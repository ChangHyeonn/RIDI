import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../models/task.dart';
import '../screens/alarm_screen.dart';

// 전역 NavigatorKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final Map<String, Timer> _alarmTimers = {};
  final Map<String, DateTime> _scheduledAlarms = {};
  AudioPlayer? _audioPlayer;

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
      return;
    }

    // 이미 완료된 일정이면 알람 설정하지 않음
    if (task.isCompleted) {
      return;
    }

    // 기존 알람이 있으면 취소
    cancelAlarm(task.id);

    // 새로운 알람 설정
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

  // 알람 취소
  void cancelAlarm(String taskId) {
    final timer = _alarmTimers[taskId];
    if (timer != null) {
      timer.cancel();
      _alarmTimers.remove(taskId);
      _scheduledAlarms.remove(taskId);
      print('알람 취소됨: $taskId');
    }
  }

  // 모든 알람 취소
  void cancelAllAlarms() {
    for (final timer in _alarmTimers.values) {
      timer.cancel();
    }
    _alarmTimers.clear();
    _scheduledAlarms.clear();
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
      print('=== 알람 소리 재생 시작 ===');

      // 진동으로 알람 효과 생성 (더 강한 진동)
      HapticFeedback.heavyImpact();
      HapticFeedback.heavyImpact();
      HapticFeedback.heavyImpact();
      print('진동 발생 완료');

      // 기존 오디오 플레이어 정리
      if (_audioPlayer != null) {
        await _audioPlayer?.stop();
        await _audioPlayer?.dispose();
        _audioPlayer = null;
        print('기존 오디오 플레이어 정리 완료');
      }

      // 새로운 오디오 플레이어 생성
      _audioPlayer = AudioPlayer();
      print('새 오디오 플레이어 생성 완료');

      // 로컬 알람 소리 파일 사용
      final assetPath = 'assets/sounds/alarm.mp3';
      print('오디오 파일 로딩 시작: $assetPath');

      // 파일 존재 여부 확인을 위한 테스트
      try {
        await _audioPlayer?.setAsset(assetPath);
        print('오디오 파일 로딩 성공');
      } catch (e) {
        print('오디오 파일 로딩 실패: $e');
        // 대체 방법: 시스템 알람 소리 사용
        print('시스템 알람 소리로 대체 시도...');
        await _audioPlayer?.setAsset('assets/sounds/alarm.mp3');
      }
      print('오디오 파일 로딩 완료');

      // 볼륨 설정 (0.0 ~ 1.0)
      await _audioPlayer?.setVolume(1.0);
      print('볼륨 설정 완료: 1.0');

      // 재생 시작
      await _audioPlayer?.play();
      print('오디오 재생 시작 완료');

      // 재생 상태 모니터링
      _audioPlayer?.playerStateStream.listen((state) {
        print('오디오 플레이어 상태: $state');
      });

      // 에러 모니터링
      _audioPlayer?.playbackEventStream.listen((event) {
        print('오디오 이벤트: $event');
      });

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      print('알람 진동 및 소리 발생 완료 (타임스탬프: $timestamp)');
    } catch (e) {
      print('알람 소리/진동 실패: $e');
      print('에러 상세 정보: ${e.toString()}');
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

  // 예약된 알람 목록 가져오기
  Map<String, DateTime> get scheduledAlarms => Map.from(_scheduledAlarms);

  // 알람이 설정되어 있는지 확인
  bool isAlarmScheduled(String taskId) {
    return _alarmTimers.containsKey(taskId);
  }
}
