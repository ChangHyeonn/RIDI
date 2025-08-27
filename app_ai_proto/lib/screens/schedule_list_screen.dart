import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/global_voice_button.dart';

class ScheduleListScreen extends StatefulWidget {
  final List<Task>? schedules; // 호환용(더 이상 사용 권장 X)
  final String? searchCriteria; // 호환용(텍스트)
  final String? searchKeyword; // 미사용 시 null
  final Map<String, dynamic>? groupedSchedules; // 미사용 시 null
  final int? totalCount; // 미사용 시 null
  final Map<String, dynamic>? dateRange; // 미사용 시 null

  const ScheduleListScreen({
    Key? key,
    this.schedules,
    this.searchCriteria,
    this.searchKeyword,
    this.groupedSchedules,
    this.totalCount,
    this.dateRange,
  }) : super(key: key);

  @override
  _ScheduleListScreenState createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfafafa),
      body: SafeArea(
        child: Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            // 필터 기준: 기존 호환 파라미터들에서 키워드/기간 등을 읽어 필터링
            final keyword = widget.searchKeyword ?? widget.searchCriteria ?? '';
            final dateRange = widget.dateRange;

            Iterable<Task> base = taskProvider.tasks;
            if (keyword.isNotEmpty) {
              final k = keyword.trim();
              base = base.where(
                (t) =>
                    t.title.contains(k) ||
                    (t.category).toString().contains(k) ||
                    (t.recurrence != null && '반복'.contains(k)),
              );
            }
            if (dateRange != null &&
                dateRange['start'] != null &&
                dateRange['end'] != null) {
              try {
                final start = DateTime.parse(dateRange['start'].toString());
                final end = DateTime.parse(dateRange['end'].toString());
                base = base.where(
                  (t) => !t.date.isBefore(start) && !t.date.isAfter(end),
                );
              } catch (_) {}
            }

            final schedules = base.toList()
              ..sort((a, b) => a.date.compareTo(b.date));

            return Column(
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
                              '일정 조회',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              keyword.isNotEmpty ? '검색어: $keyword' : '전체 일정',
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
                          '${schedules.length}개',
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
                // 일정 목록
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: schedules.isEmpty
                        ? Center(
                            child: Text(
                              '검색 결과가 없습니다',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        : ListView.builder(
                            itemCount: schedules.length,
                            itemBuilder: (context, index) {
                              final task = schedules[index];
                              return _buildScheduleCard(task);
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: const GlobalVoiceButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildScheduleCard(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                style: TextStyle(color: Color(0xFF6b7280), fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }
}
