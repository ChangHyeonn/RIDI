import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'date_detail_screen.dart';
import 'add_task_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _showImportantOnly = false; // 중요 일정만 보기 상태

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().initialize();
    });
  }

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // 일정 중요도 토글 함수
  void _toggleTaskImportance(BuildContext context, Task task) {
    final updatedTask = task.copyWith(isImportant: !task.isImportant);
    context.read<TaskProvider>().updateTask(updatedTask);
  }

  // 일정 수정 함수
  void _editTask(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(
          selectedDate: task.date,
          editingTask: task,
        ),
      ),
    );
  }

  // 일정 삭제 확인 다이얼로그
  Future<void> _showDeleteConfirmDialog(BuildContext context, Task task) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('일정 삭제'),
          content: Text('정말로 "${task.title}" 일정을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                context.read<TaskProvider>().deleteTask(task.id);
                Navigator.of(context).pop();
              },
              child: const Text(
                '삭제',
                style: TextStyle(color: Colors.red),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            if (taskProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final todayTasks = taskProvider.getTodayTasks();
            final tomorrowTasks = taskProvider.getTomorrowTasks();
            final isTodayCompleted = taskProvider.isTodayCompleted;
            final isTomorrowCompleted = taskProvider.isTomorrowCompleted;

            // 중요 일정만 보기 필터링 및 시간 순서대로 정렬
            final filteredTodayTasks = (_showImportantOnly 
                ? todayTasks.where((task) => task.isImportant).toList()
                : todayTasks)
                ..sort((a, b) => a.date.compareTo(b.date));
            final filteredTomorrowTasks = (_showImportantOnly 
                ? tomorrowTasks.where((task) => task.isImportant).toList()
                : tomorrowTasks)
                ..sort((a, b) => a.date.compareTo(b.date));

            final fontSize = taskProvider.fontSize;
            // fontSize가 null이거나 NaN일 때 기본값 사용
            final safeFontSize = fontSize.isNaN || fontSize.isInfinite ? 0.5 : fontSize;
            final today = DateTime.now();
            final tomorrow = today.add(const Duration(days: 1));

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 중요 버튼 (가장 좌측)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showImportantOnly = !_showImportantOnly;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _showImportantOnly ? Colors.orange : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _showImportantOnly ? Colors.orange : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: _showImportantOnly ? Colors.white : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '중요',
                                style: TextStyle(
                                  color: _showImportantOnly ? Colors.white : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 상단 두 개의 패널 (크기 증가)
                  Row(
                    children: [
                      // 오늘 패널
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DateDetailScreen(
                                  date: DateTime.now(),
                                  title: '오늘',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 300, // 높이 증가 (250 -> 300)
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '오늘',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20 * (0.5 + safeFontSize),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '- ${_formatDate(today)}',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16 * (0.5 + safeFontSize),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    // 중요표시 개수 - 항상 보이지만 중요 일정이 있을 때만 노란색
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: todayTasks.where((task) => task.isImportant).isNotEmpty
                                            ? Colors.orange.withOpacity(0.9)
                                            : Colors.grey.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: todayTasks.where((task) => task.isImportant).isNotEmpty
                                              ? Colors.orange
                                              : Colors.grey,
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: todayTasks.where((task) => task.isImportant).isNotEmpty
                                                ? Colors.white
                                                : Colors.grey,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${todayTasks.where((task) => task.isImportant).length}',
                                            style: TextStyle(
                                              color: todayTasks.where((task) => task.isImportant).isNotEmpty
                                                  ? Colors.white
                                                  : Colors.grey,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12 * (0.5 + safeFontSize)),
                                if (filteredTodayTasks.isEmpty)
                                  Text(
                                    _showImportantOnly ? '중요한 일정이 없습니다' : '일정이 없습니다',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14 * (0.5 + safeFontSize),
                                    ),
                                  )
                                else
                                  ...filteredTodayTasks
                                      .take(3)
                                      .map(
                                        (task) => Padding(
                                          // 더 많은 일정 표시
                                          padding: EdgeInsets.only(
                                            bottom: 8 * (0.5 + safeFontSize),
                                          ),
                                          child: GestureDetector(
                                            onTap: () => _editTask(context, task),
                                            child: Container(
                                              padding: EdgeInsets.all(
                                                8 * (0.5 + safeFontSize),
                                              ),
                                              decoration: BoxDecoration(
                                                color: task.isCompleted ? Colors.green[100] : Colors.red[100],
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: task.isCompleted ? Colors.green : Colors.red,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  // 별표시 (터치 가능)
                                                  GestureDetector(
                                                    onTap: () => _toggleTaskImportance(context, task),
                                                    child: Icon(
                                                      task.isImportant ? Icons.star : Icons.star_border,
                                                      color: task.isImportant ? Colors.orange : Colors.grey,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // 제목과 시간
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          task.title,
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 14 * (0.5 + safeFontSize),
                                                            fontWeight: FontWeight.normal,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        Text(
                                                          _formatTime(task.date),
                                                          style: TextStyle(
                                                            color: Colors.grey[600],
                                                            fontSize: 12 * (0.5 + safeFontSize),
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // 삭제 버튼 (- 표시)
                                                  GestureDetector(
                                                    onTap: () => _showDeleteConfirmDialog(context, task),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Icon(
                                                        Icons.remove,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 내일 패널
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DateDetailScreen(
                                  date: DateTime.now().add(
                                    const Duration(days: 1),
                                  ),
                                  title: '내일',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 300, // 높이 증가 (250 -> 300)
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '내일',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20 * (0.5 + safeFontSize),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '- ${_formatDate(tomorrow)}',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16 * (0.5 + safeFontSize),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    // 중요표시 개수 - 항상 보이지만 중요 일정이 있을 때만 노란색
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: tomorrowTasks.where((task) => task.isImportant).isNotEmpty
                                            ? Colors.orange.withOpacity(0.9)
                                            : Colors.grey.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: tomorrowTasks.where((task) => task.isImportant).isNotEmpty
                                              ? Colors.orange
                                              : Colors.grey,
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: tomorrowTasks.where((task) => task.isImportant).isNotEmpty
                                                ? Colors.white
                                                : Colors.grey,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${tomorrowTasks.where((task) => task.isImportant).length}',
                                            style: TextStyle(
                                              color: tomorrowTasks.where((task) => task.isImportant).isNotEmpty
                                                  ? Colors.white
                                                  : Colors.grey,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12 * (0.5 + safeFontSize)),
                                if (filteredTomorrowTasks.isEmpty)
                                  Text(
                                    _showImportantOnly ? '중요한 일정이 없습니다' : '일정이 없습니다',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14 * (0.5 + safeFontSize),
                                    ),
                                  )
                                else
                                  ...filteredTomorrowTasks
                                      .take(3)
                                      .map(
                                        (task) => Padding(
                                          // 더 많은 일정 표시
                                          padding: EdgeInsets.only(
                                            bottom: 8 * (0.5 + safeFontSize),
                                          ),
                                          child: GestureDetector(
                                            onTap: () => _editTask(context, task),
                                            child: Container(
                                              padding: EdgeInsets.all(
                                                8 * (0.5 + safeFontSize),
                                              ),
                                              decoration: BoxDecoration(
                                                color: task.isCompleted ? Colors.green[100] : Colors.red[100],
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: task.isCompleted ? Colors.green : Colors.red,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  // 별표시 (터치 가능)
                                                  GestureDetector(
                                                    onTap: () => _toggleTaskImportance(context, task),
                                                    child: Icon(
                                                      task.isImportant ? Icons.star : Icons.star_border,
                                                      color: task.isImportant ? Colors.orange : Colors.grey,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // 제목과 시간
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          task.title,
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 14 * (0.5 + safeFontSize),
                                                            fontWeight: FontWeight.normal,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        Text(
                                                          _formatTime(task.date),
                                                          style: TextStyle(
                                                            color: Colors.grey[600],
                                                            fontSize: 12 * (0.5 + safeFontSize),
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // 삭제 버튼 (- 표시)
                                                  GestureDetector(
                                                    onTap: () => _showDeleteConfirmDialog(context, task),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Icon(
                                                        Icons.remove,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24 * (0.5 + safeFontSize)),

                  // 일정 더보기 영역 (Expanded로 변경하여 남은 공간 모두 차지)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CalendarScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.white,
                                  size: 48 * (0.5 + safeFontSize),
                                ),
                                SizedBox(height: 16 * (0.5 + safeFontSize)),
                                Text(
                                  '일정 더보기',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24 * (0.5 + safeFontSize),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8 * (0.5 + safeFontSize)),
                                Text(
                                  '전체 일정을 확인하세요',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 16 * (0.5 + safeFontSize),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24 * (0.5 + safeFontSize)),

                  // 하단 버튼들 (아이콘으로 변경)
                  Row(
                    children: [
                      // 녹음 버튼 (아이콘으로 변경)
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.mic, color: Colors.white, size: 28),
                                SizedBox(width: 8),
                                Text(
                                  '녹음',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // 설정 버튼 (아이콘 유지)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.settings,
                                    size: 28,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '설정',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
