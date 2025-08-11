import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class RecordService {
  final _audioRecorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  // 플랫폼 지원 확인
  bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  // 녹음 파일 저장 디렉토리 가져오기
  Future<Directory> _getRecordingsDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // 모바일에서는 앱 문서 디렉토리 내에 recordings 폴더 생성
      final appDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${appDir.path}/recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }
      return recordingsDir;
    } else {
      // 데스크톱에서는 현재 프로젝트 디렉토리의 recordings 폴더 사용
      final currentDir = Directory.current;
      final recordingsDir = Directory('${currentDir.path}/recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }
      return recordingsDir;
    }
  }

  // 권한 요청
  Future<bool> _requestPermission() async {
    if (!_isSupportedPlatform) {
      throw Exception('현재 플랫폼에서 녹음 기능을 지원하지 않습니다.');
    }

    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
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
      // flutter_sound 초기화
      await _audioRecorder.openRecorder();

      // 녹음 파일 저장 디렉토리 가져오기
      final recordingsDir = await _getRecordingsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = Platform.isAndroid ? '.m4a' : '.wav';
      final fileName =
          'recording_${DateTime.now().year}_${DateTime.now().month.toString().padLeft(2, '0')}_${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().hour.toString().padLeft(2, '0')}_${DateTime.now().minute.toString().padLeft(2, '0')}_${DateTime.now().second.toString().padLeft(2, '0')}$extension';
      _currentRecordingPath = '${recordingsDir.path}/$fileName';

      // flutter_sound를 사용한 녹음 시작
      await _audioRecorder.startRecorder(
        toFile: _currentRecordingPath!,
        codec: Platform.isAndroid ? Codec.aacMP4 : Codec.pcm16WAV,
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
      final path = await _audioRecorder.stopRecorder();
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
      await _audioRecorder.stopRecorder();
      _isRecording = false;
      _currentRecordingPath = null;
    } catch (e) {
      print('녹음 취소 실패: $e');
    }
  }

  // 녹음 상태 확인
  Future<bool> checkRecordingStatus() async {
    if (!_isSupportedPlatform) return false;
    return await _audioRecorder.isRecording;
  }

  // 저장된 녹음 파일 목록 가져오기
  Future<List<File>> getRecordedFiles() async {
    try {
      final recordingsDir = await _getRecordingsDirectory();
      final files = recordingsDir
          .listSync()
          .whereType<File>()
          .where(
            (file) => file.path.endsWith('.m4a') || file.path.endsWith('.wav'),
          )
          .toList();

      // 최신 파일부터 정렬
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );
      return files;
    } catch (e) {
      print('녹음 파일 목록 가져오기 실패: $e');
      return [];
    }
  }

  // 녹음 파일 삭제
  Future<bool> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('녹음 파일 삭제 실패: $e');
      return false;
    }
  }

  // 리소스 해제
  void dispose() {
    _audioRecorder.closeRecorder();
  }
}
