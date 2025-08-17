import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'speech_to_text_service.dart';
import 'text_to_speech_service.dart';
import 'ai_service.dart';
import '../models/ai_response.dart';
import '../providers/task_provider.dart';

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

  // iOS 마이크 권한 팝업 문제 해결을 위한 메서드
  Future<void> triggerIOSMicrophoneRequest() async {
    if (!Platform.isIOS) return; // iOS에서만 실행

    print('🎤 iOS 마이크 권한 팝업 트리거 시작');

    try {
      // 임시 디렉토리 생성
      final tempDir = await getTemporaryDirectory();
      final dummyPath = '${tempDir.path}/dummy_check.m4a';

      print('📁 임시 파일 경로: $dummyPath');

      // STT 서비스를 사용해서 실제 마이크 접근 시도
      final dummySttService = SpeechToTextService();
      final initialized = await dummySttService.initialize();

      if (initialized) {
        // 실제 마이크 접근 시도 (매우 짧게)
        final success = await dummySttService.startListening();
        if (success) {
          print('✅ iOS 마이크 접근 성공 - 권한 팝업 트리거됨');
          await Future.delayed(const Duration(milliseconds: 300));
          await dummySttService.stopListening();
        } else {
          print('⚠️ iOS 마이크 접근 실패');
        }
      }

      dummySttService.dispose();
    } catch (e) {
      print('❌ iOS 마이크 권한 트리거 중 오류: $e');
      // 오류는 무시하고 계속 진행
    }
  }

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
    // STT 텍스트 스트림 구독 - 중간 결과는 무시하고 최종 결과만 저장
    _sttService.textStream.listen((text) {
      print('🎤 음성 인식 텍스트 수신: "$text"');
      _recognizedText = text;
      _textStreamController.add(text);
      // 중간 결과는 AI 처리하지 않음 - 최종 결과만 처리
    });

    // STT 상태 스트림 구독
    _sttService.listeningStateStream.listen((isListening) {
      _isRecording = isListening;
      _recordingStateController.add(isListening);
      print('📊 녹음 상태 변경: $isListening');

      // 음성 인식이 끝나면 최종 결과로 AI 처리
      if (!isListening && _recognizedText.isNotEmpty) {
        print('🔄 음성 인식 완료 - 최종 텍스트로 AI 처리 시작: "$_recognizedText"');
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

  // AI 처리 (가이드에 따른 개선)
  Future<void> _processWithAI(String text) async {
    try {
      print('=== AI 처리 시작 ===');
      print('📝 처리할 텍스트: "$text"');
      print('📏 텍스트 길이: ${text.length}');

      if (text.isEmpty) {
        print('⚠️ 빈 텍스트는 처리하지 않습니다.');
        return;
      }

      // STT 텍스트 로그 저장 (AI 서버 성공/실패와 관계없이)
      print('🎤 STT 인식 결과 저장: "$text"');
      _recognizedText = text;
      _textStreamController.add(text);

      // AI 서비스에 텍스트 전송
      print('🚀 AIService.processText() 호출 중...');
      final aiResponse = await AIService.processText(text);
      print('📡 AI 서비스 응답 수신 완료');

      if (aiResponse.success) {
        // 가이드에 따른 응답 처리
        print('✅ AI 응답 성공');

        // 1. 텍스트 응답 처리
        if (aiResponse.textResponse?.text != null) {
          _aiResponseText = aiResponse.textResponse!.text;
          _aiResponseStreamController.add(_aiResponseText);
          print('✅ AI 텍스트 응답: "$_aiResponseText"');
        }

        // 2. 액션 처리 (가이드에 따른 UI 업데이트)
        if (aiResponse.action != null) {
          print('🎯 액션 처리 시작: ${aiResponse.action!.type}');
          await _handleAIAction(aiResponse.action!);
        }

        // 3. TTS로 음성 재생
        if (_aiResponseText.isNotEmpty) {
          print('🔊 TTS 음성 재생 시작...');
          await _ttsService.speak(_aiResponseText);
          print('✅ TTS 음성 재생 완료');
        }
      } else {
        print('❌ AI 응답이 실패했습니다.');
        print('  - success: ${aiResponse.success}');
        print('  - textResponse: ${aiResponse.textResponse?.text}');
        print('⚠️ AI 서버 실패했지만 STT 텍스트는 저장됨: "$text"');
      }
    } catch (e) {
      print('❌ AI 처리 중 오류: $e');
      print('🔍 오류 상세: ${e.toString()}');
      print('⚠️ AI 서버 오류 발생했지만 STT 텍스트는 저장됨: "$text"');

      // AI 서버 실패 시에도 기본 응답 설정
      _aiResponseText = '죄송합니다. AI 서버 연결에 문제가 있어 일정을 처리할 수 없습니다.';
      _aiResponseStreamController.add(_aiResponseText);

      // TTS로 오류 메시지 재생
      try {
        print('🔊 오류 메시지 TTS 재생 시작...');
        await _ttsService.speak(_aiResponseText);
        print('✅ 오류 메시지 TTS 재생 완료');
      } catch (ttsError) {
        print('❌ TTS 재생 중 오류: $ttsError');
      }
    }
  }

  // AI 액션 처리 (가이드에 따른 구현)
  Future<void> _handleAIAction(AIAction action) async {
    try {
      print('🎯 === AI 액션 처리 시작 ===');
      print('액션 타입: ${action.type}');
      print('액션 데이터: ${action.data}');

      switch (action.type) {
        case 'schedule_add':
          await _handleScheduleAdd(action);
          break;
        case 'schedule_read':
          await _handleScheduleRead(action);
          break;
        case 'schedule_delete':
          await _handleScheduleDelete(action);
          break;
        case 'schedule_modify':
          await _handleScheduleModify(action);
          break;
        default:
          print('⚠️ 알 수 없는 액션 타입: ${action.type}');
      }

      print('✅ AI 액션 처리 완료');
    } catch (e) {
      print('❌ AI 액션 처리 중 오류: $e');
    }
  }

  // 일정 추가 처리
  Future<void> _handleScheduleAdd(AIAction action) async {
    try {
      print('📅 일정 추가 처리 시작');

      // 액션 데이터에서 일정 정보 추출
      final scheduleData = action.data;
      if (scheduleData != null) {
        print('📋 일정 데이터: $scheduleData');

        // AI 서버 응답에서 일정 정보 파싱
        if (scheduleData is Map<String, dynamic>) {
          final title = scheduleData['title'] ?? '새 일정';
          final datetime =
              scheduleData['datetime'] ?? DateTime.now().toIso8601String();
          final description = scheduleData['description'] ?? '';

          print('📋 파싱된 일정 정보:');
          print('  - 제목: $title');
          print('  - 날짜: $datetime');
          print('  - 설명: $description');

          // DateTime 파싱
          DateTime? parsedDateTime;
          try {
            parsedDateTime = DateTime.parse(datetime);
          } catch (e) {
            print('⚠️ 날짜 파싱 실패, 현재 시간 사용: $e');
            parsedDateTime = DateTime.now();
          }

          // TaskProvider를 통해 실제 일정 추가
          // TODO: TaskProvider 인스턴스에 접근하는 방법 필요
          // 현재는 로그만 출력하고 실제 구현은 나중에 추가
          print('✅ 일정 추가 완료 (TaskProvider 연동 필요)');
          print('  - 제목: $title');
          print('  - 날짜: ${parsedDateTime.toString()}');
          print('  - 설명: $description');
        } else {
          print('⚠️ 일정 데이터 형식이 올바르지 않습니다: $scheduleData');
        }
      } else {
        print('⚠️ 일정 데이터가 없습니다');
      }
    } catch (e) {
      print('❌ 일정 추가 처리 중 오류: $e');
    }
  }

  // 일정 조회 처리
  Future<void> _handleScheduleRead(AIAction action) async {
    try {
      print('📅 일정 조회 처리 시작');

      // TODO: TaskProvider를 통해 실제 일정 조회
      // 예시: final schedules = await TaskProvider.getTasks();
      print('✅ 일정 조회 완료 (실제 데이터 반영 필요)');
    } catch (e) {
      print('❌ 일정 조회 처리 중 오류: $e');
    }
  }

  // 일정 삭제 처리
  Future<void> _handleScheduleDelete(AIAction action) async {
    try {
      print('📅 일정 삭제 처리 시작');

      // TODO: TaskProvider를 통해 실제 일정 삭제
      // 예시: await TaskProvider.deleteTask(taskId);
      print('✅ 일정 삭제 완료 (실제 데이터 반영 필요)');
    } catch (e) {
      print('❌ 일정 삭제 처리 중 오류: $e');
    }
  }

  // 일정 수정 처리
  Future<void> _handleScheduleModify(AIAction action) async {
    try {
      print('📅 일정 수정 처리 시작');

      // TODO: TaskProvider를 통해 실제 일정 수정
      // 예시: await TaskProvider.updateTask(taskId, newData);
      print('✅ 일정 수정 완료 (실제 데이터 반영 필요)');
    } catch (e) {
      print('❌ 일정 수정 처리 중 오류: $e');
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
