import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task.dart';
import '../screens/alarm_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// 전역 NavigatorKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Map<String, Timer> _alarmTimers = {};
  final Map<String, DateTime> _scheduledAlarms = {};
  AudioPlayer? _audioPlayer;

  // 알람 서비스 초기화
  Future<void> initialize() async {
    // 타임존 초기화
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 알람 권한 요청
    await _requestPermissions();
  }

  // 알람 권한 요청
  Future<void> _requestPermissions() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // 알람 설정
  void scheduleAlarm(Task task, [BuildContext? context]) {
    final now = DateTime.now();
    final alarmTime = DateTime(
      task.date.year,
      task.date.month,
      task.date.day,
      task.date.hour,
      task.date.minute,
    );

    // 이미 지난 시간이면 알람 설정하지 않음
    if (alarmTime.isBefore(now)) {
      print('알람 시간이 이미 지났습니다: ${task.title}');
      return;
    }

    // 이미 완료된 일정이면 알람 설정하지 않음
    if (task.isCompleted) {
      print('완료된 일정은 알람을 설정하지 않습니다: ${task.title}');
      return;
    }

    // 기존 알람이 있으면 취소
    cancelAlarm(task.id);

    // 로컬 알림 설정
    _scheduleLocalNotification(task, alarmTime);

    // 앱 내 타이머도 함께 설정 (백업용)
    final duration = alarmTime.difference(now);
    final timer = Timer(duration, () {
      if (context != null) {
        _showAlarmScreen(task, context);
      }
    });

    _alarmTimers[task.id] = timer;
    _scheduledAlarms[task.id] = alarmTime;

    print('알람 설정됨: ${task.title} - ${alarmTime.toString()}');
  }

  // 로컬 알림 설정
  Future<void> _scheduleLocalNotification(Task task, DateTime alarmTime) async {
    // 웹 환경에서는 vibrationPattern을 제거
    AndroidNotificationDetails androidPlatformChannelSpecifics;
    
    if (kIsWeb) {
      androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'alarm_channel',
        '알람',
        channelDescription: '일정 알람',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('alarm'),
        enableVibration: true,
      );
    } else {
      androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'alarm_channel',
        '알람',
        channelDescription: '일정 알람',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('alarm'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      );
    }

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      sound: 'alarm.m4a',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // DateTime을 TZDateTime으로 변환
    final tzAlarmTime = tz.TZDateTime.from(alarmTime, tz.local);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      task.id.hashCode, // 고유한 알림 ID
      '일정 알림',
      task.title,
      tzAlarmTime,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // 알람 취소
  void cancelAlarm(String taskId) {
    // 타이머 취소
    final timer = _alarmTimers[taskId];
    if (timer != null) {
      timer.cancel();
      _alarmTimers.remove(taskId);
      _scheduledAlarms.remove(taskId);
    }

    // 로컬 알림 취소
    _flutterLocalNotificationsPlugin.cancel(taskId.hashCode);

    print('알람 취소됨: $taskId');
  }

  // 모든 알람 취소
  void cancelAllAlarms() {
    // 모든 타이머 취소
    for (final timer in _alarmTimers.values) {
      timer.cancel();
    }
    _alarmTimers.clear();
    _scheduledAlarms.clear();

    // 모든 로컬 알림 취소
    _flutterLocalNotificationsPlugin.cancelAll();

    print('모든 알람 취소됨');
  }

  // 알람 화면 표시
  void _showAlarmScreen(Task task, BuildContext? context) {
    // 알람 소리 재생 (진동)
    _playAlarmSound();

    // 전역 NavigatorKey를 사용하여 알람 화면 표시
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => AlarmScreen(task: task)),
      (route) => false, // 모든 이전 화면 제거
    );
  }

  // 알람 소리 재생 (진동 + 오디오)
  void _playAlarmSound() async {
    try {
      // 진동으로 알람 효과 생성
      HapticFeedback.heavyImpact();

      // 오디오 플레이어 초기화 및 소리 재생
      _audioPlayer?.dispose();
      _audioPlayer = AudioPlayer();

      // 로컬 알람 소리 파일 사용 (M4A, MP3 등 지원)
      await _audioPlayer?.setAsset('assets/sounds/alarm.m4a');
      await _audioPlayer?.play();

      print('알람 진동 및 소리 발생...');
    } catch (e) {
      print('알람 소리/진동 실패: $e');
      // 소리/진동에 실패해도 알람은 계속 작동
    }
  }

  // 알람 소리 정지
  void stopAlarmSound() async {
    try {
      await _audioPlayer?.stop();
      await _audioPlayer?.dispose();
      _audioPlayer = null;
      print('알람 소리 정지');
    } catch (e) {
      print('알람 소리 정지 실패: $e');
    }
  }

  // 알림 탭 처리
  void _onNotificationTapped(NotificationResponse response) {
    // 알림을 탭했을 때의 처리
    print('알림이 탭되었습니다: ${response.payload}');
  }

  // 예약된 알람 목록 가져오기
  Map<String, DateTime> get scheduledAlarms => Map.from(_scheduledAlarms);

  // 알람이 설정되어 있는지 확인
  bool isAlarmScheduled(String taskId) {
    return _alarmTimers.containsKey(taskId);
  }
}
