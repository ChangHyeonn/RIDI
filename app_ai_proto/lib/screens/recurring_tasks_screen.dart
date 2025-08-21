import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../constants/recurring_task_constants.dart';
import '../services/recurring_task_service.dart';
import 'recurring_task_management_screen.dart';

class RecurringTasksScreen extends StatefulWidget {
  const RecurringTasksScreen({super.key});

  @override
  State<RecurringTasksScreen> createState() => _RecurringTasksScreenState();
}

class _RecurringTasksScreenState extends State<RecurringTasksScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecurringTaskConstants.backgroundColor,
      appBar: _buildAppBar(),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final fontSize = taskProvider.fontSize;
          final scaleFactor = 0.75 + (fontSize * 0.5);

          return Column(
            children: [
              Expanded(
                child: _buildRecurringTasksList(taskProvider, scaleFactor),
              ),
              _buildBottomButton(scaleFactor),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('반복 일정 관리'),
      backgroundColor: RecurringTaskConstants.cardColor,
      foregroundColor: RecurringTaskConstants.textPrimaryColor,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
    );
  }

  Widget _buildRecurringTasksList(
    TaskProvider taskProvider,
    double scaleFactor,
  ) {
    final groupedTasks = RecurringTaskService.groupRecurringTasks(
      taskProvider.tasks,
    );
    final uniquePatterns = groupedTasks.values.toList();

    if (uniquePatterns.isEmpty) {
      return _buildEmptyState(scaleFactor);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: uniquePatterns.length,
      itemBuilder: (context, index) {
        final taskGroup = uniquePatterns[index];
        final representativeTask = taskGroup.first;

        return _buildRecurringTaskCard(
          representativeTask,
          taskGroup,
          taskProvider,
          scaleFactor,
        );
      },
    );
  }

  Widget _buildEmptyState(double scaleFactor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.repeat, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '반복 일정이 없습니다',
            style: TextStyle(
              fontSize: 18 * scaleFactor,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '반복일정관리 버튼을 눌러\n새로운 반복 일정을 만들어보세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14 * scaleFactor,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringTaskCard(
    Task representativeTask,
    List<Task> taskGroup,
    TaskProvider taskProvider,
    double scaleFactor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: RecurringTaskConstants.cardColor,
        borderRadius: BorderRadius.circular(
          RecurringTaskConstants.cardBorderRadius,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaskHeader(representativeTask, taskGroup, scaleFactor),
            const SizedBox(height: 8),
            _buildTimeDisplay(taskGroup, scaleFactor),
            const SizedBox(height: 12),
            _buildActionButtons(representativeTask, taskProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHeader(
    Task representativeTask,
    List<Task> taskGroup,
    double scaleFactor,
  ) {
    return Row(
      children: [
        Icon(Icons.repeat, color: Colors.blue[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            representativeTask.title,
            style: TextStyle(
              fontSize: 16 * scaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildWeekdayIcons(taskGroup, scaleFactor),
      ],
    );
  }

  Widget _buildActionButtons(
    Task representativeTask,
    TaskProvider taskProvider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () => _editRecurringTask(representativeTask, taskProvider),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () =>
              _deleteRecurringTask(representativeTask, taskProvider),
        ),
      ],
    );
  }

  Widget _buildBottomButton(double scaleFactor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RecurringTaskConstants.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _navigateToManagementScreen(),
          icon: const Icon(Icons.settings, color: Colors.white),
          label: Text(
            '반복일정관리',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16 * scaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                RecurringTaskConstants.inputBorderRadius,
              ),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  void _navigateToManagementScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecurrenceManagementScreen(),
      ),
    );
  }

  Widget _buildWeekdayIcons(List<Task> taskGroup, double scaleFactor) {
    final weekdayStatus = RecurringTaskService.extractWeekdaysFromTasks(
      taskGroup,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: RecurringTaskConstants.dayNames.asMap().entries.map((entry) {
        final index = entry.key;
        final dayName = entry.value;
        final isActive = weekdayStatus[index];

        return Container(
          margin: const EdgeInsets.only(right: 2),
          width: RecurringTaskConstants.weekdayIconSize,
          height: RecurringTaskConstants.weekdayIconSize,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey[300],
            borderRadius: BorderRadius.circular(
              RecurringTaskConstants.weekdayIconSize / 2,
            ),
          ),
          child: Center(
            child: Text(
              dayName,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontSize: 10 * scaleFactor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeDisplay(List<Task> taskGroup, double scaleFactor) {
    final uniqueTimes = RecurringTaskService.extractTimesFromTasks(taskGroup);

    if (uniqueTimes.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedTimes = uniqueTimes.toList()..sort();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: sortedTimes.map((time) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Text(
            time,
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 12 * scaleFactor,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _editRecurringTask(Task task, TaskProvider taskProvider) {
    final signature = RecurringTaskService.buildPatternSignatureForTask(task);
    final allRecurringTasks = RecurringTaskService.findRecurringTasksByPattern(
      taskProvider.tasks,
      task.title,
      task.category,
      signature: signature,
    );

    // 시간 정보 추출
    final sortedTimes = RecurringTaskService.extractTimeOfDayFromTasks(
      allRecurringTasks,
    );
    final baseTime = sortedTimes.isNotEmpty
        ? sortedTimes.first
        : RecurringTaskConstants.defaultTime;
    final additionalTimes = sortedTimes.length > 1
        ? sortedTimes.sublist(1)
        : <TimeOfDay>[];

    // 요일 정보 추출
    final selectedDays = RecurringTaskService.extractWeekdaysFromTasks(
      allRecurringTasks,
    );

    // 종료일 추출
    final endDate =
        RecurringTaskService.extractEndDateFromTasks(allRecurringTasks) ??
        RecurringTaskConstants.defaultEndDate;

    // 편집 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecurrenceManagementScreen(
          initialTitle: task.title,
          initialTime: baseTime,
          initialAdditionalTimes: additionalTimes,
          initialSelectedDays: selectedDays,
          initialEndDate: endDate,
          isEditing: true,
          editingTaskPattern: {
            'title': task.title,
            'category': task.category,
            // 편집 시작 시점의 원본 패턴 시그니처 전달
            'signature': RecurringTaskService.buildPatternSignatureForTask(task),
          },
        ),
      ),
    );
  }

  void _deleteRecurringTask(Task task, TaskProvider taskProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('반복 일정 삭제'),
          content: Text('정말로 "${task.title}" 반복 일정을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                _performDelete(task, taskProvider);
                Navigator.of(context).pop();
                _showDeleteSuccessMessage();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDelete(Task task, TaskProvider taskProvider) async {
    debugPrint('🗑️ 반복 일정 삭제 시작: ${task.title}');

    final signature = RecurringTaskService.buildPatternSignatureForTask(task);
    final recurringTasks = RecurringTaskService.findRecurringTasksByPattern(
      taskProvider.tasks,
      task.title,
      task.category,
      signature: signature,
    );

    debugPrint('  - 삭제할 일정 개수: ${recurringTasks.length}');

    final idsToDelete = <String>[];
    for (final recurringTask in recurringTasks) {
      idsToDelete.add(recurringTask.id);
      debugPrint('  - 삭제 예정: ${recurringTask.date} (ID: ${recurringTask.id})');
    }

    // 추가 안전장치: 제목이 같은 모든 반복 일정 삭제
    final allSimilarTasks = taskProvider.tasks
        .where((t) => t.isRecurring && t.title == task.title)
        .toList();

    for (final similarTask in allSimilarTasks) {
      if (!recurringTasks.contains(similarTask)) {
        idsToDelete.add(similarTask.id);
        debugPrint('  - 추가 삭제 예정: ${similarTask.date} (ID: ${similarTask.id})');
      }
    }

    await taskProvider.deleteTasks(idsToDelete);

    debugPrint('✅ 반복 일정 삭제 완료');
  }

  void _showDeleteSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(RecurringTaskConstants.successRecurrenceDeleted),
      ),
    );
  }
}
