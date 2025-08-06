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
      backgroundColor: Colors.white,
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
                            color: Colors.grey,
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
                    color: const Color(0xFF9C27B0),
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
                              color: Colors.grey,
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
                              // 일정 박스 전체를 탭하면 일정 수정창으로 이동
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditTaskScreen(task: task),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: task.isCompleted
                                    ? const Color(0xFF4CAF50).withOpacity(
                                        0.8,
                                      ) // 초록색 (완료)
                                    : const Color(
                                        0xFFF44336,
                                      ).withOpacity(0.8), // 빨간색 (미완료)
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  // 중요도 표시
                                  if (task.isImportant) ...[
                                    Icon(
                                      Icons.star,
                                      color: const Color(0xFFFFD700),
                                      size: 20 * scaleFactor,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  // 일정 제목
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: TextStyle(
                                        color: Colors.white,
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
                                      color: Colors.white,
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
