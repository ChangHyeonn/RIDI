import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isPaused = false;

  // 스트림 컨트롤러
  final StreamController<bool> _speakingStateController =
      StreamController<bool>.broadcast();
  final StreamController<String> _errorStreamController =
      StreamController<String>.broadcast();
  final StreamController<double> _progressStreamController =
      StreamController<double>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  bool get isPaused => _isPaused;

  // Streams
  Stream<bool> get speakingStateStream => _speakingStateController.stream;
  Stream<String> get errorStream => _errorStreamController.stream;
  Stream<double> get progressStream => _progressStreamController.stream;

  // 초기화
  Future<bool> initialize() async {
    print('=== TextToSpeech 초기화 시작 ===');
    print('🌐 Web 환경 여부: $kIsWeb');

    try {
      // iOS 크래시 방지를 위한 안전한 초기화
      if (kIsWeb) {
        print('🌐 Web 환경 TTS 설정');
        await _flutterTts.setLanguage('ko-KR');
        await _flutterTts.setSpeechRate(0.7); // 조금 더 빠르게
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(0.9); // 조금 더 낮은 톤
        
        // Web 환경에서 한국어 음성 설정 시도
        await _trySetKoreanVoice();
      } else {
        print('📱 모바일 환경 TTS 설정');

        // iOS에서 안전한 초기화를 위한 지연
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          print('🍎 iOS 환경 - 안전한 TTS 초기화');
          await Future.delayed(const Duration(milliseconds: 100));
        }

        await _flutterTts.setLanguage('ko-KR');
        await _flutterTts.setSpeechRate(0.7); // 0.0 ~ 1.0 (조금 더 빠르게)
        await _flutterTts.setVolume(1.0); // 0.0 ~ 1.0
        await _flutterTts.setPitch(0.9); // 0.5 ~ 2.0 (조금 더 낮은 톤)
        
        // 모바일 환경에서 한국어 음성 설정 시도
        await _trySetKoreanVoice();
      }

      // 콜백 설정
      _flutterTts.setStartHandler(() {
        print('TTS 재생 시작');
        _isSpeaking = true;
        _isPaused = false;
        _speakingStateController.add(true);
      });

      _flutterTts.setCompletionHandler(() {
        print('TTS 재생 완료');
        _isSpeaking = false;
        _isPaused = false;
        _speakingStateController.add(false);
      });

      _flutterTts.setCancelHandler(() {
        print('TTS 재생 취소');
        _isSpeaking = false;
        _isPaused = false;
        _speakingStateController.add(false);
      });

      _flutterTts.setPauseHandler(() {
        print('TTS 재생 일시정지');
        _isPaused = true;
      });

      _flutterTts.setContinueHandler(() {
        print('TTS 재생 재개');
        _isPaused = false;
      });

      _flutterTts.setErrorHandler((msg) {
        print('TTS 오류: $msg');
        _isSpeaking = false;
        _isPaused = false;
        _errorStreamController.add('음성 합성 오류: $msg');
        _speakingStateController.add(false);
      });

      // 진행률 콜백 (Android에서만 지원)
      if (defaultTargetPlatform == TargetPlatform.android) {
        _flutterTts.setProgressHandler((text, start, end, word) {
          if (end > 0) {
            final progress = end / text.length;
            _progressStreamController.add(progress);
          }
        });
      }

      _isInitialized = true;
      print('✅ TextToSpeech 초기화 성공');
      return true;
    } catch (e) {
      print('❌ TextToSpeech 초기화 중 오류: $e');
      _errorStreamController.add('음성 합성 초기화 오류: $e');
      return false;
    }
  }

  // 텍스트를 음성으로 변환하여 재생
  Future<bool> speak(String text) async {
    if (!_isInitialized) {
      print('❌ TextToSpeech가 초기화되지 않았습니다.');
      _errorStreamController.add('음성 합성이 초기화되지 않았습니다.');
      return false;
    }

    if (_isSpeaking) {
      print('이미 음성을 재생 중입니다.');
      await stop();
    }

    try {
      print('=== TTS 재생 시작 ===');
      print('재생할 텍스트: $text');

      if (text.trim().isEmpty) {
        print('❌ 재생할 텍스트가 비어있습니다.');
        _errorStreamController.add('재생할 텍스트가 비어있습니다.');
        return false;
      }

      final result = await _flutterTts.speak(text);

      if (result == 1) {
        print('✅ TTS 재생 시작 성공');
        return true;
      } else {
        print('❌ TTS 재생 시작 실패');
        _errorStreamController.add('음성 재생을 시작할 수 없습니다.');
        return false;
      }
    } catch (e) {
      print('❌ TTS 재생 중 오류: $e');
      _errorStreamController.add('음성 재생 오류: $e');
      return false;
    }
  }

  // 재생 중지
  Future<void> stop() async {
    if (!_isSpeaking) return;

    try {
      print('=== TTS 재생 중지 ===');
      await _flutterTts.stop();
      _isSpeaking = false;
      _isPaused = false;
      print('✅ TTS 재생 중지 완료');
    } catch (e) {
      print('❌ TTS 재생 중지 중 오류: $e');
      _errorStreamController.add('음성 재생 중지 오류: $e');
    }
  }

  // 재생 일시정지
  Future<void> pause() async {
    if (!_isSpeaking || _isPaused) return;

    try {
      print('=== TTS 재생 일시정지 ===');
      await _flutterTts.pause();
      _isPaused = true;
      print('✅ TTS 재생 일시정지 완료');
    } catch (e) {
      print('❌ TTS 재생 일시정지 중 오류: $e');
      _errorStreamController.add('음성 재생 일시정지 오류: $e');
    }
  }

  // 재생 재개 (Flutter TTS에서는 지원하지 않음)
  Future<void> resume() async {
    if (!_isSpeaking || !_isPaused) return;

    try {
      print('=== TTS 재생 재개 ===');
      // Flutter TTS에서는 resume 기능을 지원하지 않으므로 다시 시작
      print('⚠️ Flutter TTS에서는 재개 기능을 지원하지 않습니다.');
      _isPaused = false;
      print('✅ TTS 재생 재개 완료');
    } catch (e) {
      print('❌ TTS 재생 재개 중 오류: $e');
      _errorStreamController.add('음성 재생 재개 오류: $e');
    }
  }

  // 음성 설정 변경
  Future<void> setVoiceSettings({
    String? language,
    double? speechRate,
    double? volume,
    double? pitch,
  }) async {
    try {
      if (language != null) {
        await _flutterTts.setLanguage(language);
        print('🎤 언어 설정: $language');
      }

      if (speechRate != null) {
        await _flutterTts.setSpeechRate(speechRate);
        print('⚡ 속도 설정: $speechRate');
      }

      if (volume != null) {
        await _flutterTts.setVolume(volume);
        print('🔊 볼륨 설정: $volume');
      }

      if (pitch != null) {
        await _flutterTts.setPitch(pitch);
        print('🎵 피치 설정: $pitch');
      }
    } catch (e) {
      print('❌ 음성 설정 변경 중 오류: $e');
      _errorStreamController.add('음성 설정 변경 오류: $e');
    }
  }

  // 빠른 속도 설정 (편의 메서드)
  Future<void> setSpeechSpeed({required String speed}) async {
    double rate;
    switch (speed.toLowerCase()) {
      case 'very_slow':
        rate = 0.3;
        break;
      case 'slow':
        rate = 0.5;
        break;
      case 'normal':
        rate = 0.7;
        break;
      case 'fast':
        rate = 0.9;
        break;
      case 'very_fast':
        rate = 1.0;
        break;
      default:
        rate = 0.7;
    }
    
    await setVoiceSettings(speechRate: rate);
    print('🏃 TTS 속도 변경: $speed (${rate})');
  }

  // 음성 톤 설정 (편의 메서드)
  Future<void> setVoiceTone({required String tone}) async {
    double pitch;
    switch (tone.toLowerCase()) {
      case 'very_low':
        pitch = 0.6;
        break;
      case 'low':
        pitch = 0.8;
        break;
      case 'normal':
        pitch = 1.0;
        break;
      case 'high':
        pitch = 1.2;
        break;
      case 'very_high':
        pitch = 1.4;
        break;
      default:
        pitch = 0.9;
    }
    
    await setVoiceSettings(pitch: pitch);
    print('🎵 TTS 톤 변경: $tone (${pitch})');
  }

  // 사용 가능한 언어 목록 가져오기
  Future<List<Map<String, String>>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return languages.cast<Map<String, String>>();
    } catch (e) {
      print('사용 가능한 언어 목록 가져오기 오류: $e');
      return [];
    }
  }

  // 사용 가능한 음성 목록 가져오기
  Future<List<Map<String, String>>> getAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      return voices.cast<Map<String, String>>();
    } catch (e) {
      print('사용 가능한 음성 목록 가져오기 오류: $e');
      return [];
    }
  }

  // 한국어 음성 설정 시도
  Future<void> _trySetKoreanVoice() async {
    try {
      print('🎤 한국어 음성 설정 시도');
      
      final voices = await getAvailableVoices();
      print('🎤 사용 가능한 음성 수: ${voices.length}');
      
      // 한국어 음성 찾기
      Map<String, String>? koreanVoice;
      
      for (final voice in voices) {
        final name = voice['name'] ?? '';
        final locale = voice['locale'] ?? '';
        
        print('🎤 음성: $name (로케일: $locale)');
        
        // 한국어 음성 우선순위
        if (locale.startsWith('ko') || name.toLowerCase().contains('korean')) {
          koreanVoice = voice;
          print('✅ 한국어 음성 발견: $name');
          break;
        }
      }
      
      // 한국어 음성 설정
      if (koreanVoice != null) {
        await _flutterTts.setVoice(koreanVoice);
        print('✅ 한국어 음성 설정 완료: ${koreanVoice['name']}');
      } else {
        print('⚠️ 한국어 음성을 찾을 수 없어 기본 설정 사용');
      }
    } catch (e) {
      print('❌ 한국어 음성 설정 중 오류: $e');
    }
  }

  // 현재 설정 가져오기 (Flutter TTS에서는 getter를 지원하지 않음)
  Future<Map<String, dynamic>> getCurrentSettings() async {
    try {
      // Flutter TTS에서는 현재 설정을 가져오는 getter가 없으므로
      // 설정 시 저장한 값들을 반환하거나 기본값 반환
      return {
        'language': 'ko-KR',
        'speechRate': 0.7,
        'volume': 1.0,
        'pitch': 0.9,
      };
    } catch (e) {
      print('현재 설정 가져오기 오류: $e');
      return {};
    }
  }

  // 리소스 해제
  void dispose() {
    stop();
    _speakingStateController.close();
    _errorStreamController.close();
    _progressStreamController.close();
  }
}
