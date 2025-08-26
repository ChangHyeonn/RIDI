import 'package:flutter/material.dart';
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
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  double _dragX = 0; // 수평 드래그 위치
  static const double _swipeThreshold = 120; // 동작 임계치
  late AnimationController _introController; // 진입 애니메이션
  // (자동 종료 카운트다운 제거)

  // (그라디언트 제거됨)

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

    // (자동 종료 카운트다운 제거)
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _introController.dispose();
    // (자동 종료 카운트다운 제거)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = context.read<TaskProvider>().fontSize;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),

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
                        // 왼쪽 길게: (무음 모드 제거 → 동작 없음)
                      }
                      // 원위치 복귀 애니메이션 없이 초기화
                      setState(() {
                        _dragX = 0;
                      });
                    },
                    // onVerticalDragUpdate 제거 (볼륨 제스처 비활성화)
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
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 30,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.06),
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
                                      _buildChip(
                                        _categoryLabel(),
                                        _categoryColor(),
                                      ),
                                      if (widget.task.isRecurring &&
                                          widget.task.recurrence != null) ...[
                                        const SizedBox(width: 8),
                                        _buildChip(
                                          '🔄 ${_nextOccurrenceLabel()}',
                                          const Color(0xFF6366F1),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // 액션 힌트 오버레이 아이콘
                                  if (_dragX.abs() > 8)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Transform.scale(
                                        scale:
                                            1.0 +
                                            (_dragX.abs() / _swipeThreshold)
                                                    .clamp(0.0, 1.0) *
                                                0.25,
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Colors.green.shade500,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.surface,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: Theme.of(
                                                    context,
                                                  ).dividerColor,
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
                                                color:
                                                    Theme.of(context)
                                                        .textTheme
                                                        .headlineMedium
                                                        ?.color ??
                                                    const Color(0xFF1f2937),
                                                fontSize:
                                                    (widget.task.isImportant
                                                        ? 72
                                                        : 64) *
                                                    (0.75 + fontSize * 0.5),
                                                fontWeight:
                                                    widget.task.isImportant
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 16,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.surface,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Theme.of(
                                                    context,
                                                  ).dividerColor,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    widget.task.title,
                                                    style: TextStyle(
                                                      color:
                                                          widget
                                                              .task
                                                              .isImportant
                                                          ? Colors.red.shade700
                                                          : const Color(
                                                              0xFF1f2937,
                                                            ),
                                                      fontSize:
                                                          (widget
                                                                  .task
                                                                  .isImportant
                                                              ? 28
                                                              : 24) *
                                                          (0.75 +
                                                              fontSize * 0.5),
                                                      fontWeight:
                                                          widget
                                                              .task
                                                              .isImportant
                                                          ? FontWeight.w700
                                                          : FontWeight.w600,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  // (무음 모드 배지 제거)
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  // (자동 종료 문구 제거)
                                  // 미니 타임라인
                                  _buildMiniTimeline(context),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // (하단 해제 버튼 제거)
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
