import 'dart:async';
import 'package:flutter/foundation.dart';
import 'speech_to_text_service.dart';
import 'text_to_speech_service.dart';
import 'ai_service.dart';
import '../models/ai_response.dart';

class UnifiedVoiceService {
  final SpeechToTextService _sttService = SpeechToTextService();
  final TextToSpeechService _ttsService = TextToSpeechService();

  bool _isInitialized = false;
  bool _isProcessing = false;
  String _currentText = '';
  String _lastProcessedText = '';

  // 스트림 컨트롤러
  final StreamController<String> _statusStreamController =
      StreamController<String>.broadcast();
  final StreamController<String> _textStreamController =
      StreamController<String>.broadcast();
  final StreamController<AIResponse?> _aiResponseStreamController =
      StreamController<AIResponse?>.broadcast();
  final StreamController<String> _errorStreamController =
      StreamController<String>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;
  bool get isListening => _sttService.isListening;
  bool get isSpeaking => _ttsService.isSpeaking;
  String get currentText => _currentText;
  String get lastProcessedText => _lastProcessedText;

  // Streams
  Stream<String> get statusStream => _statusStreamController.stream;
  Stream<String> get textStream => _textStreamController.stream;
  Stream<AIResponse?> get aiResponseStream =>
      _aiResponseStreamController.stream;
  Stream<String> get errorStream => _errorStreamController.stream;

  // 초기화
  Future<bool> initialize() async {
    print('=== UnifiedVoiceService 초기화 시작 ===');

    try {
      // STT 초기화
      print('STT 서비스 초기화 중...');
      final sttInitialized = await _sttService.initialize();
      if (!sttInitialized) {
        print('❌ STT 서비스 초기화 실패');
        _errorStreamController.add('음성 인식 서비스 초기화 실패');
        return false;
      }

      // TTS 초기화
      print('TTS 서비스 초기화 중...');
      final ttsInitialized = await _ttsService.initialize();
      if (!ttsInitialized) {
        print('❌ TTS 서비스 초기화 실패');
        _errorStreamController.add('음성 합성 서비스 초기화 실패');
        return false;
      }

      // 스트림 구독 설정
      _setupStreamSubscriptions();

      _isInitialized = true;
      print('✅ UnifiedVoiceService 초기화 성공');
      _statusStreamController.add('음성 서비스가 준비되었습니다.');
      return true;
    } catch (e) {
      print('❌ UnifiedVoiceService 초기화 중 오류: $e');
      _errorStreamController.add('음성 서비스 초기화 오류: $e');
      return false;
    }
  }

  // 스트림 구독 설정
  void _setupStreamSubscriptions() {
    // STT 텍스트 스트림 구독
    _sttService.textStream.listen((text) {
      _currentText = text;
      _textStreamController.add(text);
      print('음성 인식 텍스트: $text');
    });

    // STT 오류 스트림 구독
    _sttService.errorStream.listen((error) {
      _errorStreamController.add('음성 인식 오류: $error');
    });

    // TTS 오류 스트림 구독
    _ttsService.errorStream.listen((error) {
      _errorStreamController.add('음성 합성 오류: $error');
    });

    // TTS 재생 상태 스트림 구독
    _ttsService.speakingStateStream.listen((isSpeaking) {
      if (isSpeaking) {
        _statusStreamController.add('AI 응답을 음성으로 재생 중입니다...');
      } else {
        _statusStreamController.add('음성 재생이 완료되었습니다.');
      }
    });
  }

  // 음성 인식 시작
  Future<bool> startVoiceRecognition() async {
    if (!_isInitialized) {
      print('❌ UnifiedVoiceService가 초기화되지 않았습니다.');
      _errorStreamController.add('음성 서비스가 초기화되지 않았습니다.');
      return false;
    }

    if (_isProcessing) {
      print('이미 음성 처리가 진행 중입니다.');
      return false;
    }

    try {
      print('=== 음성 인식 시작 ===');
      _statusStreamController.add('음성 인식을 시작합니다. 말씀해주세요.');

      final success = await _sttService.startListening();
      if (success) {
        print('✅ 음성 인식 시작 성공');
        return true;
      } else {
        print('❌ 음성 인식 시작 실패');
        _errorStreamController.add('음성 인식을 시작할 수 없습니다.');
        return false;
      }
    } catch (e) {
      print('❌ 음성 인식 시작 중 오류: $e');
      _errorStreamController.add('음성 인식 시작 오류: $e');
      return false;
    }
  }

