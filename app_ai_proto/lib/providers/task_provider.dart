import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/alarm_service.dart';
import '../services/sync_manager.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  final AlarmService _alarmService = AlarmService();
  final SyncManager _syncManager = SyncManager();
  List<Task> _tasks = [];
  Map<String, dynamic> _settings = {};
  bool _isLoading = false;
  bool _isSyncing = false;
  // 반복 일정의 날짜별 완료 상태 저장 (key: "taskId_YYYYMMDD")
  Set<String> _completedOccurrenceKeys = {};

  List<Task> get tasks => _tasks;
  Map<String, dynamic> get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;

  // 초기화
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // 로컬 데이터 먼저 로드 (빠른 시작)
    await loadTasks();
    await loadSettings();
    // 날짜별 완료 상태 로드
    final completedKeys = await _taskService.getCompletedOccurrences();
    _completedOccurrenceKeys = completedKeys.toSet();

    // 알람 서비스 초기화 및 기존 일정들의 알람 복원
    await _restoreAlarms();

    _isLoading = false;
    notifyListeners();

    // 네트워크 동기화는 백그라운드에서 (사용자 경험 개선)
    _initializeSyncInBackground();
  }

  // 백그라운드에서 초기 동기화 수행
  Future<void> _initializeSyncInBackground() async {
    try {
      final isSyncEnabled = await _syncManager.isSyncEnabled();
      if (isSyncEnabled) {
        print('🔄 백그라운드 동기화 시작...');
        await _syncManager.syncIncremental();
        _taskService.invalidateCache(); // 캐시 무효화
        await loadTasks(); // 동기화 후 데이터 새로고침
        print('✅ 백그라운드 동기화 완료');
      }
    } catch (e) {
      print('⚠️ 백그라운드 동기화 실패, 로컬 데이터 사용: $e');
    }
  }

  // 기존 일정들의 알람 복원
  Future<void> _restoreAlarms() async {
    try {
      await _alarmService.initialize();

      // 완료되지 않은 미래 일정들에 대해 알람 설정
      final now = DateTime.now();
      for (final task in _tasks) {
        if (!task.isCompleted && task.date.isAfter(now)) {
          _alarmService.scheduleAlarm(task);
          print('✅ 알람 복원: ${task.title} (${task.date})');
        }
      }
      print('✅ 알람 복원 완료');

      // 디버깅을 위해 현재 설정된 알람 목록 출력
      _alarmService.printScheduledAlarms();
    } catch (e) {
      print('❌ 알람 복원 중 오류: $e');
    }
  }

  // 일정 로드
  Future<void> loadTasks() async {
    _tasks = await _taskService.getTasks();
    _dedupeRecurringTasksInMemory();
    notifyListeners();
  }

  // 설정 로드
  Future<void> loadSettings() async {
    _settings = await _taskService.getSettings();
    notifyListeners();
  }

  // 일정 추가
  Future<void> addTask(Task task) async {
    await _taskService.addTask(task);
    await loadTasks();

    // 완료되지 않은 일정만 알람 설정
    if (!task.isCompleted) {
      _alarmService.scheduleAlarm(task);
    }

    // 반복 일정인 경우 로그 출력
    if (task.isRecurring && task.recurrence != null) {
      print('🔄 반복 일정 추가됨: ${task.title} (${task.recurrence!.type})');
      print('  - 시작일: ${task.date}');
      print('  - 반복 타입: ${task.recurrence!.type}');
      print('  - 요일: ${task.recurrence!.daysOfWeek}');
    }

    // 동기화 시도 (백그라운드에서)
    _syncInBackground();
  }

  // 일정 여러 개 추가 (일괄 저장)
  Future<void> addTasks(List<Task> tasks) async {
    // 기존과 중복되는 반복 일정(제목+카테고리+정확한 시각)을 제거하고 추가
    final existingKeys = _tasks
        .map(_composeRecurringKeyOrNull)
        .whereType<String>()
        .toSet();
    final filtered = <Task>[];
    for (final t in tasks) {
      final key = _composeRecurringKeyOrNull(t);
      if (key == null || !existingKeys.contains(key)) {
        filtered.add(t);
      }
    }

    if (filtered.isEmpty) {
      return; // 추가할 것이 없음
    }

    await _taskService.addTasks(filtered);
    await loadTasks();

    final now = DateTime.now();
    for (final task in tasks) {
      if (!task.isCompleted && task.date.isAfter(now)) {
        _alarmService.scheduleAlarm(task);
      }
    }

    // 동기화 시도 (백그라운드에서)
    _syncInBackground();
  }

  // 메모리 내 중복된 반복 일정 제거 (첫 항목만 유지)
  void _dedupeRecurringTasksInMemory() {
    final seen = <String>{};
    final deduped = <Task>[];
    for (final t in _tasks) {
      final key = _composeRecurringKeyOrNull(t);
      if (key == null) {
        deduped.add(t);
        continue;
      }
      if (!seen.contains(key)) {
        seen.add(key);
        deduped.add(t);
      }
    }
    if (deduped.length != _tasks.length) {
      _tasks = deduped;
      _saveTasksInBackground();
    }
  }

  // 반복 일정은 (제목, 카테고리, 분 단위 시각)으로 동일성 판단, 일반 일정은 null 반환
  String? _composeRecurringKeyOrNull(Task t) {
    if (!t.isRecurring) return null;
    final y = t.date.year.toString().padLeft(4, '0');
    final m = t.date.month.toString().padLeft(2, '0');
    final d = t.date.day.toString().padLeft(2, '0');
    final hh = t.date.hour.toString().padLeft(2, '0');
    final mm = t.date.minute.toString().padLeft(2, '0');
    return 'R|${t.title}|${t.category}|$y$m$d$hh$mm';
  }

  // 일정 업데이트
  Future<void> updateTask(Task task) async {
    await _taskService.updateTask(task);
    await loadTasks();

    // 완료되지 않은 일정만 알람 설정
    if (!task.isCompleted) {
      _alarmService.scheduleAlarm(task);
    } else {
      _alarmService.cancelAlarm(task.id);
    }
  }

  // 일정 삭제
  Future<void> deleteTask(String taskId) async {
    // 메모리에서 먼저 제거 (즉시 UI 반영)
    _tasks.removeWhere((task) => task.id == taskId);
    notifyListeners();

    // 백그라운드에서 저장 및 알람 취소
    _processDeletionInBackground([taskId]);
  }

  // 백그라운드에서 일정 저장
  Future<void> _saveTasksInBackground() async {
    try {
      await _taskService.saveTasks(_tasks);
    } catch (e) {
      print('❌ 백그라운드 저장 실패: $e');
      // 실패 시 다시 로드
      await loadTasks();
    }
  }

  // 백그라운드에서 삭제 처리 (저장 + 알람 취소)
  Future<void> _processDeletionInBackground(List<String> taskIds) async {
    try {
      // 저장과 알람 취소를 병렬로 처리
      await Future.wait([
        _saveTasksInBackground(),
        _cancelAlarmsInBackground(taskIds),
      ]);
      print('✅ 백그라운드 삭제 처리 완료: ${taskIds.length}개');

      // 삭제 후 지연된 동기화 (사용자 경험 개선)
      _scheduleDelayedSync();
    } catch (e) {
      print('❌ 백그라운드 삭제 처리 실패: $e');
    }
  }

  // 지연된 동기화 스케줄링
  void _scheduleDelayedSync() {
    // 5초 후에 동기화 실행 (사용자가 다른 작업을 할 시간 확보)
    Future.delayed(const Duration(seconds: 5), () {
      _syncInBackground();
    });
  }

  // 백그라운드에서 알람 취소
  Future<void> _cancelAlarmsInBackground(List<String> taskIds) async {
    try {
      for (final id in taskIds) {
        _alarmService.cancelAlarm(id);
      }
      print('✅ 백그라운드 알람 취소 완료: ${taskIds.length}개');
    } catch (e) {
      print('❌ 백그라운드 알람 취소 실패: $e');
    }
  }

  // 일정 여러 개 삭제 (일괄)
  Future<void> deleteTasks(List<String> taskIds) async {
    // 메모리에서 먼저 제거 (즉시 UI 반영)
    _tasks.removeWhere((task) => taskIds.contains(task.id));
    notifyListeners();

    // 백그라운드에서 저장 및 알람 취소
    _processDeletionInBackground(taskIds);
  }

  // 일정 완료 상태 토글
  Future<void> toggleTaskCompletion(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      await updateTask(updatedTask); // updateTask에서 알람 관리
    }
  }

  // 반복 일정의 특정 날짜 발생을 완료 처리/해제
  Future<void> toggleOccurrenceCompletion(String taskId, DateTime date) async {
    final key = _composeOccurrenceKey(taskId, date);
    if (_completedOccurrenceKeys.contains(key)) {
      _completedOccurrenceKeys.remove(key);
    } else {
      _completedOccurrenceKeys.add(key);
    }
    await _taskService.saveCompletedOccurrences(
      _completedOccurrenceKeys.toList(),
    );
    notifyListeners();
  }

  bool isOccurrenceCompleted(String taskId, DateTime date) {
    return _completedOccurrenceKeys.contains(
      _composeOccurrenceKey(taskId, date),
    );
  }

  String _composeOccurrenceKey(String taskId, DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${taskId}_${y}${m}${dd}';
  }

  // 특정 날짜의 일정 가져오기 (반복 일정 포함)
  List<Task> getTasksForDate(DateTime date) {
    final hasExplicitRecurringInstances = _tasks.any(
      (t) =>
          t.isRecurring &&
          t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day,
    );

    final tasks = _tasks.where((task) {
      final isSameDay =
          task.date.year == date.year &&
          task.date.month == date.month &&
          task.date.day == date.day;

      // 일반 일정: 같은 날만 포함
      if (!task.isRecurring) return isSameDay;

      // 반복 일정: 같은 날에 명시적 인스턴스가 있으면 그 인스턴스만 포함
      if (hasExplicitRecurringInstances) return isSameDay;

      // 명시적 인스턴스가 없을 때만 규칙 기반 포함
      if (task.recurrence != null) {
        return _isRecurringOnDate(task, date);
      }
      return false;
    }).toList();

    // 정렬: 1) 미완료 먼저 2) 완료는 뒤 3) 각각 내부는 시간 오름차순
    tasks.sort((a, b) {
      final aDone = a.isRecurring
          ? isOccurrenceCompleted(a.id, date)
          : a.isCompleted;
      final bDone = b.isRecurring
          ? isOccurrenceCompleted(b.id, date)
          : b.isCompleted;

      if (aDone != bDone) {
        return aDone ? 1 : -1; // 미완료(false) 우선
      }

      // 동일 그룹 내 시간 비교
      final hourComparison = a.date.hour.compareTo(b.date.hour);
      if (hourComparison != 0) return hourComparison;
      return a.date.minute.compareTo(b.date.minute);
    });

    return tasks;
  }

  // 반복 일정이 특정 날짜에 해당하는지 확인
  bool _isRecurringOnDate(Task task, DateTime date) {
    if (!task.isRecurring || task.recurrence == null) {
      return false;
    }

    final recurrence = task.recurrence!;
    final startDate = task.date;

    // 날짜만 비교하도록 정규화 (시간 무시)
    final DateTime dateOnly = DateTime(date.year, date.month, date.day);
    final DateTime startOnly = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    // 시작일 이전이면 false
    if (dateOnly.isBefore(startOnly)) {
      return false;
    }

    // 종료일이 있고 해당 날짜가 종료일을 넘으면 false (날짜만 비교)
    if (recurrence.endDate != null) {
      final end = recurrence.endDate!;
      final DateTime endOnly = DateTime(end.year, end.month, end.day);
      if (dateOnly.isAfter(endOnly)) {
        return false;
      }
    }

    switch (recurrence.type) {
      case 'daily':
        // 매일: 모든 날짜에 해당
        return true;

      case 'weekdays':
        // 평일: 월~금 (1~5)
        return dateOnly.weekday >= 1 && dateOnly.weekday <= 5;

      case 'weekends':
        // 주말: 토, 일 (6, 7)
        return dateOnly.weekday == 6 || dateOnly.weekday == 7;

      case 'custom_days':
        // 특정 요일: daysOfWeek에 포함된 요일
        if (recurrence.daysOfWeek != null &&
            recurrence.daysOfWeek!.isNotEmpty) {
          // Flutter의 weekday는 1=월요일, 7=일요일
          // 서버의 daysOfWeek는 0=월요일, 6=일요일
          final flutterWeekday = dateOnly.weekday; // 1~7
          final serverWeekday = flutterWeekday - 1; // 0~6
          return recurrence.daysOfWeek!.contains(serverWeekday);
        }
        return false;

      default:
        return false;
    }
  }

  // 오늘의 일정 가져오기
  List<Task> getTodayTasks() {
    final today = DateTime.now();
    return getTasksForDate(today);
  }

  // 내일의 일정 가져오기
  List<Task> getTomorrowTasks() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return getTasksForDate(tomorrow);
  }

  // 설정 업데이트
  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    _settings = newSettings;
    await _taskService.saveSettings(_settings);
    notifyListeners();
  }

  // 글씨 크기 가져오기
  double get fontSize {
    return _settings['fontSize'] ?? 0.5;
  }

  // 글씨 크기 설정
  Future<void> setFontSize(double size) async {
    _settings['fontSize'] = size;
    await _taskService.saveSettings(_settings);
    notifyListeners();
  }

  // 소리 크기 가져오기
  double get soundVolume {
    return _settings['soundVolume'] ?? 0.5;
  }

  // 소리 크기 설정
  Future<void> setSoundVolume(double volume) async {
    _settings['soundVolume'] = volume;
    await _taskService.saveSettings(_settings);
    notifyListeners();
  }

  // 오늘 일정 완료 상태 확인
  bool get isTodayCompleted {
    final todayTasks = getTodayTasks();
    return todayTasks.isNotEmpty &&
        todayTasks.every((task) => task.isCompleted);
  }

  // 내일 일정 완료 상태 확인
  bool get isTomorrowCompleted {
    final tomorrowTasks = getTomorrowTasks();
    return tomorrowTasks.isNotEmpty &&
        tomorrowTasks.every((task) => task.isCompleted);
  }

  // 백그라운드 동기화
  Future<void> _syncInBackground() async {
    try {
      final isSyncEnabled = await _syncManager.isSyncEnabled();
      if (!isSyncEnabled) return;

      _isSyncing = true;
      notifyListeners();

      await _syncManager.syncIncremental();

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      print('❌ 백그라운드 동기화 실패: $e');
      _isSyncing = false;
      notifyListeners();
    }
  }

  // 수동 동기화
  Future<void> syncNow() async {
    try {
      _isSyncing = true;
      notifyListeners();

      await _syncManager.syncFull();
      await loadTasks();

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      print('❌ 수동 동기화 실패: $e');
      _isSyncing = false;
      notifyListeners();
    }
  }

  // 동기화 상태 확인
  Future<Map<String, dynamic>> getSyncStatus() async {
    return await _syncManager.getSyncStatus();
  }
}
