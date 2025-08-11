import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import 'edit_task_screen.dart';

class DateDetailScreen extends StatefulWidget {
  final DateTime date;
  final String title;

  const DateDetailScreen({super.key, required this.date, required this.title});

  @override
  State<DateDetailScreen> createState() => _DateDetailScreenState();
}

class _DateDetailScreenState extends State<DateDetailScreen> {
  // 요일 가져오기
  String _getDayOfWeek(DateTime date) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[date.weekday - 1];
  }

  // 시간 포맷 (오전/오후 형식)
  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour < 12 ? hour : (hour == 12 ? 12 : hour - 12);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$period${displayHour.toString().padLeft(2, '0')}:$displayMinute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfafafa),
      body: SafeArea(
        child: Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            final fontSize = taskProvider.fontSize;
            final scaleFactor = 0.75 + (fontSize * 0.5); // 75%~125% 범위

            return Column(
              children: [
                // 상단 앱바
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Expanded(
                        child: Text(
                          '날짜별화면',
                          style: TextStyle(
                            fontSize: 16 * scaleFactor,
                            color: const Color(0xFF6b7280),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // 뒤로가기 버튼과 균형 맞추기
                    ],
                  ),
                ),

                // 날짜 표시 (요일 포함)
                Text(
                  '${widget.date.month}/${widget.date.day}(${_getDayOfWeek(widget.date)})',
                  style: TextStyle(
                    fontSize: 32 * scaleFactor,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1f2937),
                  ),
                ),
                const SizedBox(height: 24),

                // 일정 목록
                Expanded(
                  child: Consumer<TaskProvider>(
                    builder: (context, taskProvider, child) {
                      final tasks = taskProvider.getTasksForDate(widget.date);

                      // 시간이 임박한 순서대로 정렬
                      tasks.sort((a, b) => a.date.compareTo(b.date));

                      if (tasks.isEmpty) {
                        return Center(
                          child: Text(
                            '이 날짜에 등록된 일정이 없습니다.',
                            style: TextStyle(
                              fontSize: 16 * scaleFactor,
                              color: const Color(0xFF6b7280),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return GestureDetector(
                            onTap: () {
                              // 완료된 일정인지 확인
                              if (task.isCompleted) {
                                // 완료된 일정이면 알림창 띄우기
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(
                                        '완료된 일정',
                                        style: TextStyle(
                                          fontSize: 18 * scaleFactor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: Text(
                                        '이미 완료된 일정입니다.\n완료된 일정은 수정할 수 없습니다.',
                                        style: TextStyle(
                                          fontSize: 16 * scaleFactor,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(
                                            '확인',
                                            style: TextStyle(
                                              fontSize: 16 * scaleFactor,
                                              color: const Color(0xFF6366f1),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } else {
                                // 미완료 일정이면 일정 수정창으로 이동
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditTaskScreen(task: task),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: task.isCompleted
                                    ? const Color(0xFFdcfce7) // 밝은 초록색 (완료)
                                    : const Color(0xFFfef2f2), // 밝은 빨간색 (미완료)
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: task.isCompleted
                                      ? const Color(0xFF22c55e) // 초록색 테두리
                                      : const Color(0xFFef4444), // 빨간색 테두리
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // 중요도 표시
                                  if (task.isImportant) ...[
                                    Icon(
                                      Icons.star,
                                      color: const Color(0xFFfbbf24),
                                      size: 20 * scaleFactor,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  // 일정 제목
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: TextStyle(
                                        color: const Color(0xFF1f2937),
                                        fontSize: 20 * scaleFactor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // 시간 표시
                                  Text(
                                    _formatTime(task.date),
                                    style: TextStyle(
                                      color: const Color(0xFF6b7280),
                                      fontSize: 18 * scaleFactor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
