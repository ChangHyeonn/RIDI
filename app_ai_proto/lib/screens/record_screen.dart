import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../services/record_service.dart';
import '../services/ai_service.dart';
import '../permissions_init.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final RecordService _recordService = RecordService();
  bool _isRecording = false;
  String? _recordingPath;
  bool _isSupportedPlatform = false;
  String? _errorMessage;
  List<File> _recordedFiles = [];
  bool _isProcessingAI = false;
  String? _aiResponseText;
  String? _currentlyPlayingPath;
  String _currentRecognizedText = ''; // 실시간 음성 인식 텍스트
  bool _isClarificationMode = false; // 명확화 모드 상태
  String _pendingClarification = ''; // 대기 중인 명확화 요청
  String _originalRequest = ''; // 원본 요청 텍스트

  @override
  void initState() {
    super.initState();
    _checkPlatformSupport();
    _loadRecordedFiles();
    _initializeRecordService();
    // 권한 초기화는 사용자가 버튼을 눌렀을 때 하도록 변경
  }

  Future<void> _initializeRecordService() async {
    try {
      print('=== RecordScreen에서 RecordService 초기화 시작 ===');
      final success = await _recordService.initialize();
      if (success) {
        print('✅ RecordService 초기화 성공');

        // TaskProvider 설정
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        _recordService.setTaskProvider(taskProvider);
        print('✅ TaskProvider 설정 완료');

        // 실시간 음성 인식 텍스트 스트림 구독
        _recordService.textStream.listen((text) {
          setState(() {
            _currentRecognizedText = text;
          });
          print('🎤 실시간 음성 인식 텍스트: "$text"');
        });

        // AI 응답 스트림 구독
        _recordService.aiResponseStream.listen((response) {
          setState(() {
            _aiResponseText = response;
            // 빈 응답이 오면 AI 처리 상태 해제 (처리 완료 또는 텍스트 없음)
            if (response.isEmpty) {
              _isProcessingAI = false;
            }
            // AI 응답이 오면 처리 중 상태 해제 (단, "분석 중" 메시지는 제외)
            else if (response.isNotEmpty &&
                !response.contains('AI가 텍스트를 분석하고 있습니다')) {
              _isProcessingAI = false;
            }
          });
          print('🤖 AI 응답: "$response"');
        });

        // 녹음 상태 스트림 구독 (자동 재시작을 위해)
        _recordService.recordingStateStream.listen((isRecording) {
          setState(() {
            _isRecording = isRecording;
          });
          print('🎤 녹음 상태 변경: $isRecording');
        });

        // 명확화 모드 상태 업데이트
        _updateClarificationMode();

        print('✅ 스트림 구독 설정 완료');
      } else {
        print('❌ RecordService 초기화 실패');
      }
    } catch (e) {
      print('❌ RecordService 초기화 중 오류: $e');
    }
  }

  Future<void> _initializePermissions() async {
    try {
      print('=== RecordScreen에서 권한 초기화 시작 ===');
      await PermissionsInit.requestNecessaryPermissions();
      print('✅ RecordScreen 권한 초기화 완료');
    } catch (e) {
      print('❌ RecordScreen 권한 초기화 중 오류: $e');
    }
  }

  // 명확화 모드 상태 업데이트
  void _updateClarificationMode() {
    setState(() {
      _isClarificationMode = _recordService.isClarificationMode;
      _pendingClarification = _recordService.pendingClarification;
      _originalRequest = _recordService.originalRequest;
    });
  }

  void _checkPlatformSupport() {
    if (kIsWeb) {
      _isSupportedPlatform = true; // 웹에서도 음성 인식 지원
      _errorMessage = null;
    } else {
      _isSupportedPlatform = Platform.isAndroid || Platform.isIOS;
      if (!_isSupportedPlatform) {
        _errorMessage = '현재 플랫폼에서 음성 인식 기능을 지원하지 않습니다.';
      }
    }
  }

  Future<void> _loadRecordedFiles() async {
    try {
      // 음성 인식 기반에서는 파일 목록 대신 인식된 텍스트 목록을 표시
      setState(() {
        _recordedFiles = []; // 파일 목록은 더 이상 사용하지 않음
      });
    } catch (e) {
      print('텍스트 목록 로드 실패: $e');
    }
  }

  @override
  void dispose() {
    // 화면이 닫힐 때 진행 중인 TTS가 있다면 중단
    try {
      _recordService.stopPlaying();
    } catch (_) {}
    _recordService.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!_isSupportedPlatform) {
      _showErrorSnackBar(_errorMessage ?? '지원되지 않는 플랫폼입니다.');
      return;
    }

    try {
      // 1. 권한 확인 및 요청
      print('=== 음성 인식 시작 - 권한 확인 ===');
      final hasPermission = await PermissionsInit.checkMicrophonePermission();

      if (!hasPermission) {
        print('권한이 없습니다. 권한을 요청합니다...');

        // iOS에서 권한 팝업이 안 뜨는 문제 해결
        if (Platform.isIOS) {
          print('🍎 iOS 환경 - 실제 마이크 접근으로 권한 팝업 트리거');
          await _recordService.triggerIOSMicrophoneRequest();
        }

        await PermissionsInit.requestNecessaryPermissions();

        // 권한 요청 후 다시 확인
        final permissionGranted =
            await PermissionsInit.checkMicrophonePermission();
        if (!permissionGranted) {
          _showErrorSnackBar('마이크 권한이 필요합니다. 설정에서 권한을 허용해주세요.');
          return;
        }
      }

      print('✅ 권한 확인 완료 - 음성 인식 시작');

      // 2. 음성 인식 시작
      final success = await _recordService.startRecording();
      if (success) {
        setState(() {
          _isRecording = true;
          _currentRecognizedText = ''; // 실시간 텍스트 초기화
        });
        print('✅ 음성 인식 시작 성공');

        // 사용자 안내
        _showSuccessSnackBar('음성 인식이 시작되었습니다. 1-2초 후 말씀해주세요.');
      } else {
        _showErrorSnackBar('음성 인식을 시작할 수 없습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      print('❌ 음성 인식 시작 중 오류: $e');
      _showErrorSnackBar('음성 인식을 시작할 수 없습니다: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final recognizedText = await _recordService.stopRecording();
      setState(() {
        _isRecording = false;
        _recordingPath = recognizedText; // 텍스트를 저장 (호환성 유지)
        _isProcessingAI = true; // AI 처리 중 표시
        _currentRecognizedText = ''; // 실시간 텍스트 초기화
      });

      // AI 처리는 RecordService에서 자동으로 수행되므로 여기서는 하지 않음
      if (recognizedText == null || recognizedText.isEmpty) {
        // 텍스트가 없으면 즉시 실패 메시지
        _showErrorSnackBar('음성 인식 결과를 처리할 수 없습니다.');
      }
    } catch (e) {
      _showErrorSnackBar('음성 인식을 중지할 수 없습니다: $e');
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _recordService.cancelRecording();
      setState(() {
        _isRecording = false;
        _recordingPath = null;
        _currentRecognizedText = ''; // 실시간 텍스트 초기화
      });
      _showSuccessSnackBar('음성 인식이 취소되었습니다.');
    } catch (e) {
      _showErrorSnackBar('음성 인식을 취소할 수 없습니다: $e');
    }
  }

  // 명확화 모드 취소
  Future<void> _cancelClarification() async {
    try {
      _recordService.exitClarificationMode();
      _updateClarificationMode();
      _showSuccessSnackBar('명확화 모드가 취소되었습니다.');
    } catch (e) {
      _showErrorSnackBar('명확화 모드를 취소할 수 없습니다: $e');
    }
  }

  Future<void> _deleteRecording(File file) async {
    try {
      // 음성 인식 기반에서는 파일 삭제 대신 텍스트 초기화
      _showSuccessSnackBar('텍스트가 초기화되었습니다.');
      await _loadRecordedFiles();
    } catch (e) {
      _showErrorSnackBar('텍스트 초기화 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _playRecording(File file) async {
    try {
      // 현재 재생 중인 파일이 있다면 중지
      if (_currentlyPlayingPath != null) {
        await _recordService.stopPlaying();
        setState(() {
          _currentlyPlayingPath = null;
        });
      }

      // 새 파일 재생
      final success = await _recordService.playRecording(file.path);
      if (success) {
        setState(() {
          _currentlyPlayingPath = file.path;
        });
        _showSuccessSnackBar('AI 응답을 재생합니다.');
      } else {
        _showErrorSnackBar('AI 응답 재생에 실패했습니다.');
      }
    } catch (e) {
      _showErrorSnackBar('AI 응답 재생 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _stopPlaying() async {
    try {
      await _recordService.stopPlaying();
      setState(() {
        _currentlyPlayingPath = null;
      });
      _showSuccessSnackBar('재생이 중지되었습니다.');
    } catch (e) {
      _showErrorSnackBar('재생 중지 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _printFileInfo(File file) async {
    try {
      // 음성 인식 기반에서는 파일 정보 대신 텍스트 정보 출력
      print('텍스트 정보: ${_recordService.recognizedText}');
      _showSuccessSnackBar('텍스트 정보가 콘솔에 출력되었습니다.');
    } catch (e) {
      _showErrorSnackBar('텍스트 정보 출력 중 오류가 발생했습니다: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // 마이크 테스트 기능 제거됨 (음성 인식 기반으로 변경)

  Future<void> _testAIConnection() async {
    try {
      final isConnected = await AIService.testConnection();
      if (isConnected) {
        _showSuccessSnackBar('AI 서버에 연결되었습니다!');
      } else {
        _showErrorSnackBar('AI 서버에 연결할 수 없습니다. 서버가 실행 중인지 확인하세요.');
      }
    } catch (e) {
      _showErrorSnackBar('AI 서버 연결 테스트 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfafafa),
      appBar: AppBar(
        title: const Text('음성 인식'),
        backgroundColor: const Color(0xFF10b981),
        foregroundColor: Colors.white,
        actions: [
          // AI 서버 연결 상태 확인 버튼
          IconButton(
            onPressed: _testAIConnection,
            icon: const Icon(Icons.wifi),
            tooltip: 'AI 서버 연결 확인',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 플랫폼 지원 안내
              if (!_isSupportedPlatform)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage ??
                            '음성 인식 기능은 Android, iOS 또는 Web에서 지원됩니다.',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              // 녹음 상태 표시
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: _isRecording
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isRecording ? Colors.red : Colors.grey,
                    width: 3,
                  ),
                ),
                child: Icon(
                  _isRecording ? Icons.mic : Icons.mic_none,
                  size: 80,
                  color: _isRecording ? Colors.red : Colors.grey,
                ),
              ),
              const SizedBox(height: 40),

              // 명확화 모드 표시
              if (_isClarificationMode) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.help_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '추가 정보가 필요합니다',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_originalRequest.isNotEmpty) ...[
                        Text(
                          '원래 요청: $_originalRequest',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        _pendingClarification,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],

              // 상태 텍스트
              Text(
                _isClarificationMode
                    ? '추가 정보를 말씀해주세요'
                    : _isProcessingAI
                    ? 'AI 처리 중...'
                    : _isRecording
                    ? '음성 인식 중...'
                    : _isSupportedPlatform
                    ? '음성 인식을 시작하려면 버튼을 누르세요'
                    : '지원되지 않는 플랫폼입니다',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isClarificationMode
                      ? Colors.blue
                      : _isProcessingAI
                      ? const Color(0xFF6366f1)
                      : _isRecording
                      ? Colors.red
                      : _isSupportedPlatform
                      ? Colors.grey[600]
                      : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),

              // 실시간 음성 인식 텍스트 표시
              if (_isRecording && _currentRecognizedText.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _currentRecognizedText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 60),

              // 음성 인식 버튼들
              if (_isSupportedPlatform)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 음성 인식 시작/중지 버튼
                    GestureDetector(
                      onTap: _isProcessingAI
                          ? null
                          : (_isRecording ? _stopRecording : _startRecording),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _isProcessingAI
                              ? Colors.grey
                              : _isRecording
                              ? Colors.red
                              : const Color(0xFF6366f1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isProcessingAI
                              ? Icons.hourglass_empty
                              : _isRecording
                              ? Icons.stop
                              : Icons.mic,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),

                    // 취소 버튼 (음성 인식 중이거나 명확화 모드일 때 표시)
                    if (_isRecording || _isClarificationMode)
                      GestureDetector(
                        onTap: _isClarificationMode
                            ? _cancelClarification
                            : _cancelRecording,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _isClarificationMode
                                ? Colors.orange
                                : Colors.grey[400],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isClarificationMode ? Icons.cancel : Icons.close,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                  ],
                ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
