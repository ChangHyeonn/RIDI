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
    try {
      if (Platform.isAndroid) {
        // Android에서는 앱 내부 저장소에 저장
        final appDir = await getApplicationDocumentsDirectory();
        final recordingsDir = Directory('${appDir.path}/recordings');
        if (!await recordingsDir.exists()) {
          await recordingsDir.create(recursive: true);
        }
        print('Android 녹음 디렉토리: ${recordingsDir.path}');
        return recordingsDir;
      } else if (Platform.isIOS) {
        // iOS에서는 앱 문서 디렉토리 내에 recordings 폴더 생성
        final appDir = await getApplicationDocumentsDirectory();
        final recordingsDir = Directory('${appDir.path}/recordings');
        if (!await recordingsDir.exists()) {
          await recordingsDir.create(recursive: true);
        }
        print('iOS 녹음 디렉토리: ${recordingsDir.path}');
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
    } catch (e) {
      print('녹음 디렉토리 생성 실패: $e');
      // 폴백: 임시 디렉토리 사용
      final tempDir = await getTemporaryDirectory();
      final recordingsDir = Directory('${tempDir.path}/recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }
      print('폴백 녹음 디렉토리: ${recordingsDir.path}');
      return recordingsDir;
    }
  }

  // 권한 요청
  Future<bool> _requestPermission() async {
    if (!_isSupportedPlatform) {
      throw Exception('현재 플랫폼에서 녹음 기능을 지원하지 않습니다.');
    }

    if (Platform.isAndroid) {
      print('Android 권한 요청 시작...');

      // 현재 권한 상태 확인
      final micStatusBefore = await Permission.microphone.status;
      print('마이크 권한 상태: $micStatusBefore');

      // 마이크 권한이 영구적으로 거부된 경우
      if (micStatusBefore == PermissionStatus.permanentlyDenied) {
        print('마이크 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.');
        // 사용자에게 설정으로 이동하도록 안내
        await openAppSettings();
        return false;
      }

      // 마이크 권한 요청
      print('마이크 권한 요청 시도...');
      final micStatus = await Permission.microphone.request();
      print('마이크 권한 요청 결과: $micStatus');

      if (micStatus != PermissionStatus.granted) {
        print('마이크 권한이 거부되었습니다.');
        return false;
      }

      print('마이크 권한 허용됨 - 녹음 가능');
      return true;
    } else if (Platform.isIOS) {
      print('iOS 권한 요청 시작...');

      // 현재 권한 상태 확인
      final micStatusBefore = await Permission.microphone.status;
      print('iOS 마이크 권한 상태: $micStatusBefore');

      // 권한 상태에 따른 상세 정보 출력
      switch (micStatusBefore) {
        case PermissionStatus.granted:
          print('iOS 마이크 권한이 이미 허용되어 있습니다.');
          return true;
        case PermissionStatus.denied:
          print('iOS 마이크 권한이 거부되었습니다. 권한 요청을 시도합니다.');
          break;
        case PermissionStatus.permanentlyDenied:
          print('iOS 마이크 권한이 영구적으로 거부되었습니다. 설정에서 수동으로 허용해야 합니다.');
          // 사용자에게 설정으로 이동하도록 안내
          await openAppSettings();
          return false;
        case PermissionStatus.restricted:
          print('iOS 마이크 권한이 제한되어 있습니다.');
          return false;
        case PermissionStatus.limited:
          print('iOS 마이크 권한이 제한적으로 허용되어 있습니다.');
          return true;
        case PermissionStatus.provisional:
          print('iOS 마이크 권한이 임시로 허용되어 있습니다.');
          return true;
        default:
          print('iOS 마이크 권한 상태를 확인할 수 없습니다.');
          break;
      }

      // 권한 요청 (iOS에서는 약간의 지연 후 요청)
      print('iOS 마이크 권한 요청 시도...');
      await Future.delayed(const Duration(milliseconds: 500));
      final status = await Permission.microphone.request();
      print('iOS 마이크 권한 요청 결과: $status');

      if (status == PermissionStatus.granted) {
        print('iOS 마이크 권한 허용됨');
        return true;
      } else {
        print('iOS 마이크 권한 거부됨: $status');
        return false;
      }
    } else {
      print('지원되지 않는 플랫폼');
      return false;
    }
  }

  // 녹음 시작
  Future<bool> startRecording() async {
    if (_isRecording) return false;

    if (!_isSupportedPlatform) {
      throw Exception('현재 플랫폼에서 녹음 기능을 지원하지 않습니다. Android 또는 iOS 기기에서 실행해주세요.');
    }

    try {
      print('녹음 시작 준비...');

      // 권한 확인 및 요청
      final hasPermission = await _requestPermission();
      if (!hasPermission) {
        if (Platform.isAndroid) {
          throw Exception('마이크 권한이 필요합니다. 설정에서 권한을 허용해주세요.');
        } else if (Platform.isIOS) {
          throw Exception('마이크 권한이 필요합니다. 설정 > 개인정보 보호 및 보안 > 마이크에서 권한을 허용해주세요.');
        } else {
          throw Exception('마이크 권한이 필요합니다.');
        }
      }

      // 녹음 파일 저장 디렉토리 가져오기
      print('녹음 디렉토리 확인 중...');
      final recordingsDir = await _getRecordingsDirectory();

      // 디렉토리 존재 확인
      if (await recordingsDir.exists()) {
        print('녹음 디렉토리 존재 확인: ${recordingsDir.path}');
      } else {
        print('경고: 녹음 디렉토리가 존재하지 않습니다: ${recordingsDir.path}');
        await recordingsDir.create(recursive: true);
        print('녹음 디렉토리 생성 완료');
      }

      final extension = '.wav'; // 모든 플랫폼에서 .wav 사용
      final fileName =
          'recording_${DateTime.now().year}_${DateTime.now().month.toString().padLeft(2, '0')}_${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().hour.toString().padLeft(2, '0')}_${DateTime.now().minute.toString().padLeft(2, '0')}_${DateTime.now().second.toString().padLeft(2, '0')}$extension';
      _currentRecordingPath = '${recordingsDir.path}/$fileName';

      print('녹음 파일 경로: $_currentRecordingPath');

      // flutter_sound를 사용한 녹음 시작
      print('녹음 시작...');

      // flutter_sound 초기화
      await _audioRecorder.openRecorder();

      await _audioRecorder.startRecorder(
        toFile: _currentRecordingPath!,
        codec: Codec.pcm16WAV,
      );

      print('녹음 시작 완료');
      _isRecording = true;
      return true;
    } catch (e) {
      print('녹음 시작 실패: $e');
      _isRecording = false;
      _currentRecordingPath = null;
      return false;
    }
  }

  // 녹음 중지
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      print('녹음 중지 시작...');
      print('현재 녹음 경로: $_currentRecordingPath');

      final path = await _audioRecorder.stopRecorder();
      print('녹음 중지 완료. 반환된 경로: $path');

      _isRecording = false;

      // 파일 존재 여부 확인 및 상세 정보 출력
      if (path != null) {
        await _printFileInfo(path);
      } else {
        print('경고: 녹음 중지 후 경로가 null입니다.');
      }

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
      
      if (!await recordingsDir.exists()) {
        print('녹음 디렉토리가 존재하지 않습니다: ${recordingsDir.path}');
        return [];
      }

      final files = recordingsDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.wav'))
          .toList();

      print('발견된 녹음 파일 수: ${files.length}');
      for (var file in files) {
        final size = await file.length();
        print('파일: ${file.path.split('/').last} (${(size / 1024).toStringAsFixed(1)} KB)');
      }

      // 최신 파일부터 정렬
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );
      return files;
    } catch (e) {
      print('녹음 파일 목록 로드 실패: $e');
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

  // 파일 정보 출력 (디버깅용)
  Future<void> _printFileInfo(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        print('원본 파일이 존재하지 않습니다: $sourcePath');
        return;
      }

      // 파일 정보 출력
      final fileSize = await sourceFile.length();
      final fileName = sourcePath.split('/').last;
      print('녹음 파일 정보:');
      print('- 파일명: $fileName');
      print('- 파일 크기: ${(fileSize / 1024).toStringAsFixed(1)} KB');
      print('- 전체 경로: $sourcePath');

      // 디렉토리 내용 확인
      final dir = Directory(
        sourcePath.substring(0, sourcePath.lastIndexOf('/')),
      );
      if (await dir.exists()) {
        final files = await dir.list().toList();
        print('- 디렉토리 내 파일 수: ${files.length}');
        for (var file in files) {
          if (file is File) {
            final size = await file.length();
            print(
              '  - ${file.path.split('/').last} (${(size / 1024).toStringAsFixed(1)} KB)',
            );
          }
        }
      }
    } catch (e) {
      print('파일 정보 확인 실패: $e');
    }
  }

  // 리소스 해제
  void dispose() {
    _audioRecorder.closeRecorder();
  }
}
