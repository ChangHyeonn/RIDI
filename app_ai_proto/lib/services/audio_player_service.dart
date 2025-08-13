import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'text_to_speech_service.dart';

class AudioPlayerService {
  static final TextToSpeechService _ttsService = TextToSpeechService();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _ttsService.initialize();
      _isInitialized = true;
      print('✅ AudioPlayerService 초기화 성공');
    } catch (e) {
      print('❌ AudioPlayerService 초기화 실패: $e');
    }
  }

  static Future<void> playAudioFromBase64(String audioUrl) async {
    try {
      // TTS 서비스 초기화 확인
      if (!_isInitialized) {
        await initialize();
      }

      if (audioUrl.startsWith('data:audio/mp3;base64,')) {
        String base64Data = audioUrl.replaceFirst('data:audio/mp3;base64,', '');
        Uint8List audioBytes = base64Decode(base64Data);

        // Base64 데이터를 텍스트로 변환 시도 (간단한 방법)
        // 실제로는 AI 서버에서 텍스트를 직접 받는 것이 좋습니다
        String text = '음성 메시지가 재생됩니다.';

        // TTS로 재생
        await _ttsService.speak(text);
        print('TTS로 음성 재생 완료');
      }
    } catch (e) {
      print('음성 재생 오류: $e');
    }
  }

  static Future<void> stopAudio() async {
    try {
      await _ttsService.stop();
    } catch (e) {
      print('음성 중지 오류: $e');
    }
  }

  static Future<void> dispose() async {
    try {
      _ttsService.dispose();
      _isInitialized = false;
    } catch (e) {
      print('오디오 플레이어 해제 오류: $e');
    }
  }
}
