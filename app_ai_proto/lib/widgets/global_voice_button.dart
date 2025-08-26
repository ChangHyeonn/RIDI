import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/record_service.dart';
import '../providers/task_provider.dart';
import '../main.dart';

class GlobalVoiceButton extends StatefulWidget {
  const GlobalVoiceButton({Key? key}) : super(key: key);

  @override
  State<GlobalVoiceButton> createState() => _GlobalVoiceButtonState();
}

class _GlobalVoiceButtonState extends State<GlobalVoiceButton>
    with TickerProviderStateMixin {
  final RecordService _recordService = RecordService();
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isOverlayOpen = false;
  String _recognizedText = '';
  String _aiResponseText = '';

  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 펄스 애니메이션 초기화
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 페이드 애니메이션 초기화
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _initializeRecordService();
  }

  Future<void> _initializeRecordService() async {
    try {
      final success = await _recordService.initialize();
      if (success) {
        // TaskProvider/Context 연결 (로컬 저장 및 UI 반영을 위해 필요)
        try {
          final taskProvider = context.read<TaskProvider>();
          _recordService.setTaskProvider(taskProvider);
          _recordService.setContext(context);
          print('✅ GlobalVoiceButton: TaskProvider/Context 연결 완료');
        } catch (e) {
          print('⚠️ GlobalVoiceButton: TaskProvider/Context 연결 실패: $e');
        }

        // 실시간 음성 인식 텍스트 스트림 구독
        _recordService.textStream.listen((text) {
          if (mounted) {
            setState(() {
              _recognizedText = text;
            });
          }
        });

        // AI 응답 스트림 구독
        _recordService.aiResponseStream.listen((response) {
          if (mounted) {
            setState(() {
              _aiResponseText = response;
              if (response.isNotEmpty) {
                _isProcessing = false;
                _isRecording = false;
                _stopAnimations();
              }
            });
          }
        });
      }
    } catch (e) {
      print('❌ GlobalVoiceButton 초기화 실패: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _recordService.dispose();
    super.dispose();
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  void _stopAnimations() {
    _pulseController.stop();
    _fadeController.reverse();
  }

  Future<void> _startRecording() async {
    try {
      // 오버레이 열기 + 녹음 시작
      setState(() {
        _isOverlayOpen = true;
      });

      final success = await _recordService.startRecording();
      if (success) {
        setState(() {
          _isRecording = true;
          _recognizedText = '';
          _aiResponseText = '';
        });
        _startAnimations();
      }
    } catch (e) {
      print('❌ 녹음 시작 실패: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final recognizedText = await _recordService.stopRecording();
      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });
      _stopAnimations();
    } catch (e) {
      print('❌ 녹음 중지 실패: $e');
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
    }
  }

  Future<void> _cancelAndCloseOverlay() async {
    try {
      if (_isRecording) {
        await _recordService.cancelRecording();
      }
    } catch (e) {
      print('❌ 오버레이 닫기 중 취소 실패: $e');
    } finally {
      setState(() {
        _isRecording = false;
        _isProcessing = false;
        _recognizedText = '';
        _aiResponseText = '';
        _isOverlayOpen = false;
      });
      _stopAnimations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = _isRecording || _isProcessing;

    // 오버레이가 열리지 않았을 때는 작은 버튼만 노출
    if (!_isOverlayOpen) {
      return SizedBox(
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () {
            if (_isRecording) {
              _stopRecording();
            } else if (!_isProcessing) {
              _startRecording();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF6366f1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366f1).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 35),
          ),
        ),
      );
    }

    // 녹음/처리 중에는 전체 화면 오버레이를 표시하고 터치를 차단
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 화면 전체를 어둡게 + 터치 차단
          ModalBarrier(
            color: Colors.black.withOpacity(0.7),
            dismissible: false,
          ),

          // 중앙 콘텐츠
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isRecording)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366f1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366f1).withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      );
                    },
                  ),

                if (_isProcessing)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366f1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366f1).withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),

                const SizedBox(height: 40),

                if (_recognizedText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _recognizedText,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 20),

                if (_aiResponseText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366f1).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _aiResponseText,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 40),

                Text(
                  _isRecording ? '말씀해주세요...' : '처리 중...',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 하단 버튼 영역: 닫기 + 중지/녹음 토글
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 닫기 버튼
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: GestureDetector(
                      onTap: _cancelAndCloseOverlay,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 중지/녹음 토글 버튼
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: GestureDetector(
                      onTap: () {
                        if (_isProcessing) return; // 처리 중엔 방지
                        if (_isRecording) {
                          _stopRecording();
                        } else {
                          _startRecording();
                        }
                      },
                      child: Container(
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
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
