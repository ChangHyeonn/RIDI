import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../services/alarm_service.dart';
import 'main_screen.dart';

class AlarmScreen extends StatefulWidget {
  final Task task;

  const AlarmScreen({super.key, required this.task});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  double _dragX = 0; // 수평 드래그 위치
  bool _isMuted = false; // 무음 상태
  static const double _swipeThreshold = 120; // 동작 임계치
  late AnimationController _introController; // 진입 애니메이션
  int _remainingSeconds = 60; // 남은 시간 텍스트용
  Timer? _countdownTimer;

  // 시간대/카테고리 기반 배경 그라디언트 계산
  List<Color> _buildBackgroundColors() {
    final hour = DateTime.now().hour;
    List<Color> base;
    if (hour < 6) {
      base = [const Color(0xFF111827), const Color(0xFF312E81)];
    } else if (hour < 12) {
      base = [const Color(0xFF0EA5E9), const Color(0xFF22D3EE)];
    } else if (hour < 18) {
      base = [const Color(0xFF6366F1), const Color(0xFF22C55E)];
    } else {
      base = [const Color(0xFFF97316), const Color(0xFF7C3AED)];
    }

    final cat = widget.task.category.toLowerCase();
    Color tint;
    if (cat.contains('건강') || cat.contains('약')) {
      tint = const Color(0xFF10B981);
    } else if (cat.contains('업무') || cat.contains('회의')) {
      tint = const Color(0xFF6366F1);
    } else if (cat.contains('개인') || cat.contains('가정')) {
      tint = const Color(0xFF8B5CF6);
    } else if (widget.task.isImportant) {
      tint = const Color(0xFFEF4444);
    } else {
      tint = base.first;
    }
    final blended = Color.lerp(base.first, tint, 0.35) ?? base.first;
    return [blended, base.last];
  }

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(_blinkController);

    // 중요한 일정일 때만 깜빡임 시작
    if (widget.task.isImportant) {
      _blinkController.repeat(reverse: true);
    }

