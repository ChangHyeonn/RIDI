import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  String _lastWords = '';
  String _currentWords = '';

  // 스트림 컨트롤러
  final StreamController<String> _textStreamController =
      StreamController<String>.broadcast();
  final StreamController<bool> _listeningStateController =
      StreamController<bool>.broadcast();
  final StreamController<String> _errorStreamController =
      StreamController<String>.broadcast();

  // Getters
  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get lastWords => _lastWords;
  String get currentWords => _currentWords;

  // Streams
  Stream<String> get textStream => _textStreamController.stream;
  Stream<bool> get listeningStateStream => _listeningStateController.stream;
  Stream<String> get errorStream => _errorStreamController.stream;

  // 초기화
  Future<bool> initialize() async {
    print('=== SpeechToText 초기화 시작 ===');
    print('🌐 Web 환경 여부: $kIsWeb');

    try {
      // SpeechToText 초기화 (audio_app2 방식)
      print('🔧 SpeechToText 초기화 시작...');

      // Web 환경에서는 더 간단한 초기화 사용
      if (kIsWeb) {
        print('🌐 Web 환경 초기화 설정');
        _isAvailable = await _speech.initialize(
          onError: (error) {
            print('❌ Web 음성 인식 오류: ${error.errorMsg}');
            print('  - errorCode: ${error.errorMsg}');

            // 타임아웃 오류에 대한 특별 처리
            if (error.errorMsg == 'error_speech_timeout') {
              print('⏰ Web 음성 인식 타임아웃 - 말하기 전에 시간이 초과되었습니다.');
              _errorStreamController.add('음성 인식 타임아웃. 다시 시도해주세요.');
            } else {
              _errorStreamController.add('음성 인식 오류: ${error.errorMsg}');
            }

            _isListening = false;
            _listeningStateController.add(false);
          },
          onStatus: (status) {
            print('📊 Web 음성 인식 상태: $status');
            if (status == 'done' ||
                status == 'notListening' ||
                status == 'error') {
              _isListening = false;
              _listeningStateController.add(false);
            }
          },
          debugLogging: true, // Web에서는 디버그 로깅 활성화
        );
      } else {
        print('📱 모바일 환경 초기화 설정');
        _isAvailable = await _speech.initialize(
          onError: (error) {
            print('❌ 음성 인식 오류 발생:');
            print('  - errorMsg: ${error.errorMsg}');
            print('  - permanent: ${error.permanent}');
            print('  - errorCode: ${error.errorMsg}');

            // 타임아웃 오류에 대한 특별 처리
            if (error.errorMsg == 'error_speech_timeout') {
              print('⏰ 음성 인식 타임아웃 - 말하기 전에 시간이 초과되었습니다.');
              _errorStreamController.add('음성 인식 타임아웃. 다시 시도해주세요.');
            } else {
              _errorStreamController.add('음성 인식 오류: ${error.errorMsg}');
            }

            _isListening = false;
            _listeningStateController.add(false);
          },
          onStatus: (status) {
            print('📊 음성 인식 상태 변경: $status');
            if (status == 'done' ||
                status == 'notListening' ||
                status == 'error') {
              print('🛑 음성 인식 상태 종료: $status');
              _isListening = false;
              _listeningStateController.add(false);
            }
          },
          debugLogging: kDebugMode,
        );
      }

      print('🔧 SpeechToText 초기화 완료 - _isAvailable: $_isAvailable');

      if (_isAvailable) {
        print('✅ SpeechToText 초기화 성공');

        // 추가 상태 확인
        print('🔍 추가 상태 확인:');
        print('  - isSupported: ${_speech.isAvailable}');
        print('  - _isAvailable: $_isAvailable');

        return true;
      } else {
        print('❌ SpeechToText 초기화 실패');
        print('🔍 실패 원인 분석:');
        print('  - isSupported: ${_speech.isAvailable}');
        print('  - _isAvailable: $_isAvailable');
        _errorStreamController.add('음성 인식 기능을 초기화할 수 없습니다.');
        return false;
      }
    } catch (e) {
      print('❌ SpeechToText 초기화 중 오류: $e');
      _errorStreamController.add('음성 인식 초기화 오류: $e');
      return false;
    }
  }

  // 권한 확인
  Future<bool> _requestPermission() async {
    print('=== 음성 인식 권한 확인 ===');

    try {
      // Web 환경에서는 권한 처리가 다름
      if (kIsWeb) {
        print('🌐 Web 환경에서는 브라우저가 자동으로 권한을 요청합니다.');
        // Web에서는 브라우저가 자동으로 권한을 요청하므로 true 반환
        return true;
      }

      // 마이크 권한 확인
      var micStatus = await Permission.microphone.status;
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

      // 권한 요청 (거부된 경우)
      if (micStatus == PermissionStatus.denied) {
        print('마이크 권한을 요청합니다...');
        micStatus = await Permission.microphone.request();
        print('마이크 권한 요청 결과: $micStatus');

        if (micStatus == PermissionStatus.granted) {
          print('✅ 마이크 권한이 허용되었습니다.');
          return true;
        }
      }

      print('❌ 마이크 권한이 거부되었습니다.');
      print('⚠️ 음성 인식을 사용하려면 마이크 권한이 필요합니다.');
      return false;
    } catch (e) {
      print('권한 확인 중 오류: $e');
      return false;
    }
  }

  // 음성 인식 시작 (audio_app2 방식으로 완전히 변경)
  Future<bool> startListening({
    String? localeId,
    bool partialResults = true,
    bool onDevice = false,
  }) async {
    print('=== 음성 인식 시작 요청 (audio_app2 방식) ===');
    print('🌐 Web 환경 여부: $kIsWeb');

    // 권한 확인 (Error 7 방지)
    if (!kIsWeb) {
      print('🔐 권한 확인 중...');
      final hasPermission = await _requestPermission();
      if (!hasPermission) {
        print('❌ 권한이 없어서 음성 인식을 시작할 수 없습니다.');
        _errorStreamController.add('마이크 권한이 필요합니다. 설정에서 권한을 허용해주세요.');
        return false;
      }
      print('✅ 권한 확인 완료');
    }

    // 이미 음성 인식 중이면 먼저 중지
    if (_isListening) {
      print('이미 음성 인식 중입니다. 먼저 중지합니다.');
      await stopListening();
      await Future.delayed(const Duration(milliseconds: 500)); // 잠시 대기
    }

    try {
      print('=== audio_app2 방식으로 초기화 및 시작 ===');

      // audio_app2 방식: 매번 initialize 호출
      bool available = await _speech.initialize(
        onError: (error) {
          print('❌ 음성 인식 오류: ${error.errorMsg}');
          _errorStreamController.add('음성 인식 오류: ${error.errorMsg}');
          _isListening = false;
          _listeningStateController.add(false);
        },
        onStatus: (status) {
          print('📊 음성 인식 상태: $status');
          if (status == 'done' ||
              status == 'notListening' ||
              status == 'error') {
            _isListening = false;
            _listeningStateController.add(false);
          }
        },
      );

      print('🔧 SpeechToText 초기화 결과: $available');

      if (available) {
        // 이전 텍스트 초기화
        _currentWords = '';
        _lastWords = '';

        // audio_app2 방식: 매우 간단한 listen 파라미터
        _speech.listen(
          onResult: (result) {
            print(
              '🎤 음성 인식 결과: "${result.recognizedWords}" (final: ${result.finalResult})',
            );
            _currentWords = result.recognizedWords;

            if (result.finalResult) {
              _lastWords = result.recognizedWords;
              _textStreamController.add(_lastWords);
            } else {
              _textStreamController.add(_currentWords);
            }
          },
          onSoundLevelChange: (level) {
            print('🔊 소리 레벨: $level');
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 30), // audio_app2와 동일하게 30초
        );

        _isListening = true;
        _listeningStateController.add(true);
        print('✅ 음성 인식 시작 성공 (audio_app2 방식)');
        return true;
      } else {
        print('❌ SpeechToText 초기화 실패');
        _errorStreamController.add('음성 인식 기능을 초기화할 수 없습니다.');
        return false;
      }
    } catch (e) {
      print('❌ 음성 인식 시작 중 오류: $e');
      _errorStreamController.add('음성 인식 시작 오류: $e');
      return false;
    }
  }

  // 음성 인식 중지
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      print('=== 음성 인식 중지 ===');
      await _speech.stop();
      _isListening = false;
      _listeningStateController.add(false);
      print('✅ 음성 인식 중지 완료');
    } catch (e) {
      print('❌ 음성 인식 중지 중 오류: $e');
      _errorStreamController.add('음성 인식 중지 오류: $e');
    }
  }

  // 음성 인식 취소
  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      print('=== 음성 인식 취소 ===');
      await _speech.cancel();
      _isListening = false;
      _listeningStateController.add(false);
      _currentWords = '';
      print('✅ 음성 인식 취소 완료');
    } catch (e) {
      print('❌ 음성 인식 취소 중 오류: $e');
      _errorStreamController.add('음성 인식 취소 오류: $e');
    }
  }

  // 사용 가능한 로케일 목록 가져오기
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    return await _speech.locales();
  }

  // 현재 상태 확인
  bool get isSupported => _speech.isAvailable;

  // 리소스 해제
  void dispose() {
    stopListening();
    _textStreamController.close();
    _listeningStateController.close();
    _errorStreamController.close();
  }
}
