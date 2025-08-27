import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'speech_to_text_service.dart';
import 'text_to_speech_service.dart';
import 'ai_service.dart';
import '../models/ai_response.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../main.dart';
import 'action_handler.dart';

class RecordService {
  final SpeechToTextService _sttService = SpeechToTextService();
  final TextToSpeechService _ttsService = TextToSpeechService();
  TaskProvider? _taskProvider; // TaskProvider 참조 추가
  BuildContext? _context; // Context 참조 추가
  bool _ttsSuppressed = false; // 화면/오버레이/녹음 중에는 TTS 금지

  bool _isRecording = false;
  bool _isPlaying = false;
  String _recognizedText = '';
  String _aiResponseText = '';
  String _lastProcessedText = ''; // 중복 처리 방지를 위한 변수
  DateTime? _recordingStartTime;

  // 명확화 요청 관련 변수
  bool _isClarificationMode = false; // 명확화 모드 여부
  String _pendingClarification = ''; // 대기 중인 명확화 요청
  String _originalRequest = ''; // 원본 요청 텍스트
  int _clarificationCount = 0; // 명확화 요청 횟수 (무한 루프 방지)

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

  // 명확화 요청 관련 getter
  bool get isClarificationMode => _isClarificationMode;
  String get pendingClarification => _pendingClarification;
  String get originalRequest => _originalRequest;

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
    // STT 텍스트 스트림 구독 - 텍스트만 저장하고 AI 처리는 하지 않음
    _sttService.textStream.listen((text) {
      print('🎤 음성 인식 텍스트 수신: "$text"');
      _recognizedText = text;
      _textStreamController.add(text);
      // AI 처리는 사용자가 멈춤 버튼을 누를 때만 수행
    });

    // STT 상태 스트림 구독
    _sttService.listeningStateStream.listen((isListening) {
      _isRecording = isListening;
      // 녹음 중에는 TTS를 억제, 녹음이 끝나면 억제 해제
      _ttsSuppressed = isListening;
      _recordingStateController.add(isListening);
      print('📊 녹음 상태 변경: $isListening');
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
      // 실제 오류인 경우에만 사용자에게 알림
      if (!error.contains('타임아웃') &&
          !error.contains('no_speech') &&
          !error.contains('error_audio') &&
          !error.contains('error_network')) {
        print('⚠️ 실제 STT 오류로 판단: $error');
      } else {
        print('ℹ️ 일시적 STT 오류로 판단하여 무시: $error');
      }
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

      // 새 녹음 시작 → TTS 즉시 억제 (AI 응답 도착 레이스 차단)
      _ttsSuppressed = true;

      // STT 시작 전 TTS 재생 중이면 중지하여 오디오 경합 방지
      if (_ttsService.isSpeaking) {
        print('🔇 STT 시작 전 TTS 중지');
        await _ttsService.stop();
      }

      // 이전 텍스트 초기화
      _recognizedText = '';
      _aiResponseText = '';
      _recordingStartTime = DateTime.now();

      // 음성 인식 시작 (권한은 이미 RecordScreen에서 확인됨)
      final success = await _sttService.startListening(
        // localeId를 강제하지 않고 기기 지원 로케일을 서비스 내부에서 선택
        partialResults: true,
        onDevice: false,
        assumePermissionGranted: true,
      );
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
    try {
      print('=== 음성 인식 중지 ===');

      // 바로 이어지는 새 녹음 대비: 현재 TTS 즉시 중단
      if (_ttsService.isSpeaking) {
        print('🔇 중지 시 TTS 중지');
        await _ttsService.stop();
      }

      // STT 서비스 중지
      await _sttService.stopListening();

      // 상태 업데이트
      _isRecording = false;
      _recordingStateController.add(false);

      // 사용자가 멈춤 버튼을 눌렀을 때만 AI 처리 수행
      if (_recognizedText.isNotEmpty) {
        print('🔄 멈춤 버튼 클릭으로 AI 처리 시작: "$_recognizedText"');
        _processWithAI(_recognizedText);
      } else {
        // 텍스트가 없으면 AI 처리 상태 해제
        print('⚠️ 인식된 텍스트가 없어 AI 처리를 건너뜁니다.');
        _aiResponseStreamController.add(''); // 빈 응답으로 AI 처리 상태 해제
      }

      print('✅ 음성 인식 중지 완료');
      return _recognizedText.isNotEmpty ? _recognizedText : null;
    } catch (e) {
      print('❌ 음성 인식 중지 중 오류: $e');
      // 오류 발생 시에도 AI 처리 상태 해제
      _aiResponseStreamController.add('');
      return null;
    }
  }

  // AI 처리 (가이드에 따른 개선)
  Future<void> _processWithAI(String text) async {
    try {
      print('=== AI 처리 시작 ===');
      print('📝 처리할 텍스트: "$text"');
      print('📏 텍스트 길이: ${text.length}');
      print('❓ 명확화 모드: $_isClarificationMode');

      // 텍스트 유효성 검증 최소화 — 서버 판단 우선
      if (text.trim().isEmpty) {
        print('⚠️ 빈 텍스트는 전송하지 않습니다.');
        _aiResponseStreamController.add('음성을 다시 말씀해주세요.');
        return;
      }

      // 클라이언트 사전 차단 제거: 유효성/중복 통과 시에는 모든 텍스트를 서버로 전송

      // 명확화 모드에서 추가 정보가 들어온 경우
      if (_isClarificationMode) {
        print('🔄 명확화 모드에서 추가 정보 처리');
        await processClarificationResponse(text);
        return;
      }

      // 중복 처리 방지 - 같은 텍스트가 연속으로 처리되지 않도록
      if (_lastProcessedText == text) {
        print('⚠️ 중복 텍스트 처리 방지: "$text"');
        return;
      }
      _lastProcessedText = text;

      // AI 처리 상태를 스트림으로 전송
      _aiResponseStreamController.add('AI가 텍스트를 분석하고 있습니다...');

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

        // 1. 처리 결과 처리 먼저 (일정 추가 등)
        if (aiResponse.processingResult != null) {
          print('🎯 처리 결과 처리 시작: ${aiResponse.processingResult!.action}');
          await _handleProcessingResult(aiResponse.processingResult!);
        } else {
          // 구형 응답 구조 처리 (action + text_response)
          print('🔄 구형 응답 구조 감지 - 호환성 처리 시작');
          await _handleLegacyResponse(aiResponse);
        }

        // 2. 텍스트 응답 처리 및 TTS 재생
        String? responseText = aiResponse.responseText;
        if (responseText == null || responseText.isEmpty) {
          // 구형 구조에서 text_response 추출
          responseText = _extractLegacyResponseText(aiResponse);
        }

        if (responseText != null && responseText.isNotEmpty) {
          _aiResponseText = responseText;
          _aiResponseStreamController.add(_aiResponseText);
          print('✅ AI 텍스트 응답: "$_aiResponseText"');

          // 3. TTS로 음성 재생 (한 번만) — 화면/오버레이 닫힘 플래그 시 무시
          print('🔊 TTS 음성 재생 시작...');
          await _speakIfAllowed(_aiResponseText);
        } else {
          print('⚠️ AI 응답 텍스트가 없습니다');
        }
      } else {
        print('❌ AI 응답이 실패했습니다.');
        print('  - success: ${aiResponse.success}');
        print('  - responseText: ${aiResponse.responseText}');
        print('⚠️ AI 서버 실패했지만 STT 텍스트는 저장됨: "$text"');

        // 서버 지시에 따른 에러 처리만 수행
        await _handleErrorResponse(aiResponse);
      }

      // 신규 가이드: action 기반 UI 지시사항 처리 (구형/신형 공통)
      try {
        final action = aiResponse.action;
        if (action != null) {
          await _applyUiInstructions(action.uiInstructions);
        }
      } catch (e) {
        print('UI 지시사항 적용 중 오류: $e');
      }
    } catch (e) {
      print('❌ AI 처리 중 오류: $e');
      print('🔍 오류 상세: ${e.toString()}');
      print('⚠️ AI 서버 오류 발생했지만 STT 텍스트는 저장됨: "$text"');

      // AI 서버 실패 시에도 기본 응답 설정
      _aiResponseText = '죄송합니다. AI 서버 연결에 문제가 있어 일정을 처리할 수 없습니다.';
      _aiResponseStreamController.add(_aiResponseText);

      // TTS로 오류 메시지 재생
      print('🔊 오류 메시지 TTS 재생 시작...');
      await _speakIfAllowed(_aiResponseText);
    }

    // AI 처리 완료 후 상태 해제를 위한 빈 응답 전송
    print('✅ AI 처리 완료 - 상태 해제');
    _aiResponseStreamController.add('');
  }