  // 음성 인식 중지 및 AI 처리
  Future<void> stopVoiceRecognitionAndProcess() async {
    if (!_sttService.isListening) return;

    try {
      print('=== 음성 인식 중지 및 AI 처리 ===');
      _statusStreamController.add('음성 인식을 중지하고 AI 처리 중...');

      // 음성 인식 중지
      await _sttService.stopListening();

      // 인식된 텍스트 확인
      final recognizedText = _sttService.lastWords.trim();
      if (recognizedText.isEmpty) {
        print('인식된 텍스트가 없습니다.');
        _statusStreamController.add('음성을 인식하지 못했습니다. 다시 시도해주세요.');
        return;
      }

      _lastProcessedText = recognizedText;
      print('인식된 텍스트: $recognizedText');
      _statusStreamController.add('인식된 텍스트: $recognizedText');

      // AI 처리 시작
      await _processWithAI(recognizedText);
    } catch (e) {
      print('❌ 음성 인식 중지 및 AI 처리 중 오류: $e');
      _errorStreamController.add('음성 처리 오류: $e');
    }
  }

  // AI 처리
  Future<void> _processWithAI(String text) async {
    if (_isProcessing) return;

    try {
      _isProcessing = true;
      _statusStreamController.add('AI 서버에 요청 중...');

      print('=== AI 처리 시작 ===');
      print('처리할 텍스트: $text');

      // AI 서비스에 텍스트 전송 (임시로 더미 응답 생성)
      // TODO: AI 서버에 텍스트 처리 API 추가 후 실제 호출
      // final aiResponse = await AIService.processText(text);

      // 임시 더미 응답 생성
      final aiResponse = AIResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        processingResult: null,
        responseText:
            '음성 인식이 완료되었습니다. 인식된 텍스트: "$text". AI 서버의 텍스트 처리 API가 준비되면 실제 AI 응답을 받을 수 있습니다.',
      );

      _aiResponseStreamController.add(aiResponse);
      print('AI 응답: ${aiResponse.responseText}');

      // TTS로 응답 재생
      if (aiResponse.responseText != null) {
        await _ttsService.speak(aiResponse.responseText!);
      }

      _isProcessing = false;
      _statusStreamController.add('AI 처리가 완료되었습니다.');
    } catch (e) {
      _isProcessing = false;
      print('❌ AI 처리 중 오류: $e');
      _errorStreamController.add('AI 처리 오류: $e');
      _statusStreamController.add('AI 처리 중 오류가 발생했습니다.');
    }
  }

  // 음성 인식 취소
  Future<void> cancelVoiceRecognition() async {
    try {
      print('=== 음성 인식 취소 ===');
      await _sttService.cancelListening();
      _statusStreamController.add('음성 인식이 취소되었습니다.');
    } catch (e) {
      print('❌ 음성 인식 취소 중 오류: $e');
      _errorStreamController.add('음성 인식 취소 오류: $e');
    }
  }

  // TTS 재생 중지
  Future<void> stopTTS() async {
    try {
      print('=== TTS 재생 중지 ===');
      await _ttsService.stop();
      _statusStreamController.add('음성 재생이 중지되었습니다.');
    } catch (e) {
      print('❌ TTS 재생 중지 중 오류: $e');
      _errorStreamController.add('음성 재생 중지 오류: $e');
    }
  }

  // 텍스트를 직접 AI에 전송
  Future<void> processTextDirectly(String text) async {
    if (text.trim().isEmpty) {
      _errorStreamController.add('처리할 텍스트가 비어있습니다.');
      return;
    }

    _currentText = text;
    _textStreamController.add(text);
    await _processWithAI(text);
  }

  // 음성 설정 변경
  Future<void> updateVoiceSettings({
    String? language,
    double? speechRate,
    double? volume,
    double? pitch,
  }) async {
    try {
      await _ttsService.setVoiceSettings(
        language: language,
        speechRate: speechRate,
        volume: volume,
        pitch: pitch,
      );
      print('음성 설정이 업데이트되었습니다.');
    } catch (e) {
      print('음성 설정 업데이트 중 오류: $e');
      _errorStreamController.add('음성 설정 업데이트 오류: $e');
    }
  }

  // 현재 상태 정보 가져오기
  Map<String, dynamic> getCurrentStatus() {
    return {
      'isInitialized': _isInitialized,
      'isProcessing': _isProcessing,
      'isListening': _sttService.isListening,
      'isSpeaking': _ttsService.isSpeaking,
      'currentText': _currentText,
      'lastProcessedText': _lastProcessedText,
    };
  }

  // 리소스 해제
  void dispose() {
    _sttService.dispose();
    _ttsService.dispose();
    _statusStreamController.close();
    _textStreamController.close();
    _aiResponseStreamController.close();
    _errorStreamController.close();
  }
}
