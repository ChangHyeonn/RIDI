import 'package:flutter/material.dart';
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
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = context.read<TaskProvider>().fontSize;

    return Scaffold(
      backgroundColor: const Color(0xFFfafafa),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFfafafa), const Color(0xFFf5f5f5)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // 메인 알람 카드
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: widget.task.isImportant
                                            ? Colors.red.shade200
                                            : const Color(0xFFe5e7eb),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      widget.task.date.hour < 12 ? '오전' : '오후',
                                      style: TextStyle(
                                        color: widget.task.isImportant
                                            ? Colors.red.shade600
                                            : const Color(0xFF6b7280),
                                        fontSize:
                                            (widget.task.isImportant
                                                ? 20
                                                : 18) *
                                            (0.75 + fontSize * 0.5),
                                        fontWeight: widget.task.isImportant
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
                                          (widget.task.isImportant ? 72 : 64) *
                                          (0.75 + fontSize * 0.5),
                                      fontWeight: widget.task.isImportant
                                          ? FontWeight.w900
                                          : FontWeight.w300,
                                      shadows: widget.task.isImportant
                                          ? [
                                              Shadow(
                                                offset: const Offset(2, 2),
                                                blurRadius: 4,
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
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
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: widget.task.isImportant
                                            ? Colors.red.shade200
                                            : const Color(0xFFe5e7eb),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
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
                                        fontWeight: widget.task.isImportant
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
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
}