  // 처리 결과 처리 (가이드에 따른 구현)
  Future<void> _handleProcessingResult(
    ProcessingResult processingResult,
  ) async {
    try {
      print('🎯 === 처리 결과 처리 시작 ===');
      print('처리 액션: ${processingResult.action}');
      print('처리 결과: ${processingResult.result}');

      switch (processingResult.action) {
        case 'schedule_add':
          await _handleScheduleAddFromResult(processingResult.result);
          break;
        case 'schedule_read':
          await _handleScheduleReadFromResult(processingResult.result);
          break;
        case 'schedule_delete':
          await _handleScheduleDeleteFromResult(processingResult.result);
          break;
        case 'schedule_modify':
          await _handleScheduleModifyFromResult(processingResult.result);
          break;
        default:
          print('⚠️ 알 수 없는 처리 액션: ${processingResult.action}');
      }

      print('✅ 처리 결과 처리 완료');
    } catch (e) {
      print('❌ 처리 결과 처리 중 오류: $e');
    }
  }

  // AI 액션 처리 (가이드에 따른 구현)
  Future<void> _handleAIAction(AIAction action) async {
    try {
      print('🎯 === AI 액션 처리 시작 ===');
      print('액션 타입: ${action.type}');
      print('액션 데이터: ${action.data}');
      print('중요도(is_important): ${action.isImportant}');

      switch (action.type) {
        case 'schedule_add':
          await _handleScheduleAdd(action);
          break;
        case 'schedule_read':
          await _handleScheduleRead(action);
          break;
        case 'schedule_list':
          await _handleScheduleRead(action);
          break;
        case 'schedule_delete':
          await _handleScheduleDelete(action);
          break;
        case 'schedule_delete_visual':
          await _handleScheduleDeleteVisual(action);
          break;
        case 'schedule_read_visual':
          await _handleScheduleReadVisual(action);
          break;
        case 'schedule_modify':
          await _handleScheduleModify(action);
          break;
        case 'clarification_required':
          await _handleClarificationRequired(action);
          break;
        default:
          print('⚠️ 알 수 없는 액션 타입: ${action.type}');
      }

      print('✅ AI 액션 처리 완료');
    } catch (e) {
      print('❌ AI 액션 처리 중 오류: $e');
    }
  }

  // UI 지시사항 적용 (가이드 v3.1.0)
  Future<void> _applyUiInstructions(UIInstructions ui) async {
    try {
      print('🧭 UI 지시사항 적용 시작');
      final taskProvider = _getTaskProvider();

      if (ui.refreshData == true && taskProvider != null) {
        await taskProvider.loadTasks();
        print('🔄 데이터 새로고침 완료');
      }

      if (ui.notification != null) {
        final n = ui.notification!;
        print('🔔 알림: ${n.type} - ${n.title}: ${n.message}');
      }

      // 화면 이동(screen) 등은 현재 라우팅 구조 상 생략/로그만
      if (ui.screen != null) {
        print('🧭 화면 이동 요청: ${ui.screen}');
      }
    } catch (e) {
      print('UI 지시사항 적용 중 오류: $e');
    }
  }

