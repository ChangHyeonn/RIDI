import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  String _lastWords = '';
  String _currentWords = '';
  DateTime? _lastStopAt; // 연속 재시작 안정화를 위한 쿨다운 기준
  bool _keepAlive = false; // 사용자가 중단할 때까지 유지
  bool _userRequestedStop = false; // 사용자가 명시적으로 stop/cancel 했는지
  String? _lastLocaleId; // 자동 재시작용 마지막 설정
  bool _lastPartialResults = true;
  bool _lastOnDevice = false;

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

            // 실제 오류인지 확인 (타임아웃이나 일시적 오류는 무시)
            if (error.errorMsg == 'error_speech_timeout' ||
                error.errorMsg == 'error_no_speech' ||
                error.errorMsg == 'error_audio' ||
                error.errorMsg == 'error_network') {
              print('⚠️ Web 일시적 오류로 판단하여 무시: ${error.errorMsg}');
              // 오류 스트림으로 전송하지 않음
            } else {
              print('❌ Web 실제 오류로 판단하여 전송: ${error.errorMsg}');
              if (!_errorStreamController.isClosed) {
                _errorStreamController.add('음성 인식 오류: ${error.errorMsg}');
              }
            }

            _isListening = false;
            if (!_listeningStateController.isClosed) {
              _listeningStateController.add(false);
            }
          },
          onStatus: (status) {
            print('📊 Web 음성 인식 상태: $status');
            if (status == 'done' ||
                status == 'notListening' ||
                status == 'error') {
              _isListening = false;
              // 스트림이 닫히지 않았을 때만 이벤트 추가
              if (!_listeningStateController.isClosed) {
                _listeningStateController.add(false);
              }
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

            // 실제 오류인지 확인 (타임아웃이나 일시적 오류는 무시)
            if (error.errorMsg == 'error_speech_timeout' ||
                error.errorMsg == 'error_no_speech' ||
                error.errorMsg == 'error_audio' ||
                error.errorMsg == 'error_network') {
              print('⚠️ 모바일 일시적 오류로 판단하여 무시: ${error.errorMsg}');
              // 오류 스트림으로 전송하지 않음
            } else {
              print('❌ 모바일 실제 오류로 판단하여 전송: ${error.errorMsg}');
              if (!_errorStreamController.isClosed) {
                _errorStreamController.add('음성 인식 오류: ${error.errorMsg}');
              }
            }

            _isListening = false;
            if (!_listeningStateController.isClosed) {
              _listeningStateController.add(false);
            }
          },
          onStatus: (status) {
            print('📊 음성 인식 상태 변경: $status');
            if (status == 'done' || status == 'notListening') {
              if (_keepAlive && !_userRequestedStop) {
                print('♻️ 상태=$status, 자동 재시작 (keepAlive)');
                _scheduleAutoRestart();
                return;
              }
              print('🛑 음성 인식 상태 종료: $status');
              _isListening = false;
              if (!_listeningStateController.isClosed) {
                _listeningStateController.add(false);
              }
            } else if (status == 'error') {
              if (_keepAlive && !_userRequestedStop) {
                print('♻️ 상태=error, 자동 재시작 (keepAlive)');
                _scheduleAutoRestart();
                return;
              }
              print('🛑 음성 인식 상태 종료: error');
              _isListening = false;
              if (!_listeningStateController.isClosed) {
                _listeningStateController.add(false);
              }
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
    bool assumePermissionGranted = false,
    bool keepAlive = true,
  }) async {
    print('=== 음성 인식 시작 요청 (audio_app2 방식) ===');
    print('🌐 Web 환경 여부: $kIsWeb');

    // 권한 확인 (Error 7 방지)
    if (!kIsWeb && !assumePermissionGranted) {
      print('🔐 권한 확인 중...');
      final hasPermission = await _requestPermission();
      if (!hasPermission) {
        print('❌ 권한이 없어서 음성 인식을 시작할 수 없습니다.');
        _errorStreamController.add('마이크 권한이 필요합니다. 설정에서 권한을 허용해주세요.');
        return false;
      }
      print('✅ 권한 확인 완료');
    }

    // 바로 직전 stop/cancel 이후 엔진 정리 대기 (바쁜 상태/무음 -2.0 방지)
    if (_lastStopAt != null) {
      final diff = DateTime.now().difference(_lastStopAt!);
      const coolDown = Duration(milliseconds: 350);
      if (diff < coolDown) {
        final waitMs = coolDown - diff;
        print('⏳ STT 재시작 쿨다운 대기: ${waitMs.inMilliseconds}ms');
        await Future.delayed(waitMs);
      }
    }

    // 엔진 상태 강제 초기화: 바쁜 상태/유령 세션 제거
    try {
      await _speech.cancel();
      print('🔄 STT 엔진 상태 초기화(cancel)');
      await Future.delayed(const Duration(milliseconds: 150));
    } catch (_) {}

    // 이미 음성 인식 중이면 먼저 중지
    if (_isListening) {
      print('이미 음성 인식 중입니다. 먼저 중지합니다.');
      await stopListening();
      await Future.delayed(const Duration(milliseconds: 500)); // 잠시 대기
    }

    try {
      print('=== audio_app2 방식으로 초기화 및 시작 ===');

      // audio_app2 방식: 매번 initialize 호출
      bool available = _isAvailable
          ? true
          : await _speech.initialize(
              onError: (error) {
                print('❌ 음성 인식 오류: ${error.errorMsg}');

                // 실제 오류인지 확인 (타임아웃이나 일시적 오류는 무시)
                if (error.errorMsg == 'error_speech_timeout' ||
                    error.errorMsg == 'error_no_speech' ||
                    error.errorMsg == 'error_audio' ||
                    error.errorMsg == 'error_network') {
                  print('⚠️ 일시적 오류로 판단하여 무시: ${error.errorMsg}');
                  // 오류 스트림으로 전송하지 않음
                } else {
                  print('❌ 실제 오류로 판단하여 전송: ${error.errorMsg}');
                  if (!_errorStreamController.isClosed) {
                    _errorStreamController.add('음성 인식 오류: ${error.errorMsg}');
                  }
                }

                _isListening = false;
                if (!_listeningStateController.isClosed) {
                  _listeningStateController.add(false);
                }
              },
              onStatus: (status) {
                print('📊 음성 인식 상태: $status');
                if (status == 'done' ||
                    status == 'notListening' ||
                    status == 'error') {
                  _isListening = false;
                  // 스트림이 닫히지 않았을 때만 이벤트 추가
                  if (!_listeningStateController.isClosed) {
                    _listeningStateController.add(false);
                  }
                }
              },
            );

      print('🔧 SpeechToText 초기화 결과: $available');

      if (available) {
        _isAvailable = true;
        _keepAlive = keepAlive;
        _userRequestedStop = false;
        // 이전 텍스트 초기화
        _currentWords = '';
        _lastWords = '';

        // audio_app2 방식: 매우 간단한 listen 파라미터
        // 로케일 자동 선택 로직 (에러 방지)
        String? selectedLocaleId = localeId;
        try {
          final locales = await _speech.locales();
          // 1) 사용자가 넘긴 localeId가 지원되는지 확인
          if (selectedLocaleId != null &&
              !locales.any(
                (l) =>
                    l.localeId.toLowerCase() == selectedLocaleId!.toLowerCase(),
              )) {
            print('⚠️ 전달된 localeId가 기기에서 지원되지 않습니다: $selectedLocaleId');
            selectedLocaleId = null;
          }

          // 2) ko_* 지원 시 ko 우선 선택
          if (selectedLocaleId == null) {
            final ko = locales.firstWhere(
              (l) => l.localeId.toLowerCase().startsWith('ko'),
              orElse: () => stt.LocaleName('', ''),
            );
            if (ko.localeId.isNotEmpty) {
              selectedLocaleId = ko.localeId;
            }
          }

          // 3) 그래도 없으면 시스템 기본 로케일 사용 시 null 유지 (플러그인이 자동 선택)
          print('🌏 STT 로케일 최종 선택: ${selectedLocaleId ?? '(system default)'}');
        } catch (e) {
          print('로케일 조회 실패, 시스템 기본값 사용: $e');
          selectedLocaleId = null; // 기본값에 위임
        }

        // 자동 재시작을 위한 마지막 리슨 설정 저장
        _lastLocaleId = selectedLocaleId;
        _lastPartialResults = partialResults;
        _lastOnDevice = onDevice;

        _speech.listen(
          onResult: (result) {
            print(
              '🎤 음성 인식 결과: "${result.recognizedWords}" (final: ${result.finalResult})',
            );
            _currentWords = result.recognizedWords;

            // 실시간 텍스트 표시를 위해 중간 결과도 스트림으로 전송
            if (result.recognizedWords.isNotEmpty) {
              print('🔄 실시간 텍스트 전송: "${result.recognizedWords}"');
              _textStreamController.add(result.recognizedWords);
            }

            // 최종 결과 저장
            if (result.finalResult) {
              _lastWords = result.recognizedWords;
              print('✅ 최종 결과 저장: "$_lastWords"');
            }
          },
          onSoundLevelChange: (level) {
            print('🔊 소리 레벨: $level');
          },
          listenFor: const Duration(minutes: 15), // 더 길게 유지
          pauseFor: const Duration(minutes: 10), // 무음 허용 시간 확대
          partialResults: partialResults,
          localeId: selectedLocaleId, // null이면 시스템 기본 로케일 사용
          listenMode: stt.ListenMode.dictation,
          onDevice: onDevice,
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
    try {
      print('=== 음성 인식 중지 ===');
      _keepAlive = false;
      _userRequestedStop = true;
      await _speech.stop();
      _isListening = false;
      _listeningStateController.add(false);
      _lastStopAt = DateTime.now();
      print('✅ 음성 인식 중지 완료');
    } catch (e) {
      print('❌ 음성 인식 중지 중 오류: $e');
      _errorStreamController.add('음성 인식 중지 오류: $e');
    }
  }

  // 음성 인식 취소
  Future<void> cancelListening() async {
    try {
      print('=== 음성 인식 취소 ===');
      _keepAlive = false;
      _userRequestedStop = true;
      await _speech.cancel();
      _isListening = false;
      _listeningStateController.add(false);
      _currentWords = '';
      _lastStopAt = DateTime.now();
      print('✅ 음성 인식 취소 완료');
    } catch (e) {
      print('❌ 음성 인식 취소 중 오류: $e');
      _errorStreamController.add('음성 인식 취소 오류: $e');
    }
  }

  // 강제 종료: keepAlive 중지 + cancel + 상태 초기화
  Future<void> forceShutdown() async {
    try {
      print('🛑 STT 강제 종료(forceShutdown)');
      _keepAlive = false;
      _userRequestedStop = true;
      await _speech.cancel();
    } catch (_) {}
    _isListening = false;
    if (!_listeningStateController.isClosed) {
      _listeningStateController.add(false);
    }
    _lastStopAt = DateTime.now();
    print('✅ STT forceShutdown 완료');
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

extension _SttKeepAlive on SpeechToTextService {
  void _scheduleAutoRestart() {
    if (_userRequestedStop) return;
    Future<void>.delayed(const Duration(milliseconds: 450), () async {
      if (_userRequestedStop) return;
      try {
        await _speech.cancel();
        await Future.delayed(const Duration(milliseconds: 220));
        print('🔁 자동 재시작 수행');
        _speech.listen(
          onResult: (result) {
            print(
              '🎤 음성 인식 결과: "${result.recognizedWords}" (final: ${result.finalResult})',
            );
            _currentWords = result.recognizedWords;
            if (result.recognizedWords.isNotEmpty) {
              print('🔄 실시간 텍스트 전송: "${result.recognizedWords}"');
              _textStreamController.add(result.recognizedWords);
            }
            if (result.finalResult) {
              _lastWords = result.recognizedWords;
              print('✅ 최종 결과 저장: "$_lastWords"');
            }
          },
          onSoundLevelChange: (level) => print('🔊 소리 레벨: $level'),
          listenFor: const Duration(minutes: 10),
          pauseFor: const Duration(minutes: 5),
          partialResults: _lastPartialResults,
          localeId: _lastLocaleId,
          listenMode: stt.ListenMode.dictation,
          onDevice: _lastOnDevice,
        );
        if (!_isListening) {
          _isListening = true;
          if (!_listeningStateController.isClosed) {
            _listeningStateController.add(true);
          }
        }
      } catch (e) {
        print('♻️ 자동 재시작 실패: $e');
      }
    });
  }
}