    _introController = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    )..forward();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds = (_remainingSeconds - 1).clamp(0, 60);
      });
      if (_remainingSeconds == 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _introController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = context.read<TaskProvider>().fontSize;

    final bgColors = _buildBackgroundColors();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgColors,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // 메인 알람 카드 (스와이프 제스처 적용)
                Expanded(
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _dragX += details.delta.dx;
                      });
                    },
                    onHorizontalDragEnd: (details) {
                      // 임계치를 넘으면 동작 확정
                      if (_dragX > _swipeThreshold) {
                        _dismissAlarm();
                      } else if (_dragX < -_swipeThreshold) {
                        // 왼쪽 길게: 무음 토글 (해제 대기)
                        final alarmService = AlarmService();
                        if (_isMuted) {
                          // 무음 해제는 현재 구조상 소리 재시작 API가 없어 안내만
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('무음 해제: 소리는 다음 알람부터 재생됩니다'),
                            ),
                          );
                          setState(() {
                            _isMuted = false;
                          });
                        } else {
                          alarmService.stopAlarmSound(widget.task.id);
                          setState(() {
                            _isMuted = true;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('무음 전환: 알람은 화면에 유지됩니다'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                      // 원위치 복귀 애니메이션 없이 초기화
                      setState(() {
                        _dragX = 0;
                      });
                    },
                    onVerticalDragUpdate: (details) async {
                      // 위/아래 스와이프: 볼륨 단계 조절(±20%)
                      final provider = context.read<TaskProvider>();
                      double v = provider.soundVolume;
                      if (details.delta.dy < -2) {
                        v = (v + 0.2).clamp(0.0, 1.0);
                      } else if (details.delta.dy > 2) {
                        v = (v - 0.2).clamp(0.0, 1.0);
                      }
                      await provider.setSoundVolume(v);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('볼륨 ${(v * 100).toInt()}%'),
                            duration: const Duration(milliseconds: 600),
                          ),
                        );
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 320),
                          scale: 0.97 + 0.03 * _introController.value,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 320),
                            opacity: _introController.value,
                            child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          // 드래그 시 시각 피드백: 살짝 이동 및 배경색 힌트
                          transform: (Matrix4.identity()
                            ..translate(_dragX, 0.0)
                            ..rotateZ(_dragX / 800)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 상단 메타 배지
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildChip(_categoryLabel(), _categoryColor()),
                                  if (widget.task.isRecurring && widget.task.recurrence != null) ...[
                                    const SizedBox(width: 8),
                                    _buildChip('🔄 ${_nextOccurrenceLabel()}', const Color(0xFF6366F1)),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),
                              // 액션 힌트 오버레이 아이콘
                              if (_dragX.abs() > 8)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Transform.scale(
                                    scale:
                                        1.0 +
                                        (_dragX.abs() / _swipeThreshold).clamp(
                                              0.0,
                                              1.0,
                                            ) *
                                            0.25,
                                    child: Icon(
                                      _dragX > 0
                                          ? Icons.check_circle
                                          : Icons.volume_off,
                                      color: _dragX > 0
                                          ? Colors.green.shade500
                                          : Colors.indigo.shade500,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              // 깜빡이는 효과를 위한 AnimatedBuilder
                              AnimatedBuilder(
                                animation: _blinkAnimation,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: widget.task.isImportant
                                        ? _blinkAnimation.value
                                        : 1.0,
                                    child: Column(
                                      children: [
                                        // AM/PM indicator
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: widget.task.isImportant
                                                ? Colors.red.shade50
                                                : const Color(0xFFf8f9fa),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: widget.task.isImportant
                                                  ? Colors.red.shade200
                                                  : const Color(0xFFe5e7eb),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            widget.task.date.hour < 12
                                                ? '오전'
                                                : '오후',
                                            style: TextStyle(
                                              color: widget.task.isImportant
                                                  ? Colors.red.shade600
                                                  : const Color(0xFF6b7280),
                                              fontSize:
                                                  (widget.task.isImportant
                                                      ? 20
                                                      : 18) *
                                                  (0.75 + fontSize * 0.5),
                                              fontWeight:
                                                  widget.task.isImportant
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 32),

                                        // Large time display
                                        Text(
                                          '${widget.task.date.hour.toString().padLeft(2, '0')}:${widget.task.date.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            color: widget.task.isImportant
                                                ? Colors.red.shade600
                                                : const Color(0xFF1f2937),
                                            fontSize:
                                                (widget.task.isImportant
                                                    ? 72
                                                    : 64) *
                                                (0.75 + fontSize * 0.5),
                                            fontWeight: widget.task.isImportant
                                                ? FontWeight.w900
                                                : FontWeight.w300,
                                            shadows: widget.task.isImportant
                                                ? [
                                                    Shadow(
                                                      offset: const Offset(
                                                        2,
                                                        2,
                                                      ),
                                                      blurRadius: 4,
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 40),

                                        // Task title
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: widget.task.isImportant
                                                ? Colors.red.shade50
                                                : const Color(0xFFf8f9fa),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: widget.task.isImportant
                                                  ? Colors.red.shade200
                                                  : const Color(0xFFe5e7eb),
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                widget.task.title,
                                                style: TextStyle(
                                                  color: widget.task.isImportant
                                                      ? Colors.red.shade700
                                                      : const Color(0xFF1f2937),
                                                  fontSize:
                                                      (widget.task.isImportant
                                                          ? 28
                                                          : 24) *
                                                      (0.75 + fontSize * 0.5),
                                                  fontWeight:
                                                      widget.task.isImportant
                                                      ? FontWeight.w700
                                                      : FontWeight.w600,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              if (_isMuted) ...[
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.indigo.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors
                                                          .indigo
                                                          .shade200,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: const [
                                                      Icon(
                                                        Icons.volume_off,
                                                        size: 14,
                                                        color: Color(
                                                          0xFF6366f1,
                                                        ),
                                                      ),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        '무음 모드',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Color(
                                                            0xFF6366f1,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              // 남은 시간 텍스트
                              Text(
                                '자동 종료까지 약 ${_remainingSeconds}초',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // 미니 타임라인
                              _buildMiniTimeline(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Dismiss button
                Container(
                  width: double.infinity,
                  height: 64 * (0.75 + fontSize * 0.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _dismissAlarm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366f1),
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      '알람 해제하기',
                      style: TextStyle(
                        fontSize: 18 * (0.75 + fontSize * 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _dismissAlarm() {
    // 알람 소리 정지
    final alarmService = AlarmService();
    alarmService.stopAlarmSound(widget.task.id);

    // 알람 해제 시 일정을 완료 상태로 변경
    final taskProvider = context.read<TaskProvider>();
    if (widget.task.isRecurring) {
      // 반복 일정은 오늘 발생만 완료 처리
      taskProvider.toggleOccurrenceCompletion(widget.task.id, DateTime.now());
    } else {
      // 일반 일정은 전역 완료 처리
      final completedTask = widget.task.copyWith(isCompleted: true);
      taskProvider.updateTask(completedTask);
    }

    // 메인 화면으로 돌아가기 (설정 유지)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false, // 모든 이전 화면 제거하되, 설정은 Provider에서 유지됨
    );
  }

  // 메타 배지 빌더
  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _categoryLabel() {
    return widget.task.category.isNotEmpty ? widget.task.category : '일정';
  }

  Color _categoryColor() {
    final c = widget.task.category;
    if (c.contains('업무') || c.contains('회의')) return const Color(0xFF6366F1);
    if (c.contains('건강') || c.contains('약')) return const Color(0xFF10B981);
    if (c.contains('개인') || c.contains('가정')) return const Color(0xFF8B5CF6);
    if (widget.task.isImportant) return const Color(0xFFEF4444);
    return const Color(0xFF6366F1);
  }

  String _nextOccurrenceLabel() {
    final d = widget.task.date.add(const Duration(days: 1));
    return '다음 ${d.month}월 ${d.day}일';
  }

  // 미니 타임라인: 다음 2~3개(더미, 실제 연동은 TaskProvider에서 가져와 확장 가능)
  Widget _buildMiniTimeline(BuildContext context) {
    final color = _categoryColor();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 10 + i * 2,
          height: 10 + i * 2,
          decoration: BoxDecoration(
            color: color.withOpacity(0.9 - i * 0.25),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
