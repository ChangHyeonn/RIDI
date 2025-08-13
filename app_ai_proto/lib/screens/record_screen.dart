import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/task_provider.dart';
import '../services/record_service.dart';
import '../services/ai_service.dart';
import '../services/action_handler.dart';
import '../services/audio_player_service.dart';
import '../models/ai_response.dart';
import 'package:share_plus/share_plus.dart';
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
      final path = await _recordService.stopRecording();
      setState(() {
        _isRecording = false;
        _recordingPath = path;
      });

      if (path != null) {
        _showSuccessSnackBar('음성 인식이 완료되었습니다.');
        // AI 처리 시작
        await _processWithAI(path);
      } else {
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
      });
      _showSuccessSnackBar('음성 인식이 취소되었습니다.');
    } catch (e) {
      _showErrorSnackBar('음성 인식을 취소할 수 없습니다: $e');
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

  Future<void> _shareRecording(File file) async {
    try {
      // 음성 인식 기반에서는 텍스트 공유
      await Share.share(_recordService.recognizedText, subject: '음성 인식 결과');
    } catch (e) {
      _showErrorSnackBar('텍스트 공유 실패: $e');
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

  Future<void> _processWithAI(String recognizedText) async {
    if (mounted) {
      setState(() {
        _isProcessingAI = true;
        _aiResponseText = 'AI가 텍스트를 분석하고 있습니다...';
      });
    }

    try {
      // AI 서버에 텍스트 전송
      final aiResponse = await AIService.processText(recognizedText);

      if (mounted) {
        setState(() {
          _aiResponseText = aiResponse.textResponse?.text ?? '응답을 받지 못했습니다.';
        });
      }

      // 액션 처리
      if (aiResponse.action != null && mounted) {
        ActionHandler.handleAction(aiResponse.action!, context);
      }

      // TTS로 음성 응답 재생
      if (aiResponse.textResponse?.text != null) {
        await _recordService.playRecording(null);
      }

      _showSuccessSnackBar('AI 처리가 완료되었습니다.');
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiResponseText = 'AI 처리 중 오류가 발생했습니다: $e';
        });
      }
      _showErrorSnackBar('AI 처리 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAI = false;
        });
      }
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

              // 상태 텍스트
              Text(
                _isProcessingAI
                    ? 'AI 처리 중...'
                    : _isRecording
                    ? '음성 인식 중...'
                    : _isSupportedPlatform
                    ? '음성 인식을 시작하려면 버튼을 누르세요'
                    : '지원되지 않는 플랫폼입니다',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isProcessingAI
                      ? const Color(0xFF6366f1)
                      : _isRecording
                      ? Colors.red
                      : _isSupportedPlatform
                      ? Colors.grey[600]
                      : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
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

                    // 취소 버튼 (음성 인식 중일 때만 표시)
                    if (_isRecording)
                      GestureDetector(
                        onTap: _cancelRecording,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                  ],
                ),

              const SizedBox(height: 60),

              // 인식된 텍스트 표시
              if (_recordService.recognizedText.isNotEmpty) ...[
                const Text(
                  '인식된 텍스트',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.text_fields,
                            color: Color(0xFF6366f1),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '인식된 내용',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _recordService.recognizedText,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                      if (_recordService.aiResponseText.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.smart_toy,
                              color: Color(0xFF10b981),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'AI 응답',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Color(0xFF10b981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _recordService.aiResponseText,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF10b981),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // AI 응답 재생 버튼
                            IconButton(
                              onPressed: () async {
                                await _recordService.playRecording(null);
                              },
                              icon: const Icon(
                                Icons.play_arrow,
                                color: Color(0xFF10b981),
                                size: 20,
                              ),
                            ),
                            // AI 응답 공유 버튼
                            IconButton(
                              onPressed: () async {
                                await Share.share(
                                  _recordService.aiResponseText,
                                  subject: 'AI 응답',
                                );
                              },
                              icon: const Icon(
                                Icons.share,
                                color: Color(0xFF10b981),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
