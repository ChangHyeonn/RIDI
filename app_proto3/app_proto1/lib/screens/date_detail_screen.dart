import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class DateDetailScreen extends StatefulWidget {
  final DateTime date;
  final String title;

  const DateDetailScreen({
    super.key,
    required this.date,
    required this.title,
  });

  @override
  State<DateDetailScreen> createState() => _DateDetailScreenState();
}

class _DateDetailScreenState extends State<DateDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
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
                  const Expanded(
                    child: Text(
                      '날짜별화면',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // 뒤로가기 버튼과 균형 맞추기
                ],
              ),
            ),
            
            // 날짜 표시
            Text(
              '${widget.date.month}/${widget.date.day}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9C27B0),
              ),
            ),
            const SizedBox(height: 24),
            
            // 일정 목록
            Expanded(
              child: Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
                  final tasks = taskProvider.getTasksForDate(widget.date);
                  
                  if (tasks.isEmpty) {
                    return const Center(
                      child: Text(
                        '이 날짜에 등록된 일정이 없습니다.',
                        style: TextStyle(
                          fontSize: 16,
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
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1BEE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            // 일정 제목
                            Expanded(
                              child: Text(
                                task.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // 완료 상태 표시
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: task.isCompleted ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                task.isCompleted ? Icons.check : Icons.remove,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            
                            // 삭제 버튼
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('일정 삭제'),
                                    content: const Text('이 일정을 삭제하시겠습니까?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('취소'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          taskProvider.deleteTask(task.id);
                                          Navigator.pop(context);
                                        },
                                        child: const Text('삭제'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '삭제',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 