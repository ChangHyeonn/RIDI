import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskService {
  static const String _tasksKey = 'tasks';
  static const String _settingsKey = 'settings';

  // 일정 목록 가져오기
  Future<List<Task>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList(_tasksKey) ?? [];
    return tasksJson.map((json) => Task.fromJson(jsonDecode(json))).toList();
  }

  // 일정 저장하기
  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = tasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList(_tasksKey, tasksJson);
  }

  // 일정 추가하기
  Future<void> addTask(Task task) async {
    final tasks = await getTasks();
    tasks.add(task);
    await saveTasks(tasks);
  }

  // 일정 여러 개 추가하기 (경쟁 상태 방지용 일괄 저장)
  Future<void> addTasks(List<Task> newTasks) async {
    if (newTasks.isEmpty) return;
    final tasks = await getTasks();
    tasks.addAll(newTasks);
    await saveTasks(tasks);
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
    final prefs = await SharedPreferences.getInstance();

    // JSON으로 저장된 설정을 먼저 시도
    final settingsJson = prefs.getString(_settingsKey);
    if (settingsJson != null) {
      try {
        return Map<String, dynamic>.from(jsonDecode(settingsJson));
      } catch (e) {
        print('설정 JSON 파싱 실패: $e');
      }
    }

    // 개별 키로 저장된 설정을 시도 (이전 버전 호환성)
    return {
      'soundVolume': prefs.getDouble('soundVolume') ?? 0.5,
      'fontSize': prefs.getDouble('fontSize') ?? 0.5,
    };
  }

  // 설정 저장하기
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();

    // JSON으로 저장
    await prefs.setString(_settingsKey, jsonEncode(settings));

    // 개별 키로도 저장 (이전 버전 호환성)
    await prefs.setDouble('soundVolume', settings['soundVolume'] ?? 0.5);
    await prefs.setDouble('fontSize', settings['fontSize'] ?? 0.5);
  }
}