  // 일정 추가 처리 (ProcessingResult용)
  Future<void> _handleScheduleAddFromResult(Map<String, dynamic> result) async {
    try {
      print('📅 일정 추가 처리 시작 (ProcessingResult)');

      // result에서 schedule_data 추출
      final scheduleData = result['schedule_data'];
      if (scheduleData != null && scheduleData is Map<String, dynamic>) {
        await _processScheduleData(scheduleData);
      } else {
        print('⚠️ schedule_data가 없거나 올바르지 않습니다: $scheduleData');
      }
    } catch (e) {
      print('❌ 일정 추가 처리 중 오류: $e');
    }
  }

  // 일정 조회 처리 (ProcessingResult용)
  Future<void> _handleScheduleReadFromResult(
    Map<String, dynamic> result,
  ) async {
    try {
      print('📅 일정 조회 처리 시작 (ProcessingResult)');
      // 일정 조회 로직 구현
      print('📋 조회 결과: $result');
    } catch (e) {
      print('❌ 일정 조회 처리 중 오류: $e');
    }
  }

  // 일정 삭제 처리 (ProcessingResult용)
  Future<void> _handleScheduleDeleteFromResult(
    Map<String, dynamic> result,
  ) async {
    try {
      print('📅 일정 삭제 처리 시작 (ProcessingResult)');
      // 일정 삭제 로직 구현
      print('📋 삭제 결과: $result');
    } catch (e) {
      print('❌ 일정 삭제 처리 중 오류: $e');
    }
  }

  // 일정 수정 처리 (ProcessingResult용)
  Future<void> _handleScheduleModifyFromResult(
    Map<String, dynamic> result,
  ) async {
    try {
      print('📅 일정 수정 처리 시작 (ProcessingResult)');
      // 일정 수정 로직 구현
      print('📋 수정 결과: $result');
    } catch (e) {
      print('❌ 일정 수정 처리 중 오류: $e');
    }
  }

