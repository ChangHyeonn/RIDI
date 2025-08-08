import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class RecordService {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  // 플랫폼 지원 확인
  bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  // 권한 요청
  Future<bool> _requestPermission() async {
    if (!_isSupportedPlatform) {
      throw Exception('현재 플랫폼에서 녹음 기능을 지원하지 않습니다.');
    }

    if (Platform.isAndroid) {
      final status = await Permission.microphone.request();
      return status == PermissionStatus.granted;
    }
    return true;
  }

  // 녹음 시작
  Future<bool> startRecording() async {
    if (_isRecording) return false;

    if (!_isSupportedPlatform) {
      throw Exception('현재 플랫폼에서 녹음 기능을 지원하지 않습니다. Android 또는 iOS 기기에서 실행해주세요.');
    }

    final hasPermission = await _requestPermission();
    if (!hasPermission) {
      throw Exception('마이크 권한이 필요합니다.');
    }

    try {
      // 임시 디렉토리 가져오기
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${tempDir.path}/recording_$timestamp.m4a';

      // 녹음 시작
      await _audioRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      return true;
    } catch (e) {
      print('녹음 시작 실패: $e');
      return false;
    }
  }

  // 녹음 중지
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      return path;
    } catch (e) {
      print('녹음 중지 실패: $e');
      _isRecording = false;
      return null;
    }
  }

  // 녹음 취소
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      await _audioRecorder.stop();
      _isRecording = false;
      _currentRecordingPath = null;
    } catch (e) {
      print('녹음 취소 실패: $e');
    }
  }

  // 녹음 상태 확인
  Future<bool> checkRecordingStatus() async {
    if (!_isSupportedPlatform) return false;
    return await _audioRecorder.isRecording();
  }

  // 리소스 해제
  void dispose() {
    _audioRecorder.dispose();
  }
}
