import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../services/record_service.dart';
import '../services/ai_service.dart';
import '../services/action_handler.dart';
import '../services/audio_player_service.dart';
import '../models/ai_response.dart';

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

  @override
  void initState() {
    super.initState();
    _checkPlatformSupport();
    _loadRecordedFiles();
  }

  void _checkPlatformSupport() {
    if (kIsWeb) {
      _isSupportedPlatform = false;
      _errorMessage = '웹에서는 녹음 기능을 지원하지 않습니다.';
    } else {
      _isSupportedPlatform = Platform.isAndroid || Platform.isIOS;
      if (!_isSupportedPlatform) {
        _errorMessage = '현재 플랫폼에서 녹음 기능을 지원하지 않습니다.';
      }
    }
  }

  Future<void> _loadRecordedFiles() async {
    try {
      final files = await _recordService.getRecordedFiles();
      setState(() {
        _recordedFiles = files;
      });
    } catch (e) {
      print('녹음 파일 목록 로드 실패: $e');
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
      final success = await _recordService.startRecording();
      if (success) {
        setState(() {
          _isRecording = true;
        });
      } else {
        _showErrorSnackBar('녹음을 시작할 수 없습니다.');
      }
    } catch (e) {
      _showErrorSnackBar('녹음을 시작할 수 없습니다: $e');
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
        _showSuccessSnackBar('녹음이 완료되었습니다.');
        // 녹음 파일 목록 새로고침
        await _loadRecordedFiles();

        // AI 처리 시작
        await _processWithAI(path);
      } else {
        _showErrorSnackBar('녹음 파일을 저장할 수 없습니다.');
      }
    } catch (e) {
      _showErrorSnackBar('녹음을 중지할 수 없습니다: $e');
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _recordService.cancelRecording();
      setState(() {
        _isRecording = false;
        _recordingPath = null;
      });
      _showSuccessSnackBar('녹음이 취소되었습니다.');
    } catch (e) {
      _showErrorSnackBar('녹음을 취소할 수 없습니다: $e');
    }
  }

  Future<void> _deleteRecording(File file) async {
    try {
      final success = await _recordService.deleteRecording(file.path);
      if (success) {
        _showSuccessSnackBar('녹음 파일이 삭제되었습니다.');
        await _loadRecordedFiles();
      } else {
        _showErrorSnackBar('녹음 파일 삭제에 실패했습니다.');
      }
    } catch (e) {
      _showErrorSnackBar('녹음 파일 삭제 중 오류가 발생했습니다: $e');
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

  Future<void> _processWithAI(String audioPath) async {
    if (mounted) {
      setState(() {
        _isProcessingAI = true;
        _aiResponseText = 'AI가 음성을 분석하고 있습니다...';
      });
    }

    try {
      // AI 서버에 음성 파일 전송
      final aiResponse = await AIService.processVoice(audioPath);

      if (mounted) {
        setState(() {
          _aiResponseText = aiResponse.voiceResponse?.text ?? '응답을 받지 못했습니다.';
        });
      }

      // 액션 처리
      if (aiResponse.action != null && mounted) {
        ActionHandler.handleAction(aiResponse.action!, context);
      }

      // 음성 응답 재생
      if (aiResponse.voiceResponse?.audioUrl != null &&
          aiResponse.voiceResponse!.playAutomatically) {
        await AudioPlayerService.playAudioFromBase64(
          aiResponse.voiceResponse!.audioUrl!,
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfafafa),
      appBar: AppBar(
        title: const Text('음성 녹음'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1f2937),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
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
                      _errorMessage ?? '녹음 기능은 Android 또는 iOS 기기에서만 지원됩니다.',
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
                  ? '녹음 중...'
                  : _isSupportedPlatform
                  ? '녹음을 시작하려면 버튼을 누르세요'
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

            // 녹음 버튼들
            if (_isSupportedPlatform)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 녹음 시작/중지 버튼
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
                            color: _isProcessingAI
                                ? Colors.grey.withValues(alpha: 0.3)
                                : (_isRecording
                                          ? Colors.red
                                          : const Color(0xFF6366f1))
                                      .withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
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

                  // 녹음 취소 버튼 (녹음 중일 때만 표시)
                  if (_isRecording)
                    GestureDetector(
                      onTap: _cancelRecording,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.grey,
                          size: 30,
                        ),
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 40),

            // AI 응답 텍스트
            if (_aiResponseText != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366f1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6366f1).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.smart_toy,
                          color: const Color(0xFF6366f1),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'AI 응답',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366f1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _aiResponseText!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 저장된 녹음 파일 목록
            if (_recordedFiles.isNotEmpty) ...[
              const Text(
                '저장된 녹음 파일',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1f2937),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _recordedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _recordedFiles[index];
                    final fileName = file.path.split('/').last;
                    final fileSize = (file.lengthSync() / 1024).toStringAsFixed(
                      1,
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.audiotrack,
                            color: Color(0xFF6366f1),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '$fileSize KB',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteRecording(file),
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
