import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:audioplayers/audioplayers.dart';
import '../models/task.dart';
import '../screens/alarm_screen.dart';
import '../providers/task_provider.dart';
import '../services/task_service.dart';
import 'text_to_speech_service.dart';
import '../main.dart';

// 앱 전역 NavigatorKey는 main.dart에서 정의되어 있음 (여기서는 import만 사용)

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final Map<String, Timer> _alarmTimers = {};
  final Map<String, DateTime> _scheduledAlarms = {};
  final Map<String, Timer> _alarmSoundTimers = {}; // 알람 소리 반복 재생용 타이머
  final TaskService _taskService = TaskService();
  final TextToSpeechService _ttsService = TextToSpeechService();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;
  static bool _timezoneInitialized = false;
  final Set<String> _activeAlarmTaskIds = <String>{};

  // 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _ttsService.initialize();

      // timezone 초기화 (한 번만 수행)
      if (!_timezoneInitialized) {
        tz.initializeTimeZones();
        _timezoneInitialized = true;
        print('✅ 타임존 초기화 완료');
      }

      // 로컬 알림 초기화
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      print('✅ AlarmService 초기화 성공');
    } catch (e) {
      print('❌ AlarmService 초기화 실패: $e');
    }
  }

  // 알람 설정
  void scheduleAlarm(Task task, [BuildContext? context]) async {
    final now = DateTime.now();

    // 반복 일정 처리: 다음 1회 발생 시점을 계산해 단일 알람을 예약
    if (task.isRecurring && task.recurrence != null) {
      final next = _computeNextOccurrence(task.recurrence!, now);
      if (next == null) {
        print('⚠️ 반복 일정의 다음 발생 시점을 찾을 수 없어 알람을 설정하지 않습니다.');
        return;
      }
      final nextTask = task.copyWith(date: next);
      print('🔁 반복 일정 — 다음 발생 시점으로 알람 예약: ${next.toString()}');
      // 기존 예약 취소 후 다음 1회 알람으로 예약
      cancelAlarm(task.id);
      return _scheduleSingleAlarm(nextTask, context);
    }

    // 일반 단건 일정
    final alarmTime = DateTime(
      task.date.year,
      task.date.month,
      task.date.day,
      task.date.hour,
      task.date.minute,
    );

    // 이미 지난 시간이면 알람 설정하지 않음
    if (alarmTime.isBefore(now)) {
      print('❌ 알람 설정 실패: 이미 지난 시간');
      print('  - 알람 시간: ${alarmTime.toString()}');
      print('  - 현재 시간: ${now.toString()}');
      print('  - 차이: ${now.difference(alarmTime).inMinutes}분 전');
      return;
    }

    // 이미 완료된 일정이면 알람 설정하지 않음
    if (task.isCompleted) {
      print('❌ 알람 설정 실패: 이미 완료된 일정');
      print('  - 일정: ${task.title}');
      print('  - 완료 상태: ${task.isCompleted}');
      return;
    }

    cancelAlarm(task.id);
    _scheduleSingleAlarm(task, context);
  }

  // 단일 알람 예약 (내부 공통 함수)
  void _scheduleSingleAlarm(Task task, [BuildContext? context]) async {
    final now = DateTime.now();
    final alarmTime = DateTime(
      task.date.year,
      task.date.month,
      task.date.day,
      task.date.hour,
      task.date.minute,
    );

    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _notifications.zonedSchedule(
        int.parse(task.id),
        '일정 알람',
        '${task.title} 일정이 시작되었습니다.',
        tz.TZDateTime.from(alarmTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'schedule_alarm',
            '일정 알람',
            channelDescription: '일정 알람 알림',
            importance: Importance.high,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('alarm'),
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
          ),
          iOS: DarwinNotificationDetails(
            sound: 'alarm.aiff',
            presentSound: true,
            presentAlert: true,
            presentBadge: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: task.id,
      );

      final duration = alarmTime.difference(now);
      final timer = Timer(duration, () {
        _showAlarmScreen(task, context);
      });

      _alarmTimers[task.id] = timer;
      _scheduledAlarms[task.id] = alarmTime;

      print('✅ 알람 설정됨: ${task.title}');
      print('  - 알람 시간: ${alarmTime.toString()}');
      print('  - 현재 시간: ${now.toString()}');
      print('  - 대기 시간: ${duration.inMinutes}분 ${duration.inSeconds % 60}초');
      print('  - Task ID: ${task.id}');
      print('  - 로컬 알림 스케줄링 완료');
    } catch (e) {
      print('❌ 로컬 알림 스케줄링 실패: $e');
      final duration = alarmTime.difference(now);
      final timer = Timer(duration, () {
        _showAlarmScreen(task, context);
      });
      _alarmTimers[task.id] = timer;
      _scheduledAlarms[task.id] = alarmTime;
      print('✅ Timer 방식으로 알람 설정됨 (폴백)');
    }
  }

  // 반복 일정의 다음 1회 발생 시점 계산
  DateTime? _computeNextOccurrence(RecurrenceInfo recurrence, DateTime from) {
    // 허용 요일 집합 만들기 (DateTime.weekday: 1=월..7=일)
    Set<int> allowedWeekdays;
    switch (recurrence.type) {
      case 'daily':
        allowedWeekdays = {1, 2, 3, 4, 5, 6, 7};
        break;
      case 'weekdays':
        allowedWeekdays = {1, 2, 3, 4, 5};
        break;
      case 'weekends':
        allowedWeekdays = {6, 7};
        break;
      case 'custom_days':
        // RecurrenceInfo.daysOfWeek: 0=월..6=일
        final days = recurrence.daysOfWeek ?? [];
        allowedWeekdays = days.map((d) => ((d % 7) + 1)).toSet();
        break;
      default:
        allowedWeekdays = {1, 2, 3, 4, 5, 6, 7};
    }

    DateTime cursorDate = from;
    // 탐색 한도: 365일
    for (int dayOffset = 0; dayOffset <= 365; dayOffset++) {
      final date = DateTime(
        cursorDate.year,
        cursorDate.month,
        cursorDate.day,
      ).add(Duration(days: dayOffset));

      if (!allowedWeekdays.contains(date.weekday)) {
        continue;
      }

      // 해당 날짜의 각 시간 후보 계산
      DateTime? best;
      for (final rt in recurrence.times) {
        final parts = rt.time.split(':');
        if (parts.length < 2) continue;
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final candidate = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );

        // from 이후만 허용
        if (candidate.isAfter(from) || candidate.isAtSameMomentAs(from)) {
          if (recurrence.endDate != null &&
              candidate.isAfter(recurrence.endDate!)) {
            continue;
          }
          if (best == null || candidate.isBefore(best)) {
            best = candidate;
          }
        }
      }

      if (best != null) {
        return best;
      }
    }
    return null;
  }

  // 알람 취소
  void cancelAlarm(String taskId) async {
    final timer = _alarmTimers[taskId];
    if (timer != null) {
      timer.cancel();
      _alarmTimers.remove(taskId);
      _scheduledAlarms.remove(taskId);
      print('Timer 알람 취소됨: $taskId');
    }

    // 반복 재생 타이머 취소
    if (_alarmSoundTimers.containsKey(taskId)) {
      _alarmSoundTimers[taskId]?.cancel();
      _alarmSoundTimers.remove(taskId);
      print('반복 재생 타이머 취소됨: $taskId');
    }

    // 활성 알람 집합에서 제거 및 사운드도 안전하게 정지
    _activeAlarmTaskIds.remove(taskId);
    await Future.microtask(() => stopAlarmSound(taskId));

    // 로컬 알림도 취소
    try {
      await _notifications.cancel(int.tryParse(taskId) ?? 0);
      print('로컬 알림 취소됨: $taskId');
    } catch (e) {
      print('로컬 알림 취소 실패: $e');
    }
  }

  // 모든 알람 취소
  void cancelAllAlarms() {
    for (final timer in _alarmTimers.values) {
      timer.cancel();
    }
    _alarmTimers.clear();
    _scheduledAlarms.clear();

    // 모든 반복 재생 타이머 취소
    for (final timer in _alarmSoundTimers.values) {
      timer.cancel();
    }
    _alarmSoundTimers.clear();

    print('모든 알람 취소됨');
  }

  // 알람 화면 표시
  void _showAlarmScreen(Task task, BuildContext? context) {
    final now = DateTime.now();
    final alarmTime = DateTime(
      task.date.year,
      task.date.month,
      task.date.day,
      task.date.hour,
      task.date.minute,
    );

    // 정확한 시간 체크: 설정된 시간과 1분 이내 차이여야 함
    final timeDifference = now.difference(alarmTime).abs();
    if (timeDifference.inMinutes > 1) {
      print('❌ 알람 시간 불일치로 알람 취소');
      print('  - 설정 시간: $alarmTime');
      print('  - 현재 시간: $now');
      print(
        '  - 시간 차이: ${timeDifference.inMinutes}분 ${timeDifference.inSeconds % 60}초',
      );
      return;
    }

    // 이미 완료된 일정이면 알람 표시하지 않음
    if (task.isCompleted) {
      print('❌ 이미 완료된 일정으로 알람 취소: ${task.title}');
      return;
    }

    print('⏰ 정확한 시간에 알람 실행');
    print('  - 설정 시간: $alarmTime');
    print('  - 현재 시간: $now');
    print('  - 시간 차이: ${timeDifference.inSeconds}초');

    // 중복 방지: 이미 활성화된 알람이면 재생하지 않음
    if (_activeAlarmTaskIds.contains(task.id)) {
      print('ℹ️ 이미 활성화된 알람입니다. 중복 재생 방지: ${task.id}');
    } else {
      _activeAlarmTaskIds.add(task.id);
      // 알람 소리 재생 (진동 + TTS)
      _playAlarmSound(task, context);
    }

    // 전역 NavigatorKey를 사용하여 알람 화면 표시
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => AlarmScreen(task: task)),
        (route) => false, // 모든 이전 화면 제거
      );
      print('✅ 알람 화면 표시됨: ${task.title}');
    } else {
      print('❌ NavigatorKey가 null이어서 알람 화면을 표시할 수 없음');
    }

    // 반복 일정이면 다음 1회 발생 시점을 재예약 — 단, 현재 알람이 해제되면 재예약하지 않음
    if (task.isRecurring && task.recurrence != null) {
      if (_activeAlarmTaskIds.contains(task.id)) {
        final next = _computeNextOccurrence(
          task.recurrence!,
          DateTime.now().add(const Duration(seconds: 1)),
        );
        if (next != null) {
          final nextTask = task.copyWith(date: next);
          print('🔁 반복 일정 — 다음 발생 시점 재예약: ${next.toString()}');
          // 기존 예약 정리 후 재예약
          cancelAlarm(task.id);
          _scheduleSingleAlarm(nextTask, context);
        } else {
          print('⚠️ 반복 일정 재예약 불가(다음 시점 없음)');
        }
      } else {
        print('⏹️ 알람이 이미 해제됨 — 다음 반복 재예약 생략: ${task.id}');
      }
    }
  }

  // 알람 소리 재생 (진동 + 음성 파일) - 반복 재생
  void _playAlarmSound(Task task, [BuildContext? context]) async {
    try {
      print('=== 알람 소리 재생 시작 (무한 루프) ===');

      // 기존 반복 재생 타이머가 있으면 취소
      if (_alarmSoundTimers.containsKey(task.id)) {
        _alarmSoundTimers[task.id]?.cancel();
        _alarmSoundTimers.remove(task.id);
        print('🔄 기존 반복 재생 타이머 취소');
      }

      // 볼륨 설정 가져오기
      double volume = 0.5; // 기본값

      // context가 있으면 Provider에서 가져오기
      if (context != null) {
        try {
          final taskProvider = context.read<TaskProvider>();
          volume = taskProvider.soundVolume;
          print('🔊 Provider에서 설정된 볼륨 값: $volume (${(volume * 100).toInt()}%)');
        } catch (e) {
          print('❌ Provider에서 볼륨 설정 가져오기 실패: $e');
        }
      }

      // context가 없거나 Provider에서 가져오기 실패한 경우 TaskService에서 직접 가져오기
      if (volume == 0.5) {
        try {
          final settings = await _taskService.getSettings();
          volume = settings['soundVolume'] ?? 0.5;
          print(
            '🔊 TaskService에서 설정된 볼륨 값: $volume (${(volume * 100).toInt()}%)',
          );
        } catch (e) {
          print('❌ TaskService에서 볼륨 설정 가져오기 실패: $e');
        }
      }

      // 중요한 일정인 경우 볼륨을 1.5배로 증가
      if (task.isImportant) {
        final originalVolume = volume;
        volume = (volume * 1.5).clamp(0.0, 1.0); // 최대 1.0으로 제한
        print(
          '⭐ 중요한 일정: 볼륨 ${(originalVolume * 100).toInt()}% → ${(volume * 100).toInt()}% (1.5배 증가)',
        );
      }

      // 볼륨이 0이면 소리 재생하지 않음
      if (volume <= 0.0) {
        print('🔇 볼륨이 0이므로 소리 재생하지 않음 (진동만 발생)');
        return;
      }

      // 플레이어 자체 루프 설정으로 무한 반복 재생
      try {
        await _audioPlayer.stop();
        await _audioPlayer.setVolume(volume);
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
        // 최초 진입 시 한 번 강한 햅틱
        HapticFeedback.heavyImpact();
        print('✅ 알람 소리 루프 재생 시작');
      } catch (e) {
        print('❌ 루프 재생 시작 실패: $e');
        // 음원 실패 시 TTS로 폴백 (TTS는 루프 불가, 주기적 루프는 생략)
        print('🔄 TTS로 폴백 시도');
        await _ttsService.setVoiceSettings(
          speechRate: 0.8,
          volume: volume,
          pitch: 1.2,
        );
        await _ttsService.speak('알람입니다. ${task.title} 일정이 시작되었습니다.');
      }
    } catch (e) {
      print('알람 소리/진동 실패: $e');
      print('에러 상세 정보: ${e.toString()}');
      // 소리/진동에 실패해도 알람은 계속 작동
    }
  }

  // 단일 재생 로직은 루프 재생으로 대체되어 미사용

  // 알람 소리 정지 (반복 재생 포함)
  void stopAlarmSound([String? taskId]) async {
    try {
      print('=== 알람 소리 정지 ===');

      // 특정 태스크의 반복 재생 중지
      if (taskId != null && _alarmSoundTimers.containsKey(taskId)) {
        _alarmSoundTimers[taskId]?.cancel();
        _alarmSoundTimers.remove(taskId);
        print('✅ 특정 알람 반복 재생 중지: $taskId');
        _activeAlarmTaskIds.remove(taskId);
      }

      // 모든 반복 재생 중지
      for (final timer in _alarmSoundTimers.values) {
        timer.cancel();
      }
      _alarmSoundTimers.clear();
      print('✅ 모든 알람 반복 재생 중지');
      _activeAlarmTaskIds.clear();

      // TTS 중지
      await _ttsService.stop();

      // 오디오 플레이어 중지
      await _audioPlayer.stop();

      print('✅ 알람 소리 정지 완료');
    } catch (e) {
      print('알람 소리 정지 실패: $e');
    }
  }

  // 예약된 알람 목록 가져오기
  Map<String, DateTime> get scheduledAlarms => Map.from(_scheduledAlarms);

  // 알람이 설정되어 있는지 확인
  bool isAlarmScheduled(String taskId) {
    return _alarmTimers.containsKey(taskId);
  }

  // 현재 설정된 모든 알람 정보 출력 (디버깅용)
  void printScheduledAlarms() {
    print('=== 현재 설정된 알람 목록 ===');
    if (_scheduledAlarms.isEmpty) {
      print('설정된 알람이 없습니다.');
    } else {
      _scheduledAlarms.forEach((taskId, alarmTime) {
        final now = DateTime.now();
        final remaining = alarmTime.difference(now);
        print('Task ID: $taskId');
        print('  - 알람 시간: $alarmTime');
        print(
          '  - 남은 시간: ${remaining.inMinutes}분 ${remaining.inSeconds % 60}초',
        );
        print('  - 활성 상태: ${_alarmTimers.containsKey(taskId)}');
        print('---');
      });
    }
  }

  // 알림 탭 처리
  void _onNotificationTapped(NotificationResponse response) {
    print('알림이 탭됨: ${response.payload}');
    // 알림을 탭하면 앱을 포그라운드로 가져오고 알람 화면 표시
    if (response.payload != null) {
      // Task ID를 payload에서 추출하여 알람 화면 표시
      final taskId = response.payload!;
      // 여기서 TaskProvider를 통해 task를 가져와서 알람 화면 표시
      _showAlarmFromNotification(taskId);
    }
  }

  // TaskProvider 가져오기 (RecordService에서 사용하는 방식과 동일)
  TaskProvider? _getTaskProvider() {
    try {
      // 전역 NavigatorKey를 통해 context에 접근
      if (navigatorKey.currentState != null) {
        final context = navigatorKey.currentState!.context;
        return Provider.of<TaskProvider>(context, listen: false);
      }
      return null;
    } catch (e) {
      print('❌ TaskProvider 가져오기 실패: $e');
      return null;
    }
  }

  // 알림에서 알람 화면 표시
  void _showAlarmFromNotification(String taskId) {
    try {
      // TaskProvider를 통해 task를 가져와서 알람 화면 표시
      final taskProvider = _getTaskProvider();
      if (taskProvider != null) {
        final task = taskProvider.tasks.firstWhere(
          (task) => task.id == taskId,
          orElse: () => throw Exception('Task를 찾을 수 없습니다: $taskId'),
        );

        // 알람 화면 표시
        _showAlarmScreen(task, null);
        print('✅ 알림에서 알람 화면 표시 성공: ${task.title}');
      } else {
        print('❌ TaskProvider에 접근할 수 없습니다');
      }
    } catch (e) {
      print('❌ 알림에서 알람 화면 표시 실패: $e');
    }
  }

  // 리소스 해제
  void dispose() {
    // 모든 반복 재생 타이머 취소
    for (final timer in _alarmSoundTimers.values) {
      timer.cancel();
    }
    _alarmSoundTimers.clear();

    // 모든 알람 타이머 취소
    for (final timer in _alarmTimers.values) {
      timer.cancel();
    }
    _alarmTimers.clear();

    _ttsService.dispose();
    _audioPlayer.dispose();
  }
}
