import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../providers/task_provider.dart';
=======
import '../models/task.dart';
>>>>>>> app_ai
import '../widgets/global_voice_button.dart';

class ScheduleListScreen extends StatefulWidget {
  final List<Task> schedules;
  final String searchCriteria;
<<<<<<< HEAD
  final String? searchKeyword;
  final Map<String, dynamic>? groupedSchedules;
  final int? totalCount;
  final Map<String, dynamic>? dateRange;
=======
>>>>>>> app_ai

  const ScheduleListScreen({
    Key? key,
    required this.schedules,
    required this.searchCriteria,
<<<<<<< HEAD
    this.searchKeyword,
    this.groupedSchedules,
    this.totalCount,
    this.dateRange,
=======
>>>>>>> app_ai
  }) : super(key: key);

  @override
  _ScheduleListScreenState createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
<<<<<<< HEAD
  final TaskService _taskService = TaskService();

=======
>>>>>>> app_ai
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfafafa),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더 영역
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF6366f1),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
<<<<<<< HEAD
                          '일정 조회',
=======
                          '일정 목록',
>>>>>>> app_ai
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '검색어: ${widget.searchCriteria}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366f1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.schedules.length}개',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
<<<<<<< HEAD
            // 일정 목록
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView.builder(
                  itemCount: widget.schedules.length,
                  itemBuilder: (context, index) {
                    final task = widget.schedules[index];
                    return _buildScheduleCard(task);
                  },
                ),
              ),
=======

            // 일정 목록
            Expanded(
              child: widget.schedules.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_note,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '검색된 일정이 없습니다',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: widget.schedules.length,
                      itemBuilder: (context, index) {
                        final task = widget.schedules[index];
                        return _buildTaskCard(task);
                      },
                    ),
>>>>>>> app_ai
            ),
          ],
        ),
      ),
      floatingActionButton: const GlobalVoiceButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

<<<<<<< HEAD
  Widget _buildScheduleCard(Task task) {
=======
  Widget _buildTaskCard(Task task) {
>>>>>>> app_ai
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
<<<<<<< HEAD
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showTaskDetails(task),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 아이콘 영역
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: task.isRecurring 
                        ? const Color(0xFFf97316).withOpacity(0.1)
                        : const Color(0xFF6366f1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    task.isRecurring ? Icons.repeat : Icons.event,
                    color: task.isRecurring 
                        ? const Color(0xFFf97316)
                        : const Color(0xFF6366f1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                // 텍스트 영역
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTaskDateTime(task),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6b7280),
                        ),
                      ),
                      if (task.isRecurring) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFf97316).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '반복 일정',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFf97316),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      if (task.isImportant) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
=======
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 일정 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (task.isImportant)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
>>>>>>> app_ai
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFef4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '중요',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFef4444),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
<<<<<<< HEAD
                      ],
                    ],
                  ),
                ),
                // 상세보기 버튼
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366f1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF6366f1),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
=======
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTaskDateTime(task),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (task.isRecurring) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFf97316).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '반복 일정',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFf97316),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // 완료 상태 표시
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: task.isCompleted 
                    ? const Color(0xFF10b981).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: task.isCompleted ? const Color(0xFF10b981) : Colors.grey,
                size: 20,
              ),
            ),
          ],
>>>>>>> app_ai
        ),
      ),
    );
  }

  String _formatTaskDateTime(Task task) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
    
    // 시간이 기본값(정오)인지 확인
    final isDefaultTime = task.date.hour == 12 && task.date.minute == 0;
    
    // 날짜 표시
    String dateText;
    if (taskDate == today) {
      dateText = '오늘';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      dateText = '내일';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      dateText = '어제';
    } else {
      dateText = '${task.date.month}월 ${task.date.day}일';
    }
    
    // 시간 표시 (기본값이 아닌 경우에만)
    if (isDefaultTime) {
      return dateText;
    } else {
      return '$dateText ${task.date.hour.toString().padLeft(2, '0')}:${task.date.minute.toString().padLeft(2, '0')}';
    }
  }
<<<<<<< HEAD

  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366f1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF6366f1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '일정 상세',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '제목: ${task.title}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '날짜: ${_formatTaskDateTime(task)}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '카테고리: ${task.category}',
                style: const TextStyle(fontSize: 16),
              ),
              if (task.isRecurring) ...[
                const SizedBox(height: 8),
                Text(
                  '반복: 반복 일정',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFf97316),
                  ),
                ),
              ],
              if (task.isImportant) ...[
                const SizedBox(height: 8),
                Text(
                  '중요도: 중요',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFef4444),
                  ),
                ),
              ],
              if (task.isCompleted) ...[
                const SizedBox(height: 8),
                Text(
                  '상태: 완료됨',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF10b981),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '닫기',
                style: TextStyle(
                  color: Color(0xFF6b7280),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
=======
>>>>>>> app_ai
}