  // 일정 데이터 처리 (공통 로직)
  Future<void> _processScheduleData(Map<String, dynamic> scheduleData) async {
    try {
      print('📋 일정 데이터: $scheduleData');
      print('📋 일정 데이터 타입: ${scheduleData.runtimeType}');
      print('📋 일정 데이터 키들: ${scheduleData.keys.toList()}');

      // AI 서버 응답에서 일정 정보 파싱
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

      // 시간 검증은 서버에서 수행 — 클라이언트는 서버 지시에만 따름

      // 서버에서 받은 카테고리와 중요도 정보 확인
      print('🔍 원본 scheduleData: $scheduleData');
      print('🔍 scheduleData 타입: ${scheduleData.runtimeType}');

      // 서버에서 받은 카테고리 그대로 사용
      String category = scheduleData['category'] ?? '일반';
      final isImportant =
          scheduleData['is_important'] == true ||
          scheduleData['priority'] == 'high' ||
          category == '건강';

      // 반복 일정 정보 처리
      bool isRecurring = scheduleData['is_recurring'] ?? false;
      RecurrenceInfo? recurrence;

      if (isRecurring && scheduleData['recurrence'] != null) {
        try {
          final recurrenceData =
              scheduleData['recurrence'] as Map<String, dynamic>;
          final times =
              (recurrenceData['times'] as List?)
                  ?.map((time) => RecurrenceTime.fromJson(time))
                  .toList() ??
              [];

          recurrence = RecurrenceInfo(
            type: recurrenceData['type'] ?? 'daily',
            times: times,
            endDate: recurrenceData['end_date'] != null
                ? DateTime.parse(recurrenceData['end_date'])
                : null,
            daysOfWeek: recurrenceData['days_of_week'] != null
                ? List<int>.from(recurrenceData['days_of_week'])
                : null,
          );

          print('📋 반복 일정 정보:');
          print('  - 반복 타입: ${recurrence.type}');
          print(
            '  - 반복 시간: ${recurrence.times.map((t) => '${t.label} ${t.time}').join(', ')}',
          );
          print('  - 종료 날짜: ${recurrence.endDate}');
          print('  - 요일: ${recurrence.daysOfWeek}');
        } catch (e) {
          print('⚠️ 반복 일정 정보 파싱 실패: $e');
          isRecurring = false;
          recurrence = null;
        }
      }

      print('📋 서버에서 받은 정보:');
      print('  - 원본 category 값: ${scheduleData['category']}');
      print('  - category 타입: ${scheduleData['category']?.runtimeType}');
      print('  - 최종 카테고리: $category');
      print('  - is_important: ${scheduleData['is_important']}');
      print('  - priority: ${scheduleData['priority']}');
      print('  - 최종 중요도: $isImportant');
      print('  - 반복 일정: $isRecurring');

      // Task 객체 생성
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        date: parsedDateTime,
        isCompleted: false,
        isImportant: isImportant,
        category: category,
        isRecurring: isRecurring,
        recurrence: recurrence,
      );

      print('📋 생성된 Task 객체:');
      print('  - ID: ${task.id}');
      print('  - 제목: ${task.title}');
      print('  - 날짜: ${task.date}');
      print('  - 완료: ${task.isCompleted}');
      print('  - 중요: ${task.isImportant}');
      print('  - 카테고리: ${task.category}');

      // TaskProvider를 통해 일정 추가
      final taskProvider = _getTaskProvider();
      if (taskProvider != null) {
        taskProvider.addTask(task);
        print('✅ TaskProvider를 통해 일정 추가 완료');
      } else {
        print('❌ TaskProvider를 찾을 수 없습니다');
      }
    } catch (e) {
      print('❌ 일정 데이터 처리 중 오류: $e');
    }
  }

  // 일정 추가 처리
  Future<void> _handleScheduleAdd(AIAction action) async {
    try {
      print('📅 일정 추가 처리 시작');

      // 액션 데이터에서 일정 정보 추출
      final scheduleData = action.data;
      print('📋 일정 데이터: $scheduleData');
      print('📋 일정 데이터 타입: ${scheduleData.runtimeType}');
      print('📋 일정 데이터 키들: ${scheduleData.keys.toList()}');

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

        // 서버에서 받은 카테고리와 중요도 정보 확인 (시간 검증은 서버에 위임)
        print('🔍 원본 scheduleData: $scheduleData');
        print('🔍 scheduleData 타입: ${scheduleData.runtimeType}');

        // 서버에서 받은 카테고리 그대로 사용
        String category = scheduleData['category'] ?? '일반';
        final isImportant =
            scheduleData['is_important'] == true ||
            scheduleData['priority'] == 'high' ||
            category == '건강';

        // 반복 일정 정보 처리 (액션 경로도 지원)
        bool isRecurring =
            scheduleData['is_recurring'] == true ||
            scheduleData['recurrence'] != null;
        RecurrenceInfo? recurrence;
        if (scheduleData['recurrence'] != null) {
          try {
            final recurrenceData = Map<String, dynamic>.from(
              scheduleData['recurrence'],
            );

            final times =
                (recurrenceData['times'] as List?)
                    ?.map((time) => RecurrenceTime.fromJson(time))
                    .toList() ??
                [];

            DateTime? endDate;
            if (recurrenceData['end_date'] != null) {
              final ed = recurrenceData['end_date'];
              if (ed is String && ed.isNotEmpty) {
                try {
                  endDate = DateTime.parse(ed);
                } catch (_) {}
              }
            }

            List<int>? daysOfWeek;
            if (recurrenceData['days_of_week'] != null) {
              final raw = recurrenceData['days_of_week'] as List;
              daysOfWeek = raw.map((e) {
                if (e is int) return e;
                return int.tryParse(e.toString()) ?? 0;
              }).toList();
            }

            recurrence = RecurrenceInfo(
              type: (recurrenceData['type'] ?? 'daily').toString(),
              times: times,
              endDate: endDate,
              daysOfWeek: daysOfWeek,
            );
            print(
              '📋(action) 반복 일정 정보: type=${recurrence.type}, times=${times.map((t) => t.time).join(',')}, end=${recurrence.endDate}, days=${recurrence.daysOfWeek}',
            );
          } catch (e) {
            print('⚠️(action) 반복 일정 파싱 실패: $e');
            // 파싱 실패해도 단일 일정으로 진행
            isRecurring = false;
            recurrence = null;
          }
        }

        print('📋 서버에서 받은 정보:');
        print('  - 원본 category 값: ${scheduleData['category']}');
        print('  - category 타입: ${scheduleData['category']?.runtimeType}');
        print('  - 최종 카테고리: $category');
        print('  - is_important: ${scheduleData['is_important']}');
        print('  - priority: ${scheduleData['priority']}');
        print('  - 최종 중요도: $isImportant');
        print('  - 반복 일정: $isRecurring');

        // Task 객체 생성
        final task = Task(
          id:
              scheduleData['id'] ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          date: parsedDateTime,
          isCompleted: false,
          isImportant: isImportant,
          category: category, // 서버에서 받은 카테고리 사용
          isRecurring: isRecurring,
          recurrence: recurrence,
        );

        print('📝 생성된 Task 객체:');
        print('  - ID: ${task.id}');
        print('  - 제목: ${task.title}');
        print('  - 날짜: ${task.date.toString()}');
        print('  - 카테고리: ${task.category}');
        print('  - 중요도: ${task.isImportant}');

        // TaskProvider를 통해 실제 일정 추가
        try {
          // Provider를 통해 TaskProvider에 접근
          final taskProvider = _getTaskProvider();
          if (taskProvider != null) {
            await taskProvider.addTask(task);
            print('✅ TaskProvider를 통해 일정 추가 완료 (알람은 TaskProvider에서 자동 설정됨)');
            print('✅ 일정 시간 처리 완료: $parsedDateTime');
          } else {
            print('❌ TaskProvider에 접근할 수 없습니다');
          }
        } catch (e) {
          print('❌ TaskProvider 일정 추가 중 오류: $e');
        }
      } else {
        print('⚠️ 일정 데이터 형식이 올바르지 않습니다: $scheduleData');
      }
    } catch (e) {
      print('❌ 일정 추가 처리 중 오류: $e');
    }
  }

  // TaskProvider 설정 메서드
  void setTaskProvider(TaskProvider taskProvider) {
    _taskProvider = taskProvider;
    print('✅ TaskProvider 설정 완료');
  }

  // TaskProvider 인스턴스 가져오기
  TaskProvider? _getTaskProvider() {
    if (_taskProvider != null) return _taskProvider;
    try {
      if (navigatorKey.currentContext != null) {
        final tp = Provider.of<TaskProvider>(
          navigatorKey.currentContext!,
          listen: false,
        );
        _taskProvider = tp;
        print('✅ RecordService: navigatorKey로 TaskProvider 획득');
        return tp;
      }
    } catch (e) {
      print('⚠️ RecordService: TaskProvider 자동 획득 실패: $e');
    }
    return null;
  }

  // Context 설정 메서드
  void setContext(BuildContext context) {
    _context = context;
    print('✅ Context 설정 완료');
  }

  // Context 가져오기 메서드
  BuildContext? _getContext() {
    return _context;
  }

  // 명확화 요청 처리
  Future<void> _handleClarificationRequired(AIAction action) async {
    try {
      print('❓ === 명확화 요청 처리 시작 ===');

      final clarificationData = action.data;
      if (clarificationData is Map<String, dynamic>) {
        // 명확화 요청 정보 추출
        final clarificationText =
            clarificationData['clarification_text'] ?? '추가 정보가 필요합니다.';
        final originalRequest = clarificationData['original_request'] ?? '';
        final missingFields = clarificationData['missing_fields'] ?? <String>[];

        print('❓ 명확화 요청 정보:');
        print('  - 명확화 텍스트: $clarificationText');
        print('  - 원본 요청: $originalRequest');
        print('  - 부족한 필드: $missingFields');

        // 명확화 모드 활성화
        _isClarificationMode = true;
        _pendingClarification = clarificationText;
        _originalRequest = originalRequest;
        _clarificationCount++;

        print('✅ 명확화 모드 활성화됨 (횟수: $_clarificationCount)');

        // 명확화 요청을 AI 응답으로 설정
        _aiResponseText = clarificationText;
        _aiResponseStreamController.add(_aiResponseText);

        // TTS로 명확화 요청 재생
        print('🔊 명확화 요청 TTS 재생 시작...');
        await _speakIfAllowed(clarificationText);
      } else {
        print('⚠️ 명확화 요청 데이터가 올바르지 않습니다: $clarificationData');
      }
    } catch (e) {
      print('❌ 명확화 요청 처리 중 오류: $e');
    }
  }

  // 명확화 모드 종료
  void exitClarificationMode() {
    print('🚪 명확화 모드 종료');
    _isClarificationMode = false;
    _pendingClarification = '';
    _originalRequest = '';
    _clarificationCount = 0;
  }

  // 명확화 모드에서 추가 정보 처리
  Future<void> processClarificationResponse(String additionalInfo) async {
    try {
      print('🔄 === 명확화 응답 처리 시작 ===');
      print('추가 정보: $additionalInfo');
      print('원본 요청: $_originalRequest');

      // 원본 요청과 추가 정보를 합쳐서 새로운 요청 생성
      final combinedRequest = '$_originalRequest $additionalInfo';
      print('합쳐진 요청: $combinedRequest');

      // 명확화 모드 종료
      exitClarificationMode();

      // 합쳐진 요청으로 AI 처리 재시도
      print('🔄 합쳐진 요청으로 AI 처리 재시도...');
      await _processWithAI(combinedRequest);
    } catch (e) {
      print('❌ 명확화 응답 처리 중 오류: $e');
    }
  }

  // 일정 조회 처리
  Future<void> _handleScheduleRead(AIAction action) async {
    try {
      print('📅 일정 조회 처리 시작');

      final taskProvider = _getTaskProvider();
      if (taskProvider != null) {
        // 신규 가이드에선 서버에서 리스트를 내려줄 수 있음
        final data = action.data;
        if (data.containsKey('schedules')) {
          final schedules = data['schedules'] as List<dynamic>;
          print('📋 서버 제공 일정 수: ${schedules.length}');
          for (final s in schedules) {
            print('  - ${s['title']} (${s['datetime']})');
          }
        } else {
          final tasks = taskProvider.tasks;
          print('📋 로컬 저장 일정 수: ${tasks.length}');
          for (final task in tasks) {
            print('  - ${task.title} (${task.date.toString()})');
          }
        }

        print('✅ 일정 조회 완료');
      } else {
        print('❌ TaskProvider에 접근할 수 없습니다');
      }

      // ActionHandler 호출 추가
      print('🔍 ActionHandler 호출 시도');
      try {
        final context = _getContext();
        if (context != null) {
          print('🔍 ActionHandler.handleAction 호출');
          ActionHandler.handleAction(action, context);
          print('✅ ActionHandler.handleAction 호출 완료');
        } else {
          print('❌ Context를 가져올 수 없습니다');
        }
      } catch (e) {
        print('❌ ActionHandler 호출 중 오류: $e');
      }
    } catch (e) {
      print('❌ 일정 조회 처리 중 오류: $e');
    }
  }

  // 시각적 일정 삭제 처리
  Future<void> _handleScheduleDeleteVisual(AIAction action) async {
    try {
      print('📅 시각적 일정 삭제 처리 시작');

      // 전역 navigatorKey를 사용하여 네비게이션 처리
      if (navigatorKey.currentContext != null) {
        // ActionHandler를 통해 시각적 삭제 화면으로 이동
        ActionHandler.handleScheduleDeleteVisual(
          action,
          navigatorKey.currentContext!,
        );
        print('✅ 시각적 삭제 화면으로 이동 완료');
      } else {
        print('❌ 전역 Context를 가져올 수 없습니다');
        // 대안: UI 지시사항을 통해 화면 이동 시도
        print('🔄 UI 지시사항을 통한 화면 이동 시도');
        _tryNavigateToDeleteScreen(action);
      }
    } catch (e) {
      print('❌ 시각적 일정 삭제 처리 중 오류: $e');
    }
  }

  // UI 지시사항을 통한 삭제 화면 이동 시도
  void _tryNavigateToDeleteScreen(AIAction action) {
    try {
      final taskData = action.data;
      final searchCriteria =
          taskData['search_criteria'] as Map<String, dynamic>? ?? {};
      final foundSchedules =
          taskData['found_schedules'] as List<dynamic>? ?? [];

      // Task 객체로 변환
      final tasks = foundSchedules.map((schedule) {
        return Task.fromJson(schedule);
      }).toList();

      // 검색 기준 텍스트 생성
      final title = searchCriteria['title'] as String? ?? '';
      final date = searchCriteria['date'] as String? ?? '';
      final searchText = title.isNotEmpty ? title : date;

      // 전역 navigatorKey를 사용하여 화면 이동
      if (navigatorKey.currentContext != null) {
        Navigator.pushNamed(
          navigatorKey.currentContext!,
          '/delete-schedule',
          arguments: {'schedules': tasks, 'searchCriteria': searchText},
        );
        print('✅ 삭제 화면으로 이동 완료 (UI 지시사항 경로)');
      } else {
        print('❌ 전역 Context를 가져올 수 없어 화면 이동 실패');
      }
    } catch (e) {
      print('❌ UI 지시사항을 통한 화면 이동 실패: $e');
    }
  }

  // 일정 삭제 처리
  Future<void> _handleScheduleDelete(AIAction action) async {
    try {
      print('📅 일정 삭제 처리 시작');

      final scheduleData = action.data;
      if (scheduleData is Map<String, dynamic>) {
        final taskId = scheduleData['id'];
        if (taskId != null) {
          final taskProvider = _getTaskProvider();
          if (taskProvider != null) {
            await taskProvider.deleteTask(taskId);
            print('✅ 일정 삭제 완료: $taskId (알람은 TaskProvider에서 자동 취소됨)');
          } else {
            print('❌ TaskProvider에 접근할 수 없습니다');
          }
        } else {
          print('⚠️ 삭제할 일정 ID가 없습니다');
        }
      } else {
        print('⚠️ 일정 삭제 데이터가 없습니다');
      }
    } catch (e) {
      print('❌ 일정 삭제 처리 중 오류: $e');
    }
  }

  // 시각적 일정 조회 처리
  Future<void> _handleScheduleReadVisual(AIAction action) async {
    try {
      print('📅 시각적 일정 조회 처리 시작');

      final taskData = action.data;
      final searchCriteria =
          taskData['search_criteria'] as Map<String, dynamic>? ?? {};
      final foundSchedules =
          taskData['found_schedules'] as List<dynamic>? ?? [];

      // Task 객체로 변환
      final tasks = foundSchedules.map((schedule) {
        return Task.fromJson(schedule);
      }).toList();

      // 검색 기준 텍스트 생성
      final title = searchCriteria['title'] as String? ?? '';
      final date = searchCriteria['date'] as String? ?? '';
      final searchText = title.isNotEmpty
          ? title
          : (date.isNotEmpty ? date : '일정');

      // 전역 navigatorKey를 사용하여 화면 이동
      if (navigatorKey.currentContext != null) {
        Navigator.pushNamed(
          navigatorKey.currentContext!,
          '/schedule-list',
          arguments: {'schedules': tasks, 'searchCriteria': searchText},
        );
        print('✅ 일정 조회 화면으로 이동 완료');
      } else {
        print('❌ 전역 Context를 가져올 수 없어 화면 이동 실패');
      }
    } catch (e) {
      print('❌ 시각적 일정 조회 처리 오류: $e');
    }
  }

  // 일정 수정 처리
  Future<void> _handleScheduleModify(AIAction action) async {
    try {
      print('📅 일정 수정 처리 시작');

      final scheduleData = action.data;
      if (scheduleData is Map<String, dynamic>) {
        final taskId = scheduleData['id'];
        final title = scheduleData['title'];
        final datetime = scheduleData['datetime'];

        if (taskId != null) {
          final taskProvider = _getTaskProvider();
          if (taskProvider != null) {
            // 기존 일정 찾기
            final existingTask = taskProvider.tasks.firstWhere(
              (task) => task.id == taskId,
              orElse: () => throw Exception('일정을 찾을 수 없습니다: $taskId'),
            );

            // 수정된 일정 생성
            final updatedTask = existingTask.copyWith(
              title: title ?? existingTask.title,
              date: datetime != null
                  ? DateTime.parse(datetime)
                  : existingTask.date,
            );

            await taskProvider.updateTask(updatedTask);
            print('✅ 일정 수정 완료: $taskId (알람은 TaskProvider에서 자동 재설정됨)');
          } else {
            print('❌ TaskProvider에 접근할 수 없습니다');
          }
        } else {
          print('⚠️ 수정할 일정 ID가 없습니다');
        }
      } else {
        print('⚠️ 일정 수정 데이터가 없습니다');
      }
    } catch (e) {
      print('❌ 일정 수정 처리 중 오류: $e');
    }
  }

  // 음성 인식 취소 (기존 메서드명 유지)
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      print('=== 음성 인식 취소 ===');
      // 진행 중인 TTS가 있으면 즉시 중지 (다음 녹음을 위해 경합 방지)
      if (_ttsService.isSpeaking) {
        print('🔇 취소 시 TTS 중지');
        await _ttsService.stop();
      }
      // 오버레이/화면 종료 흐름에서는 이후 TTS를 금지
      _ttsSuppressed = true;
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

  // 자동 재녹음은 서버의 명확화/선택 지시에만 따름
  bool _shouldAutoRestartForError(String errorType) {
    return false;
  }

  // 자동 녹음 재시작 메서드
  Future<void> _autoRestartRecording() async {
    try {
      print('🔄 === 자동 녹음 재시작 시작 ===');

      // 현재 녹음 상태 확인
      if (_isRecording) {
        print('⚠️ 이미 녹음 중이므로 재시작하지 않습니다.');
        return;
      }

      // 이전 텍스트 초기화
      _recognizedText = '';
      _lastProcessedText = '';

      // 녹음 시작
      final success = await startRecording();
      if (success) {
        print('✅ 자동 녹음 재시작 성공');
        // 녹음 상태를 스트림으로 전송
        _recordingStateController.add(true);
      } else {
        print('❌ 자동 녹음 재시작 실패');
      }
    } catch (e) {
      print('❌ 자동 녹음 재시작 중 오류: $e');
    }
  }

  // 불완전 요청 클라이언트 감지는 제거됨: 서버 응답으로 처리

  // 텍스트 유효성 검증 메서드 (더 관대하게 수정)
  bool _isValidTextForAI(String text) {
    // 1. 빈 텍스트 체크
    if (text.isEmpty) {
      print('🔍 텍스트 검증 실패: 빈 텍스트');
      return false;
    }

    // 2. 공백만 있는 텍스트 체크
    if (text.trim().isEmpty) {
      print('🔍 텍스트 검증 실패: 공백만 있는 텍스트');
      return false;
    }

    // 3. 너무 짧은 텍스트 체크 (1글자 미만으로 완화)
    if (text.trim().isEmpty) {
      print('🔍 텍스트 검증 실패: 너무 짧은 텍스트 (${text.trim().length}글자)');
      return false;
    }

    // 4. 의미없는 텍스트 패턴 체크 (더 엄격한 패턴만 체크)
    final meaninglessPatterns = [
      '음음음음음',
      '아아아아아',
      '어어어어어',
      '으으으으으',
      '그그그그그',
      '저저저저저',
      '그게그게그게그게그게',
      '저게저게저게저게저게',
      '뭐뭐뭐뭐뭐',
      '어떻게어떻게어떻게어떻게어떻게',
      '그래서그래서그래서그래서그래서',
    ];

    final trimmedText = text.trim();
    for (final pattern in meaninglessPatterns) {
      if (trimmedText == pattern) {
        print('🔍 텍스트 검증 실패: 의미없는 패턴 "$pattern"');
        return false;
      }
    }

    // 5. 숫자나 특수문자만 있는 텍스트 체크 (완화)
    final hasMeaningfulContent = RegExp(r'[가-힣a-zA-Z]').hasMatch(trimmedText);
    if (!hasMeaningfulContent && trimmedText.length < 3) {
      print('🔍 텍스트 검증 실패: 의미있는 텍스트가 없음 (숫자/특수문자만)');
      return false;
    }

    // 6. 일정 관련 키워드 체크는 제거 (모든 텍스트를 AI로 전송)
    print('✅ 텍스트 검증 통과: "$trimmedText" (AI로 전송)');
    return true;
  }

  // AI_03 구형 에러 응답 처리
  Future<void> _handleErrorResponse(AIResponse aiResponse) async {
    try {
      print('🚨 === 에러 응답 처리 시작 ===');

      // 에러 타입과 메시지 추출 시도
      String errorType = 'general';
      String errorMessage = '음성 인식 결과를 처리할 수 없습니다.';

      // AI_03 구형 에러 구조 처리 (action + text_response)
      if (aiResponse.action != null && aiResponse.action!.type == 'error') {
        print('🔍 AI_03 구형 에러 구조 감지');

        final actionData = aiResponse.action!.data;
        if (actionData.containsKey('error_type')) {
          errorType = actionData['error_type'] ?? 'general';
        }
        if (actionData.containsKey('message')) {
          errorMessage = actionData['message'] ?? errorMessage;
        }

        print('🔍 action.data에서 추출:');
        print('  - error_type: $errorType');
        print('  - message: $errorMessage');
      }

      // text_response에서 메시지 추출 (AI_03 구조)
      if (aiResponse.textResponse != null &&
          aiResponse.textResponse!.text.isNotEmpty) {
        errorMessage = aiResponse.textResponse!.text;
        print('🔍 text_response에서 추출: $errorMessage');
      }

      // 신형 구조도 확인 (APP_INTEGRATION_GUIDE 참조)
      if (aiResponse.processingResult != null) {
        final result = aiResponse.processingResult!.result;
        if (result.containsKey('error_type')) {
          errorType = result['error_type'] ?? 'general';
        }
        if (result.containsKey('message')) {
          errorMessage = result['message'] ?? errorMessage;
        }
      }

      // responseText가 있으면 그것을 우선 사용
      if (aiResponse.responseText != null &&
          aiResponse.responseText!.isNotEmpty) {
        errorMessage = aiResponse.responseText!;
      }

      print('🚨 최종 에러 타입: $errorType');
      print('🚨 최종 에러 메시지: $errorMessage');

      // 에러 타입별 처리
      await _processErrorByType(errorType, errorMessage);
    } catch (e) {
      print('❌ 에러 응답 처리 중 오류: $e');

      // 기본 에러 메시지로 폴백
      _aiResponseText = '죄송합니다. 요청을 처리하는 중에 문제가 발생했습니다.';
      _aiResponseStreamController.add(_aiResponseText);

      try {
        await _ttsService.speak(_aiResponseText);
      } catch (ttsError) {
        print('❌ 기본 에러 TTS 재생 실패: $ttsError');
      }
    }
  }

  // 에러 타입별 처리 (APP_INTEGRATION_GUIDE 기준)
  Future<void> _processErrorByType(
    String errorType,
    String errorMessage,
  ) async {
    print('🔍 에러 타입별 처리: $errorType');

    String userFriendlyMessage = errorMessage;
    String logMessage = errorMessage;

    switch (errorType) {
      // 1. 입력 검증 에러
      case 'validation_error':
      case 'invalid_request':
      case 'missing_content_type':
      case 'missing_required_data':
        logMessage = '입력 검증 오류: $errorMessage';
        userFriendlyMessage = errorMessage;
        break;

      // 2. 일정 정보 검증 에러
      case 'schedule_validation_error':
      case 'missing_schedule_title':
        logMessage = '일정 제목 누락: $errorMessage';
        userFriendlyMessage = errorMessage.isNotEmpty
            ? errorMessage
            : '구체적인 일정 내용을 말씀해주세요. 예: 병원 진료, 친구 만남 등';
        break;

      case 'generic_schedule_title':
        logMessage = '비구체적 일정 제목: $errorMessage';
        userFriendlyMessage = errorMessage.isNotEmpty
            ? errorMessage
            : '좀 더 구체적인 일정 내용을 말씀해주세요.';
        break;

      case 'short_schedule_title':
        logMessage = '일정 제목이 너무 짧음: $errorMessage';
        userFriendlyMessage = errorMessage.isNotEmpty
            ? errorMessage
            : '일정 내용을 좀 더 자세히 말씀해주세요.';
        break;

      case 'missing_schedule_date':
        logMessage = '일정 날짜 누락: $errorMessage';
        userFriendlyMessage = errorMessage.isNotEmpty
            ? errorMessage
            : '언제 일정이 있는지 날짜를 말씀해주세요.';
        break;

      case 'missing_schedule_time':
        logMessage = '일정 시간 누락: $errorMessage';
        userFriendlyMessage = errorMessage.isNotEmpty
            ? errorMessage
            : '몇 시에 일정이 있는지 시간을 말씀해주세요.';
        break;

      case 'invalid_date_format':
      case 'invalid_time_format':
        logMessage = '잘못된 날짜/시간 형식: $errorMessage';
        userFriendlyMessage = errorMessage.isNotEmpty
            ? errorMessage
            : '날짜와 시간을 다시 말씀해주세요.';
        break;

      // 3. 데이터베이스/저장 에러
      case 'database_error':
      case 'schedule_save_error':
      case 'data_parsing_error':
        logMessage = '데이터 저장 오류: $errorMessage';
        userFriendlyMessage = '일정을 저장하는 중에 문제가 발생했습니다. 다시 시도해주세요.';
        break;

      // 4. 일정 조회/삭제 에러
      case 'schedule_not_found':
        logMessage = '일정을 찾을 수 없음: $errorMessage';
        userFriendlyMessage = errorMessage.isNotEmpty
            ? errorMessage
            : '해당 일정을 찾을 수 없습니다.';
        break;

      case 'schedule_delete_error':
        logMessage = '일정 삭제 실패: $errorMessage';
        userFriendlyMessage = '일정을 삭제하는 중에 문제가 발생했습니다.';
        break;

      case 'insufficient_delete_info':
        logMessage = '삭제 정보 부족: $errorMessage';
        userFriendlyMessage = errorMessage.isNotEmpty
            ? errorMessage
            : '어떤 일정을 삭제할지 더 구체적으로 말씀해주세요.';
        break;

      // 5. AI 처리 에러
      case 'ai_processing_error':
      case 'llm_error':
      case 'intent_analysis_error':
      case 'response_generation_error':
        logMessage = 'AI 처리 오류: $errorMessage';
        userFriendlyMessage = '요청을 분석하는 중에 문제가 발생했습니다. 다시 말씀해주세요.';
        break;

      // 6. 서버 상태 에러
      case 'health_check':
      case 'server_error':
        logMessage = '서버 오류: $errorMessage';
        userFriendlyMessage = '서버에 일시적인 문제가 있습니다. 잠시 후 다시 시도해주세요.';
        break;

      // 7. HTTP 에러
      case 'bad_request':
        logMessage = '잘못된 요청: $errorMessage';
        userFriendlyMessage = '요청에 문제가 있습니다. 다시 말씀해주세요.';
        break;

      case 'not_found':
        logMessage = '리소스 없음: $errorMessage';
        userFriendlyMessage = '요청한 정보를 찾을 수 없습니다.';
        break;

      case 'internal_error':
        logMessage = '서버 내부 오류: $errorMessage';
        userFriendlyMessage = '서버에 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
        break;

      // 8. 시스템 예외
      case 'system_error':
      case 'unexpected_error':
      default:
        logMessage = '일반 오류: $errorMessage';
        userFriendlyMessage = errorMessage.isNotEmpty
            ? errorMessage
            : '요청을 처리하는 중에 문제가 발생했습니다. 다시 시도해주세요.';
        break;
    }

    print('📝 로그 메시지: $logMessage');
    print('🎤 사용자 메시지: $userFriendlyMessage');

    // AI 응답으로 설정
    _aiResponseText = userFriendlyMessage;
    _aiResponseStreamController.add(_aiResponseText);

    // TTS로 에러 메시지 재생
    print('🔊 에러 메시지 TTS 재생 시작...');
    await _speakIfAllowed(userFriendlyMessage);
  }

  // 구형 응답 구조 처리 (action + text_response)
  Future<void> _handleLegacyResponse(AIResponse aiResponse) async {
    try {
      print('🔄 === 구형 응답 구조 처리 시작 ===');

      // AIResponse에서 action 정보 추출 시도
      if (aiResponse.action != null) {
        print('🎯 구형 action 처리: ${aiResponse.action!.type}');
        await _handleAIAction(aiResponse.action!);
        await _applyUiInstructions(aiResponse.action!.uiInstructions);
      } else {
        print('⚠️ 구형 action이 없습니다');
      }

      print('✅ 구형 응답 구조 처리 완료');
    } catch (e) {
      print('❌ 구형 응답 구조 처리 중 오류: $e');
    }
  }

  // 구형 구조에서 텍스트 응답 추출
  String? _extractLegacyResponseText(AIResponse aiResponse) {
    try {
      print('🔄 구형 텍스트 응답 추출 시도');

      // text_response에서 텍스트 추출
      if (aiResponse.textResponse != null &&
          aiResponse.textResponse!.text.isNotEmpty) {
        print(
          '✅ 구형 text_response에서 텍스트 추출: "${aiResponse.textResponse!.text}"',
        );
        return aiResponse.textResponse!.text;
      }

      print('⚠️ 구형 text_response가 없거나 비어있습니다');
      return null;
    } catch (e) {
      print('❌ 구형 텍스트 응답 추출 중 오류: $e');
      return null;
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

  // 화면/오버레이 닫힘 후에는 TTS 재생을 억제
  Future<void> _speakIfAllowed(String text) async {
    if (_ttsSuppressed) {
      print('🔇 TTS suppressed — 화면/오버레이 종료로 재생 생략');
      return;
    }
    try {
      await _ttsService.speak(text);
    } catch (e) {
      print('❌ TTS 재생 실패: $e');
    }
  }
}
