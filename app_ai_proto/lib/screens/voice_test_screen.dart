import 'package:flutter/material.dart';
import 'dart:async';
import '../services/unified_voice_service.dart';
import '../models/ai_response.dart';

class VoiceTestScreen extends StatefulWidget {
  const VoiceTestScreen({super.key});

  @override
  State<VoiceTestScreen> createState() => _VoiceTestScreenState();
}

class _VoiceTestScreenState extends State<VoiceTestScreen> {
  final UnifiedVoiceService _voiceService = UnifiedVoiceService();

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String _currentText = '';
  String _lastProcessedText = '';
  String _statusMessage = '음성 서비스를 초기화 중입니다...';
  String? _errorMessage;
  AIResponse? _lastAIResponse;

  @override
  void initState() {
    super.initState();
    _initializeVoiceService();
  }

  Future<void> _initializeVoiceService() async {
    try {
      final success = await _voiceService.initialize();
      if (success) {
        setState(() {
          _isInitialized = true;
          _statusMessage = '음성 서비스가 준비되었습니다.';
        });

        // 스트림 구독
        _voiceService.statusStream.listen((status) {
          setState(() {
            _statusMessage = status;
          });
        });

        _voiceService.textStream.listen((text) {
          setState(() {
            _currentText = text;
          });
        });

        _voiceService.aiResponseStream.listen((response) {
          setState(() {
            _lastAIResponse = response;
          });
        });

        _voiceService.errorStream.listen((error) {
          setState(() {
            _errorMessage = error;
          });
        });

        // 상태 업데이트
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
          if (mounted) {
            final status = _voiceService.getCurrentStatus();
            setState(() {
              _isListening = status['isListening'] ?? false;
              _isProcessing = status['isProcessing'] ?? false;
              _isSpeaking = _voiceService.isSpeaking;
              _currentText = status['currentText'] ?? '';
              _lastProcessedText = status['lastProcessedText'] ?? '';
            });
          }
        });
      } else {
        setState(() {
          _statusMessage = '음성 서비스 초기화에 실패했습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '음성 서비스 초기화 중 오류가 발생했습니다: $e';
      });
    }
  }

  Future<void> _startVoiceRecognition() async {
    if (!_isInitialized) {
      _showSnackBar('음성 서비스가 초기화되지 않았습니다.');
      return;
    }

    try {
      final success = await _voiceService.startVoiceRecognition();
      if (!success) {
        _showSnackBar('음성 인식을 시작할 수 없습니다.');
      }
    } catch (e) {
      _showSnackBar('음성 인식 시작 중 오류: $e');
    }
  }

  Future<void> _stopVoiceRecognition() async {
    try {
      await _voiceService.stopVoiceRecognitionAndProcess();
    } catch (e) {
      _showSnackBar('음성 인식 중지 중 오류: $e');
    }
  }

  Future<void> _cancelVoiceRecognition() async {
    try {
      await _voiceService.cancelVoiceRecognition();
    } catch (e) {
      _showSnackBar('음성 인식 취소 중 오류: $e');
    }
  }

  Future<void> _stopTTS() async {
    try {
      await _voiceService.stopTTS();
    } catch (e) {
      _showSnackBar('음성 재생 중지 중 오류: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('음성 서비스 테스트'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상태 표시 카드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '서비스 상태',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildStatusRow('초기화', _isInitialized),
                    _buildStatusRow('음성 인식 중', _isListening),
                    _buildStatusRow('AI 처리 중', _isProcessing),
                    _buildStatusRow('음성 재생 중', _isSpeaking),
                    const SizedBox(height: 8),
                    Text(
                      '상태 메시지: $_statusMessage',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '오류: $_errorMessage',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 음성 인식 컨트롤
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '음성 인식',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isInitialized &&
                                    !_isListening &&
                                    !_isProcessing
                                ? _startVoiceRecognition
                                : null,
                            icon: const Icon(Icons.mic),
                            label: const Text('음성 인식 시작'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isListening
                                ? _stopVoiceRecognition
                                : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('인식 중지'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isListening ? _cancelVoiceRecognition : null,
                      icon: const Icon(Icons.cancel),
                      label: const Text('인식 취소'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 텍스트 표시
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '인식된 텍스트',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentText.isNotEmpty
                            ? _currentText
                            : '음성을 인식하면 여기에 표시됩니다.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    if (_lastProcessedText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '최종 처리된 텍스트:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _lastProcessedText,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // AI 응답 표시
            if (_lastAIResponse != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI 응답',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '응답 텍스트:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _lastAIResponse!.textResponse?.text ?? '응답 없음',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (_isSpeaking) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.volume_up,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('음성 재생 중...'),
                                  const Spacer(),
                                  ElevatedButton(
                                    onPressed: _stopTTS,
                                    child: const Text('중지'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 음성 재생 컨트롤
            if (_isSpeaking) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '음성 재생',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _stopTTS,
                        icon: const Icon(Icons.stop),
                        label: const Text('음성 재생 중지'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            color: isActive ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }
}
