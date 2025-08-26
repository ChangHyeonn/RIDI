import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../constants/categories.dart';
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

  // 반복 일정 타입 표시
  String _getRecurrenceText(Task task) {
    if (!task.isRecurring || task.recurrence == null) {
      return '';
    }

    switch (task.recurrence!.type) {
      case 'daily':
        return '매일';
      case 'weekdays':
        return '평일';
      case 'weekends':
        return '주말';
      case 'custom_days':
        // 특정 요일인 경우 요일 정보 표시
        if (task.recurrence!.daysOfWeek != null &&
            task.recurrence!.daysOfWeek!.isNotEmpty) {
          final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
          final selectedDays = task.recurrence!.daysOfWeek!
              .map((day) => dayNames[day])
              .join(', ');
          return '매주 $selectedDays';
        }
        return '특정 요일';
      default:
        return '반복';
    }
  }

  // 삭제 확인 다이얼로그 표시
  void _showDeleteConfirmation(BuildContext context, Task task, double scaleFactor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '일정 삭제',
            style: TextStyle(
              fontSize: 18 * scaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '이 일정을 정말로 삭제하시겠습니까?\n삭제된 일정은 복구할 수 없습니다.',
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
                '취소',
                style: TextStyle(
                  fontSize: 16 * scaleFactor,
                  color: const Color(0xFF6b7280),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Provider.of<TaskProvider>(context, listen: false).deleteTask(task.id);
                Navigator.of(context).pop();
              },
              child: Text(
                '삭제',
                style: TextStyle(
                  fontSize: 16 * scaleFactor,
                  color: const Color(0xFFef4444),
                ),
              ),
            ),
          ],
        );
      },
    );
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

                      // 미완료 먼저(시간 오름차순) → 완료(시간 오름차순)
                      tasks.sort((a, b) {
                        final aDone = a.isRecurring
                            ? taskProvider.isOccurrenceCompleted(
                                a.id,
                                widget.date,
                              )
                            : a.isCompleted;
                        final bDone = b.isRecurring
                            ? taskProvider.isOccurrenceCompleted(
                                b.id,
                                widget.date,
                              )
                            : b.isCompleted;
                        if (aDone != bDone) return aDone ? 1 : -1;
                        return a.date.compareTo(b.date);
                      });

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
                              // 반복 일정은 날짜별 화면에서 개별 수정 금지
                              if (task.isRecurring) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(
                                        '반복 일정',
                                        style: TextStyle(
                                          fontSize: 18 * scaleFactor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: Text(
                                        '반복 일정은 날짜별 화면에서 수정할 수 없습니다.\n반복 일정 관리 화면에서 수정해주세요.',
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
                                return;
                              }

                              // 완료된 일정은 수정 금지 (반복 일정은 날짜별 완료 기준)
                              final isDone = task.isRecurring
                                  ? taskProvider.isOccurrenceCompleted(
                                      task.id,
                                      widget.date,
                                    )
                                  : task.isCompleted;
                              if (isDone) {
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
                                return;
                              }

                              // 그 외에는 수정 화면으로 이동
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
                                color:
                                    ((task.isRecurring
                                        ? taskProvider.isOccurrenceCompleted(
                                            task.id,
                                            widget.date,
                                          )
                                        : task.isCompleted))
                                    ? const Color(0xFFdcfce7) // 밝은 초록색 (완료)
                                    : const Color(0xFFfef2f2), // 밝은 빨간색 (미완료)
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      ((task.isRecurring
                                          ? taskProvider.isOccurrenceCompleted(
                                              task.id,
                                              widget.date,
                                            )
                                          : task.isCompleted))
                                      ? const Color(0xFF22c55e) // 초록색 테두리
                                      : const Color(0xFFef4444), // 빨간색 테두리
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // 카테고리/반복 표시 배지
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: task.isRecurring
                                          ? const Color(0xFF6366F1)
                                          : Color(
                                              TaskCategories.getCategoryColor(
                                                task.category,
                                              ),
                                            ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (task.isRecurring) ...[
                                          Text(
                                            '🔄',
                                            style: TextStyle(
                                              fontSize: 14 * scaleFactor,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '반복',
                                            style: TextStyle(
                                              fontSize: 12 * scaleFactor,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ] else ...[
                                          Text(
                                            TaskCategories.getCategoryIcon(
                                              task.category,
                                            ),
                                            style: TextStyle(
                                              fontSize: 14 * scaleFactor,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            TaskCategories.getCategoryInfo(
                                                  task.category,
                                                )?['name'] ??
                                                task.category,
                                            style: TextStyle(
                                              fontSize: 12 * scaleFactor,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // 일정 제목
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.title,
                                          style: TextStyle(
                                            color: const Color(0xFF1f2937),
                                            fontSize: 20 * scaleFactor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            // 중요도 표시 (반복 일정은 표시하지 않음)
                                            if (!task.isRecurring &&
                                                task.isImportant) ...[
                                              Icon(
                                                Icons.star,
                                                color: const Color(0xFFfbbf24),
                                                size: 16 * scaleFactor,
                                              ),
                                              const SizedBox(width: 4),
                                            ],
                                            // 시간 표시
                                            Text(
                                              _formatTime(task.date),
                                              style: TextStyle(
                                                color: const Color(0xFF6b7280),
                                                fontSize: 14 * scaleFactor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            // 반복 일정 타입 표시
                                            if (task.isRecurring) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                _getRecurrenceText(task),
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFF6366f1,
                                                  ),
                                                  fontSize: 12 * scaleFactor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 삭제 버튼
                                  IconButton(
                                    onPressed: () {
                                      _showDeleteConfirmation(context, task, scaleFactor);
                                    },
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: const Color(0xFFef4444),
                                      size: 24 * scaleFactor,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFFfef2f2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
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
