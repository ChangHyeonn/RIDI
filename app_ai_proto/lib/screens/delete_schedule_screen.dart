import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/network_service.dart';
import '../providers/task_provider.dart';
import '../widgets/global_voice_button.dart';

class DeleteScheduleScreen extends StatefulWidget {
  final List<Task> schedules;
  final String searchCriteria;

  const DeleteScheduleScreen({
    Key? key,
    required this.schedules,
    required this.searchCriteria,
  }) : super(key: key);

  @override
  _DeleteScheduleScreenState createState() => _DeleteScheduleScreenState();
}

class _DeleteScheduleScreenState extends State<DeleteScheduleScreen> {
  final TaskService _taskService = TaskService();

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
                          '삭제할 일정',
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
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '삭제할 일정이 없습니다',
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
=======
            blurRadius: 12,
            offset: const Offset(0, 4),
>>>>>>> app_ai
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
<<<<<<< HEAD
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDeleteConfirmation(task),
=======
          onTap: () => _showDeleteConfirmation(task),
          borderRadius: BorderRadius.circular(16),
>>>>>>> app_ai
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
<<<<<<< HEAD
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
=======
                // 일정 정보
>>>>>>> app_ai
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
<<<<<<< HEAD
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
=======
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
>>>>>>> app_ai
                    ],
                  ),
                ),
                // 삭제 버튼
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFef4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFef4444),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
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

  void _showDeleteConfirmation(Task task) {
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
                  color: const Color(0xFFef4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFef4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '일정 삭제',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '${task.title} 일정을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '취소',
                style: TextStyle(
                  color: Color(0xFF6b7280),
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTask(task);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFef4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '삭제',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTask(Task task) async {
    try {
      // 즉시 UI에서 제거 (사용자 경험 개선)
      setState(() {
        widget.schedules.remove(task);
      });

      // 성공 메시지 즉시 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('${task.title} 일정을 삭제했습니다.'),
              ],
            ),
            backgroundColor: const Color(0xFF10b981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }

      // TaskProvider를 통해 최적화된 삭제 수행
      final taskProvider = context.read<TaskProvider>();
      await taskProvider.deleteTask(task.id);
      print('✅ TaskProvider를 통한 최적화된 삭제 완료: ${task.id}');

      // 모든 일정이 삭제되면 이전 화면으로 돌아가기
      if (widget.schedules.isEmpty) {
        Navigator.of(context).pop();
      }

      // 백그라운드에서 서버 동기화 (사용자 경험 개선)
      _syncWithServerInBackground(task.id);
    } catch (e) {
      print('❌ 일정 삭제 실패: $e');
      
      // 실패 시 목록에 다시 추가
      setState(() {
        if (!widget.schedules.contains(task)) {
          widget.schedules.add(task);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('일정 삭제에 실패했습니다. 다시 시도해주세요.'),
              ],
            ),
            backgroundColor: const Color(0xFFef4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  // 백그라운드에서 서버 동기화
  Future<void> _syncWithServerInBackground(String taskId) async {
    try {
      print('🔄 백그라운드 서버 동기화 시작: $taskId');
      await NetworkService.deleteScheduleFromServer(taskId, 'user123');
      print('✅ 백그라운드 서버 동기화 완료: $taskId');
    } catch (e) {
      print('⚠️ 백그라운드 서버 동기화 실패: $e');
      // 실패해도 사용자에게는 알리지 않음 (이미 로컬에서 삭제됨)
    }
  }
}
