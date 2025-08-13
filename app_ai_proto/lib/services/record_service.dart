import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'speech_to_text_service.dart';
import 'text_to_speech_service.dart';
import 'ai_service.dart';
import '../models/ai_response.dart';

class RecordService {
  final SpeechToTextService _sttService = SpeechToTextService();
  final TextToSpeechService _ttsService = TextToSpeechService();

  bool _isRecording = false;
  bool _isPlaying = false;
  String _recognizedText = '';
  String _aiResponseText = '';
  DateTime? _recordingStartTime;

  // 스트림 컨트롤러
  final StreamController<String> _textStreamController =
      StreamController<String>.broadcast();
  final StreamController<String> _aiResponseStreamController =
      StreamController<String>.broadcast();
  final StreamController<bool> _recordingStateController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _playingStateController =
      StreamController<bool>.broadcast();

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String get recognizedText => _recognizedText;
  String get aiResponseText => _aiResponseText;
  DateTime? get recordingStartTime => _recordingStartTime;

  // Streams
  Stream<String> get textStream => _textStreamController.stream;
  Stream<String> get aiResponseStream => _aiResponseStreamController.stream;
  Stream<bool> get recordingStateStream => _recordingStateController.stream;
  Stream<bool> get playingStateStream => _playingStateController.stream;

  // 초기화
  Future<bool> initialize() async {
    print('=== RecordService 초기화 시작 ===');

    try {
      // STT 서비스 초기화
      final sttInitialized = await _sttService.initialize();
      if (!sttInitialized) {
        print('❌ STT 서비스 초기화 실패');
        return false;
      }

      // TTS 서비스 초기화
      final ttsInitialized = await _ttsService.initialize();
      if (!ttsInitialized) {
        print('❌ TTS 서비스 초기화 실패');
        return false;
      }

      // 스트림 구독 설정
      _setupStreamSubscriptions();

      print('✅ RecordService 초기화 성공');
      return true;
    } catch (e) {
      print('❌ RecordService 초기화 실패: $e');
      return false;
    }
  }

  void _setupStreamSubscriptions() {
    // STT 텍스트 스트림 구독 (audio_app2 방식)
    _sttService.textStream.listen((text) {
      print('🎤 음성 인식 텍스트 수신: "$text"');
      _recognizedText = text;
      _textStreamController.add(text);

      // 텍스트가 있으면 AI 처리 (audio_app2 방식)
      if (text.isNotEmpty) {
        print('🤖 AI 처리 시작 - 인식된 텍스트: "$text"');
        _processWithAI(text);
      }
    });

    // STT 상태 스트림 구독
    _sttService.listeningStateStream.listen((isListening) {
      _isRecording = isListening;
      _recordingStateController.add(isListening);
      print('📊 녹음 상태 변경: $isListening');

      // 음성 인식이 끝나면 자동으로 AI 처리 (audio_app2 방식)
      if (!isListening && _recognizedText.isNotEmpty) {
        print('🔄 음성 인식 완료 - AI 처리 시작');
        _processWithAI(_recognizedText);
      }
    });

    // TTS 상태 스트림 구독
    _ttsService.speakingStateStream.listen((isSpeaking) {
      _isPlaying = isSpeaking;
      _playingStateController.add(isSpeaking);
      print('🔊 재생 상태 변경: $isSpeaking');
    });

    // STT 오류 스트림 구독
    _sttService.errorStream.listen((error) {
      print('❌ STT 오류: $error');
    });

    // TTS 오류 스트림 구독
    _ttsService.errorStream.listen((error) {
      print('❌ TTS 오류: $error');
    });
  }

  // 권한 확인 (기존 메서드명 유지)
  Future<bool> _requestPermission() async {
    print('=== 마이크 권한 확인 ===');

    try {
      if (kIsWeb) {
        print('🌐 Web 환경에서는 브라우저가 자동으로 권한을 요청합니다.');
        return true;
      }

      final micStatus = await Permission.microphone.status;
      print('현재 마이크 권한 상태: $micStatus');

      if (micStatus == PermissionStatus.granted) {
        print('✅ 마이크 권한이 허용되어 있습니다.');
        return true;
      }

      if (micStatus == PermissionStatus.permanentlyDenied) {
        print('❌ 마이크 권한이 영구적으로 거부되었습니다.');
        print('⚠️ 앱 설정에서 마이크 권한을 수동으로 허용해주세요.');
        await openAppSettings();
        return false;
      }

      print('❌ 마이크 권한이 거부되었습니다.');
      print('⚠️ 앱 시작 시 권한을 허용해주세요.');
      return false;
    } catch (e) {
      print('권한 확인 중 오류: $e');
      return false;
    }
  }

  // 음성 인식 시작 (기존 메서드명 유지)
  Future<bool> startRecording() async {
    if (_isRecording) {
      print('이미 음성 인식 중입니다.');
      return false;
    }

    try {
      print('=== 음성 인식 시작 ===');

      // audio_app2 방식: 매번 초기화하므로 여기서는 확인만
      print('🔧 audio_app2 방식으로 STT 서비스 사용');

      // 이전 텍스트 초기화
      _recognizedText = '';
      _aiResponseText = '';
      _recordingStartTime = DateTime.now();

      // 음성 인식 시작 (권한은 이미 RecordScreen에서 확인됨)
      final success = await _sttService.startListening();
      if (success) {
        print('✅ 음성 인식 시작 성공');
        return true;
      } else {
        print('❌ 음성 인식 시작 실패');
        return false;
      }
    } catch (e) {
      print('❌ 음성 인식 시작 중 오류: $e');
      return false;
    }
  }

