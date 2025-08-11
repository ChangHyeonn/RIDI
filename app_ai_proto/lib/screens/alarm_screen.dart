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

class _AlarmScreenState extends State<AlarmScreen> {
  @override
  Widget build(BuildContext context) {
    final fontSize = context.read<TaskProvider>().fontSize;

    return Scaffold(
      backgroundColor: Color(0xFFfafafa),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFfafafa), Color(0xFFf5f5f5)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 100), // 상단 여백 추가
                // AM/PM indicator
                Text(
                  widget.task.date.hour < 12 ? '오전' : '오후',
                  style: TextStyle(
                    color: Color(0xFF6b7280),
                    fontSize: 24 * (0.75 + fontSize * 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 20),
                // Large time display
                Text(
                  '${widget.task.date.hour.toString().padLeft(2, '0')}:${widget.task.date.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Color(0xFF1f2937),
                    fontSize: 64 * (0.75 + fontSize * 0.5),
                    fontWeight: FontWeight.w300,
                  ),
                ),
                SizedBox(height: 40),
                // Task title
                Text(
                  widget.task.title,
                  style: TextStyle(
                    color: Color(0xFF1f2937),
                    fontSize: 56 * (0.75 + fontSize * 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                Spacer(),
                // Dismiss button
                Container(
                  width: double.infinity,
                  height: 60 * (0.75 + fontSize * 0.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _dismissAlarm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Color(0xFF6366f1),
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      '알람 해제하기',
                      style: TextStyle(
                        fontSize: 22 * (0.75 + fontSize * 0.5),
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
    alarmService.stopAlarmSound();

    // 알람 해제 시 일정을 완료 상태로 변경
    final taskProvider = context.read<TaskProvider>();
    final completedTask = widget.task.copyWith(isCompleted: true);
    taskProvider.updateTask(completedTask);

    // 메인 화면으로 돌아가기 (설정 유지)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false, // 모든 이전 화면 제거하되, 설정은 Provider에서 유지됨
    );
  }
}
