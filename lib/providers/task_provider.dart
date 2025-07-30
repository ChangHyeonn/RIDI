import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];
  Map<String, dynamic> _settings = {};
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  Map<String, dynamic> get settings => _settings;
  bool get isLoading => _isLoading;

  // 초기화
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    await loadTasks();
    await loadSettings();
    
    _isLoading = false;
    notifyListeners();
  }

  // 일정 로드
  Future<void> loadTasks() async {
    _tasks = await _taskService.getTasks();
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
  }

  // 일정 업데이트
  Future<void> updateTask(Task task) async {
    await _taskService.updateTask(task);
    await loadTasks();
  }

  // 일정 삭제
  Future<void> deleteTask(String taskId) async {
    await _taskService.deleteTask(taskId);
    await loadTasks();
  }

  // 일정 완료 상태 토글
  Future<void> toggleTaskCompletion(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      await updateTask(updatedTask);
    }
  }

  // 특정 날짜의 일정 가져오기
  List<Task> getTasksForDate(DateTime date) {
    return _tasks.where((task) {
      return task.date.year == date.year &&
          task.date.month == date.month &&
          task.date.day == date.day;
    }).toList();
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

  // 오늘 일정 완료 상태 확인
  bool get isTodayCompleted {
    final todayTasks = getTodayTasks();
    return todayTasks.isNotEmpty && todayTasks.every((task) => task.isCompleted);
  }

  // 내일 일정 완료 상태 확인
  bool get isTomorrowCompleted {
    final tomorrowTasks = getTomorrowTasks();
    return tomorrowTasks.isNotEmpty && tomorrowTasks.every((task) => task.isCompleted);
  }
} 