  // 음성 인식 중지 (기존 메서드명 유지)
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      print('음성 인식이 진행 중이 아닙니다.');
      return null;
    }

    try {
      print('=== 음성 인식 중지 ===');

      await _sttService.stopListening();

      // AI 처리는 스트림에서 자동으로 처리되므로 여기서는 하지 않음
      print('✅ 음성 인식 중지 완료');
      return _recognizedText.isNotEmpty ? _recognizedText : null;
    } catch (e) {
      print('❌ 음성 인식 중지 중 오류: $e');
      return null;
    }
  }

  // AI 처리
  Future<void> _processWithAI(String text) async {
    try {
      print('=== AI 처리 시작 ===');
      print('📝 처리할 텍스트: "$text"');
      print('📏 텍스트 길이: ${text.length}');

      if (text.isEmpty) {
        print('⚠️ 빈 텍스트는 처리하지 않습니다.');
        return;
      }

      // AI 서비스에 텍스트 전송
      print('🚀 AIService.processText() 호출 중...');
      final aiResponse = await AIService.processText(text);
      print('📡 AI 서비스 응답 수신 완료');

      if (aiResponse.success && aiResponse.textResponse?.text != null) {
        _aiResponseText = aiResponse.textResponse!.text;
        _aiResponseStreamController.add(_aiResponseText);
        print('✅ AI 응답 성공: "$_aiResponseText"');

        // TTS로 음성 재생
        print('🔊 TTS 음성 재생 시작...');
        await _ttsService.speak(_aiResponseText);
        print('✅ TTS 음성 재생 완료');
      } else {
        print('❌ AI 응답이 없거나 실패했습니다.');
        print('  - success: ${aiResponse.success}');
        print('  - textResponse: ${aiResponse.textResponse?.text}');
      }
    } catch (e) {
      print('❌ AI 처리 중 오류: $e');
      print('🔍 오류 상세: ${e.toString()}');
    }
  }

  // 음성 인식 취소 (기존 메서드명 유지)
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      print('=== 음성 인식 취소 ===');
      await _sttService.cancelListening();
      _recognizedText = '';
      _aiResponseText = '';
      _recordingStartTime = null;
      print('✅ 음성 인식 취소 완료');
    } catch (e) {
      print('❌ 음성 인식 취소 중 오류: $e');
    }
  }

  // 음성 인식 상태 확인 (기존 메서드명 유지)
  Future<bool> checkRecordingStatus() async {
    return _isRecording;
  }

  // AI 응답 재생 (기존 메서드명 유지)
  Future<bool> playRecording(String? filePath) async {
    try {
      if (_aiResponseText.isEmpty) {
        print('재생할 AI 응답이 없습니다.');
        return false;
      }

      print('=== AI 응답 음성 재생 ===');
      await _ttsService.speak(_aiResponseText);
      return true;
    } catch (e) {
      print('❌ AI 응답 재생 중 오류: $e');
      return false;
    }
  }

  // 재생 중지 (기존 메서드명 유지)
  Future<void> stopPlaying() async {
    try {
      await _ttsService.stop();
      print('✅ 재생 중지 완료');
    } catch (e) {
      print('❌ 재생 중지 중 오류: $e');
    }
  }

  // 재생 일시정지 (기존 메서드명 유지)
  Future<void> pausePlaying() async {
    try {
      await _ttsService.pause();
      print('✅ 재생 일시정지 완료');
    } catch (e) {
      print('❌ 재생 일시정지 중 오류: $e');
    }
  }

  // 재생 재개 (기존 메서드명 유지)
  Future<void> resumePlaying() async {
    try {
      await _ttsService.resume();
      print('✅ 재생 재개 완료');
    } catch (e) {
      print('❌ 재생 재개 중 오류: $e');
    }
  }

  // 녹음 시간 계산
  Duration? get recordingDuration {
    if (_recordingStartTime == null) return null;
    return DateTime.now().difference(_recordingStartTime!);
  }

  // 기존 스트림들 (호환성 유지)
  Stream<bool> get playerStateStream => _playingStateController.stream;
  Stream<Duration?> get positionStream => Stream.value(null); // TTS에서는 위치 정보 없음
  Stream<Duration?> get durationStream => Stream.value(null); // TTS에서는 길이 정보 없음

  // 마이크 테스트 (기존 메서드명 유지)
  Future<bool> testMicrophone() async {
    try {
      print('=== 마이크 테스트 시작 ===');

      final hasPermission = await _requestPermission();
      if (!hasPermission) {
        print('❌ 마이크 권한이 없습니다.');
        return false;
      }

      // 간단한 음성 인식 테스트
      final success = await _sttService.startListening();
      if (success) {
        await Future.delayed(const Duration(seconds: 2));
        await _sttService.stopListening();
        print('✅ 마이크 테스트 성공');
        return true;
      } else {
        print('❌ 마이크 테스트 실패');
        return false;
      }
    } catch (e) {
      print('마이크 테스트 실패: $e');
      return false;
    }
  }

  // 리소스 해제
  void dispose() {
    _sttService.dispose();
    _ttsService.dispose();
    _textStreamController.close();
    _aiResponseStreamController.close();
    _recordingStateController.close();
    _playingStateController.close();
  }
}
