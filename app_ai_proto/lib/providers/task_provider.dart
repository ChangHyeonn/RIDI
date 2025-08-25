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
      print('🔍 동기화 활성화 상태: $isSyncEnabled');
      
      if (isSyncEnabled) {
        print('🔄 백그라운드 동기화 시작...');
        print('📊 동기화 전 일정 개수: ${_tasks.length}');
        
        await _syncManager.syncIncremental();
        _taskService.invalidateCache(); // 캐시 무효화
        await loadTasks(); // 동기화 후 데이터 새로고침
        
        print('📊 동기화 후 일정 개수: ${_tasks.length}');
        print('✅ 백그라운드 동기화 완료');
        
        // 동기화 결과를 UI에 반영
        notifyListeners();
      } else {
        print('⚠️ 동기화가 비활성화되어 있습니다');
      }
    } catch (e) {
      print('❌ 백그라운드 동기화 실패: $e');
      print('📋 상세 오류: ${e.toString()}');
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
    print('📥 일정 로드 시작...');
    _tasks = await _taskService.getTasks();
    print('📊 로드된 일정 개수: ${_tasks.length}');
    
    // 일정 목록 출력 (디버깅용)
    for (int i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      print('  ${i + 1}. ${task.title} (${task.date}) - 반복: ${task.isRecurring}');
    }
    
    notifyListeners();
    print('✅ 일정 로드 완료');
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
    await _taskService.addTasks(tasks);
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

    // 백그라운드에서 저장
    _saveTasksInBackground();
    
    // 알람 취소
    _alarmService.cancelAlarm(taskId);
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

  // 일정 여러 개 삭제 (일괄)
  Future<void> deleteTasks(List<String> taskIds) async {
    await _taskService.deleteTasks(taskIds);
    await loadTasks();

    for (final id in taskIds) {
      _alarmService.cancelAlarm(id);
    }
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

  // 특정 날짜의 일정 가져오기 (반복 일정 포함)
  List<Task> getTasksForDate(DateTime date) {
    final tasks = _tasks.where((task) {
      // 일반 일정: 정확히 같은 날짜
      if (!task.isRecurring) {
        return task.date.year == date.year &&
            task.date.month == date.month &&
            task.date.day == date.day;
      }
      
      // 반복 일정: 해당 날짜에 반복되는지 확인
      if (task.isRecurring && task.recurrence != null) {
        return _isRecurringOnDate(task, date);
      }
      
      return false;
    }).toList();

    // 시간 순으로 정렬 (오전/오후, 시간, 분 순서)
    tasks.sort((a, b) {
      // 시간 비교
      final hourComparison = a.date.hour.compareTo(b.date.hour);
      if (hourComparison != 0) return hourComparison;

      // 분 비교
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
    final DateTime startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    
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
        if (recurrence.daysOfWeek != null && recurrence.daysOfWeek!.isNotEmpty) {
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
