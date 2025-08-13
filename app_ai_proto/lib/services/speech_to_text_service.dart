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
      // Web 환경에서는 권한 처리를 다르게
      if (kIsWeb) {
        print('🌐 Web 환경에서 초기화 중...');
        print('⚠️ Web에서는 브라우저가 자동으로 마이크 권한을 요청합니다.');
        // Web에서는 권한 확인을 건너뛰고 바로 초기화 시도
      } else {
        // 모바일 환경에서 권한 확인
        final hasPermission = await _requestPermission();
        if (!hasPermission) {
          print('❌ 음성 인식 권한이 없습니다.');
          _errorStreamController.add('음성 인식 권한이 필요합니다.');
          return false;
        }
      }

      // SpeechToText 초기화 (audio_app2 방식)
      print('🔧 SpeechToText 초기화 시작...');

      // Web 환경에서는 더 간단한 초기화 사용
      if (kIsWeb) {
        _isAvailable = await _speech.initialize(
          onError: (error) {
            print('❌ Web 음성 인식 오류: ${error.errorMsg}');
            _errorStreamController.add('음성 인식 오류: ${error.errorMsg}');
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
        _isAvailable = await _speech.initialize(
          onError: (error) {
            print('❌ 음성 인식 오류 발생:');
            print('  - errorMsg: ${error.errorMsg}');
            print('  - permanent: ${error.permanent}');
            _errorStreamController.add('음성 인식 오류: ${error.errorMsg}');
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
        return true;
      } else {
        print('❌ SpeechToText 초기화 실패');
        _errorStreamController.add('음성 인식 기능을 초기화할 수 없습니다.');
        return false;
      }
    } catch (e) {
      print('❌ SpeechToText 초기화 중 오류: $e');
      _errorStreamController.add('음성 인식 초기화 오류: $e');
      return false;
    }
  }

  // 권한 요청
  Future<bool> _requestPermission() async {
    print('=== 음성 인식 권한 요청 ===');

    try {
      // Web 환경에서는 권한 처리가 다름
      if (kIsWeb) {
        print('🌐 Web 환경에서는 브라우저가 자동으로 권한을 요청합니다.');
        // Web에서는 브라우저가 자동으로 권한을 요청하므로 true 반환
        return true;
      }

      // 마이크 권한 확인
      final micStatus = await Permission.microphone.status;
      print('현재 마이크 권한 상태: $micStatus');

      if (micStatus == PermissionStatus.granted) {
        print('✅ 마이크 권한이 이미 허용되어 있습니다.');
        return true;
      }

      if (micStatus == PermissionStatus.permanentlyDenied) {
        print('❌ 마이크 권한이 영구적으로 거부되었습니다.');
        await openAppSettings();
        return false;
      }

      // 권한 요청
      print('마이크 권한을 요청합니다...');
      final micResult = await Permission.microphone.request();
      print('마이크 권한 요청 결과: $micResult');

      if (micResult == PermissionStatus.granted) {
        print('✅ 마이크 권한이 허용되었습니다.');
        return true;
      } else {
        print('❌ 마이크 권한이 거부되었습니다.');
        return false;
      }
    } catch (e) {
      print('권한 요청 중 오류: $e');
      return false;
    }
  }

  // 음성 인식 시작 (웹 환경 최적화)
  Future<bool> startListening({
    String? localeId,
    bool partialResults = true,
    bool onDevice = false,
  }) async {
    if (!_isAvailable) {
      print('❌ SpeechToText가 초기화되지 않았습니다.');
      _errorStreamController.add('음성 인식이 초기화되지 않았습니다.');
      return false;
    }

    // 이미 음성 인식 중이면 먼저 중지
    if (_isListening) {
      print('이미 음성 인식 중입니다. 먼저 중지합니다.');
      await stopListening();
      await Future.delayed(const Duration(milliseconds: 500)); // 잠시 대기
    }

    try {
      print('=== 음성 인식 시작 ===');
      print('🌐 Web 환경 여부: $kIsWeb');

      // 이전 텍스트 초기화
      _currentWords = '';
      _lastWords = '';

      // Web 환경에서는 audio_app2 방식으로 최대한 간단하게
      if (kIsWeb) {
        print('🌐 Web 환경 음성 인식 설정 (audio_app2 방식):');
        print('  - 최소한의 파라미터만 사용');
        print('  - 반환값 확인하지 않음');

        // audio_app2 방식: 반환값을 확인하지 않고 바로 시작
        _speech.listen(
          onResult: (result) {
            print(
              '🎤 Web 음성 인식 결과: "${result.recognizedWords}" (final: ${result.finalResult})',
            );
            _currentWords = result.recognizedWords;

            if (result.finalResult) {
              _lastWords = result.recognizedWords;
              _textStreamController.add(_lastWords);
            } else {
              _textStreamController.add(_currentWords);
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 30),
        );
      } else {
        // 모바일 환경
        print('📱 모바일 환경 음성 인식 설정');
        _speech.listen(
          onResult: (result) {
            print(
              '🎤 모바일 음성 인식 결과: "${result.recognizedWords}" (final: ${result.finalResult})',
            );
            _currentWords = result.recognizedWords;

            if (result.finalResult) {
              _lastWords = result.recognizedWords;
              _textStreamController.add(_lastWords);
            } else {
              _textStreamController.add(_currentWords);
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 30),
          partialResults: partialResults,
          onDevice: onDevice,
          localeId: localeId,
        );
      }

      _isListening = true;
      _listeningStateController.add(true);
      print('✅ 음성 인식 시작 성공');
      return true;
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
