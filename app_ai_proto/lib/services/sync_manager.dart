import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import 'network_service.dart';
import 'task_service.dart';

class SyncManager {
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _syncEnabledKey = 'sync_enabled';

  final TaskService _taskService = TaskService();

  // 동기화 활성화 여부
  Future<bool> isSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncEnabledKey) ?? true; // 기본값: 활성화
  }

  // 동기화 활성화/비활성화
  Future<void> setSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncEnabledKey, enabled);
  }

  // 마지막 동기화 시간 가져오기
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastSyncKey);
    if (timestamp != null) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        print('❌ 마지막 동기화 시간 파싱 오류: $e');
        return null;
      }
    }
    return null;
  }

  // 마지막 동기화 시간 업데이트
  Future<void> updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  // 전체 동기화 (초기 로드 또는 강제 동기화)
  Future<void> syncFull() async {
    try {
      print('🔄 전체 동기화 시작...');

      // 서버에서 모든 일정 가져오기
      final serverTasks = await NetworkService.fetchSchedulesFromServer(
        'user123',
        null,
      );
      print('📥 서버에서 ${serverTasks.length}개 일정 가져옴');

      // 로컬 일정과 병합 (서버 우선)
      await _mergeSchedules(serverTasks, true);

      // 동기화 시간 업데이트
      await updateLastSyncTime();

      print('✅ 전체 동기화 완료');
    } catch (e) {
      print('❌ 전체 동기화 실패: $e');
    }
  }

  // 증분 동기화 (변경된 일정만)
  Future<void> syncIncremental() async {
    try {
      print('🔄 증분 동기화 시작...');

      final lastSync = await getLastSyncTime();
      final serverTasks = await NetworkService.fetchSchedulesFromServer(
        'user123',
        lastSync,
      );

      if (serverTasks.isNotEmpty) {
        print('📥 서버에서 ${serverTasks.length}개 변경사항 가져옴');
        await _mergeSchedules(serverTasks, false);
      }

      // 동기화 시간 업데이트
      await updateLastSyncTime();

      print('✅ 증분 동기화 완료');
    } catch (e) {
      print('❌ 증분 동기화 실패: $e');
    }
  }

  // 일정 병합 (로컬과 서버)
  Future<void> _mergeSchedules(
    List<Task> serverTasks,
    bool serverPriority,
  ) async {
    try {
      final localTasks = await _taskService.getTasks();
      final Map<String, Task> localTaskMap = {
        for (var task in localTasks) task.id: task,
      };

      final List<Task> mergedTasks = [];

      // 서버 일정 처리
      for (final serverTask in serverTasks) {
        final localTask = localTaskMap[serverTask.id];

        if (localTask == null) {
          // 서버에만 있는 일정: 로컬에 추가
          mergedTasks.add(serverTask);
          print('➕ 새 일정 추가: ${serverTask.title}');
        } else {
          // 양쪽에 있는 일정: 우선순위에 따라 처리
          if (serverPriority) {
            mergedTasks.add(serverTask);
            print('🔄 일정 업데이트: ${serverTask.title}');
          } else {
            mergedTasks.add(localTask);
            print('💾 로컬 일정 유지: ${localTask.title}');
          }
          localTaskMap.remove(serverTask.id);
        }
      }

      // 로컬에만 있는 일정 처리
      if (!serverPriority) {
        mergedTasks.addAll(localTaskMap.values);
        print('💾 로컬 일정 ${localTaskMap.length}개 유지');
      }

      // 병합된 일정 저장
      await _taskService.saveTasks(mergedTasks);
      print('💾 병합된 일정 ${mergedTasks.length}개 저장');
    } catch (e) {
      print('❌ 일정 병합 실패: $e');
    }
  }

  // 오프라인 변경사항 업로드
  Future<void> uploadOfflineChanges() async {
    try {
      print('📤 오프라인 변경사항 업로드 시작...');

      final localTasks = await _taskService.getTasks();
      int uploadCount = 0;

      for (final task in localTasks) {
        // TODO: 실제로는 변경된 일정만 업로드하는 로직 필요
        final success = await NetworkService.uploadScheduleToServer(task);
        if (success) {
          uploadCount++;
        }
      }

      print('✅ 오프라인 변경사항 ${uploadCount}개 업로드 완료');
    } catch (e) {
      print('❌ 오프라인 변경사항 업로드 실패: $e');
    }
  }

  // 동기화 상태 확인
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final isEnabled = await isSyncEnabled();
      final lastSync = await getLastSyncTime();
      final isConnected = await NetworkService.testConnection();

      return {
        'enabled': isEnabled,
        'lastSync': lastSync?.toIso8601String(),
        'connected': isConnected,
        'status': isEnabled && isConnected ? 'active' : 'inactive',
      };
    } catch (e) {
      return {
        'enabled': false,
        'lastSync': null,
        'connected': false,
        'status': 'error',
        'error': e.toString(),
      };
    }
  }
}
