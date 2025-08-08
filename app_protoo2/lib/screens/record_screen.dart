import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../services/record_service.dart';

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

  @override
  void initState() {
    super.initState();
    _checkPlatformSupport();
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
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
        shadowColor: Colors.black.withOpacity(0.08),
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
                  color: Colors.orange.withOpacity(0.1),
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
                    ? Colors.red.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
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
              _isRecording
                  ? '녹음 중...'
                  : _isSupportedPlatform
                  ? '녹음을 시작하려면 버튼을 누르세요'
                  : '지원되지 않는 플랫폼입니다',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isRecording
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
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isRecording
                            ? Colors.red
                            : const Color(0xFF6366f1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isRecording
                                        ? Colors.red
                                        : const Color(0xFF6366f1))
                                    .withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
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

            // 녹음 파일 경로 표시 (디버그용)
            if (_recordingPath != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      '녹음 파일 경로:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _recordingPath!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
