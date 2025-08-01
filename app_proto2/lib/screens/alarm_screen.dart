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
      backgroundColor: const Color(0xFFFF6B35), // 붉은 오렌지색 배경
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 오전/오후 표시
              Center(
                child: Text(
                  widget.task.date.hour < 12 ? '오전' : '오후',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20 * (0.5 + fontSize),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 큰 시간 표시
              Center(
                child: Text(
                  '${widget.task.date.hour.toString().padLeft(2, '0')}:${widget.task.date.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48 * (0.5 + fontSize),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 일정 제목
              Center(
                child: Text(
                  widget.task.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48 * (0.5 + fontSize), // 기존 24 -> 48
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Spacer(),

              // 알람 해제 버튼
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      _dismissAlarm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3), // 밝은 파란색
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '알람 해제하기',
                      style: TextStyle(
                        fontSize: 18 * (0.5 + fontSize),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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

    // 메인 화면으로 돌아가기
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false, // 모든 이전 화면 제거
    );
  }
}
