import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskService {
  static const String _tasksKey = 'tasks';
  static const String _settingsKey = 'settings';
  static const String _completedOccurrencesKey = 'completed_occurrence_keys';
  static const String _tasksBackupKey = 'tasks_backup';

  // 캐싱을 위한 변수들
  List<Task>? _cachedTasks;
  Map<String, dynamic>? _cachedSettings;
  List<String>? _cachedCompletedOccurrenceKeys;

  // 쓰기 직렬화 큐 (플랫폼 공통 원자성 강화)
  Future<void> _writeQueue = Future.value();

  Future<T> _enqueueWrite<T>(Future<T> Function() action) {
    // 이전 작업 완료 후 이어서 실행되도록 보장
    final completer = Completer<T>();
    _writeQueue = _writeQueue
        .then((_) => action())
        .then((value) {
          completer.complete(value);
        })
        .catchError((e, st) {
          completer.completeError(e, st);
        });
    return completer.future;
  }

  // 일정 목록 가져오기
  Future<List<Task>> getTasks() async {
    // 진행 중인 쓰기가 있으면 완료 후 읽기 (일관성 확보)
    await _writeQueue;
    if (_cachedTasks != null) return _cachedTasks!;

    final prefs = await SharedPreferences.getInstance();
    final currentList = prefs.getStringList(_tasksKey);
    final backupList = prefs.getStringList(_tasksBackupKey);

    List<Task> parsed = [];
    List<String>? source;
    try {
      source = currentList ?? <String>[];
      parsed = (source).map((json) => Task.fromJson(jsonDecode(json))).toList();
    } catch (e) {
      // 현재 데이터 파싱 실패 시 백업에서 복구 시도
      try {
        if (backupList != null) {
          parsed = backupList
              .map((json) => Task.fromJson(jsonDecode(json)))
              .toList();
          await prefs.setStringList(_tasksKey, backupList);
        } else {
          parsed = [];
        }
      } catch (_) {
        parsed = [];
      }
    }

    _cachedTasks = parsed;
    return _cachedTasks!;
  }

  // 일정 저장하기
  Future<void> saveTasks(List<Task> tasks) async {
    await _enqueueWrite<void>(() async {
      final prefs = await SharedPreferences.getInstance();

      // ID 기준 중복 제거 및 안정적 정렬(옵션)
      final Map<String, Task> byId = {for (final t in tasks) t.id: t};
      final deduped = byId.values.toList();

      // 백업 저장 (롤백 대비)
      final prev = prefs.getStringList(_tasksKey) ?? <String>[];
      await prefs.setStringList(_tasksBackupKey, prev);

      // 실제 저장
      final tasksJson = deduped.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList(_tasksKey, tasksJson);

      // 캐시 갱신
      _cachedTasks = deduped;
    });
  }

  // 일정 추가하기
  Future<void> addTask(Task task) async {
    final tasks = await getTasks();
    // 동일 ID가 이미 있으면 교체, 없으면 추가
    final idx = tasks.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      tasks[idx] = task;
    } else {
      tasks.add(task);
    }
    await saveTasks(tasks);
  }

  // 일정 여러 개 추가하기 (경쟁 상태 방지용 일괄 저장)
  Future<void> addTasks(List<Task> newTasks) async {
    if (newTasks.isEmpty) return;
    final tasks = await getTasks();
    final Map<String, Task> byId = {for (final t in tasks) t.id: t};
    for (final nt in newTasks) {
      byId[nt.id] = nt;
    }
    await saveTasks(byId.values.toList());
  }

  // 일정 업데이트하기
  Future<void> updateTask(Task task) async {
    final tasks = await getTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      await saveTasks(tasks);
    }
  }

  // 일정 삭제하기
  Future<void> deleteTask(String taskId) async {
    final tasks = await getTasks();
    tasks.removeWhere((task) => task.id == taskId);
    await saveTasks(tasks);
  }

  // 일정 여러 개 삭제하기
  Future<void> deleteTasks(List<String> taskIds) async {
    if (taskIds.isEmpty) return;
    final tasks = await getTasks();
    tasks.removeWhere((task) => taskIds.contains(task.id));
    await saveTasks(tasks);
  }

  // 특정 날짜의 일정 가져오기
  Future<List<Task>> getTasksForDate(DateTime date) async {
    final tasks = await getTasks();
    return tasks.where((task) {
      return task.date.year == date.year &&
          task.date.month == date.month &&
          task.date.day == date.day;
    }).toList();
  }

  // 설정 가져오기
  Future<Map<String, dynamic>> getSettings() async {
    if (_cachedSettings != null) return _cachedSettings!;

    final prefs = await SharedPreferences.getInstance();

    // JSON으로 저장된 설정을 먼저 시도
    final settingsJson = prefs.getString(_settingsKey);
    if (settingsJson != null) {
      try {
        _cachedSettings = Map<String, dynamic>.from(jsonDecode(settingsJson));
        return _cachedSettings!;
      } catch (e) {
        print('설정 JSON 파싱 실패: $e');
      }
    }

    // 개별 키로 저장된 설정을 시도 (이전 버전 호환성)
    _cachedSettings = {
      'soundVolume': prefs.getDouble('soundVolume') ?? 0.5,
      'fontSize': prefs.getDouble('fontSize') ?? 0.5,
    };
    return _cachedSettings!;
  }

  // 설정 저장하기
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();

    // JSON으로 저장
    await prefs.setString(_settingsKey, jsonEncode(settings));

    // 개별 키로도 저장 (이전 버전 호환성)
    await prefs.setDouble('soundVolume', settings['soundVolume'] ?? 0.5);
    await prefs.setDouble('fontSize', settings['fontSize'] ?? 0.5);

    _cachedSettings = settings; // 캐시 업데이트
  }

  // 반복 일정의 특정 날짜 완료 키 목록 가져오기
  Future<List<String>> getCompletedOccurrences() async {
    if (_cachedCompletedOccurrenceKeys != null) {
      return _cachedCompletedOccurrenceKeys!;
    }
    final prefs = await SharedPreferences.getInstance();
    // StringList로 저장/로드. 없으면 빈 리스트 반환
    final keys = prefs.getStringList(_completedOccurrencesKey) ?? <String>[];
    _cachedCompletedOccurrenceKeys = List<String>.from(keys);
    return _cachedCompletedOccurrenceKeys!;
  }

  // 반복 일정의 특정 날짜 완료 키 목록 저장하기
  Future<void> saveCompletedOccurrences(List<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_completedOccurrencesKey, keys);
    _cachedCompletedOccurrenceKeys = List<String>.from(keys);
  }

  // 캐시 무효화 (동기화 후 사용)
  void invalidateCache() {
    _cachedTasks = null;
    _cachedSettings = null;
    _cachedCompletedOccurrenceKeys = null;
  }
}
