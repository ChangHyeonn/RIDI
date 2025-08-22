import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../constants/categories.dart';
import '../constants/recurring_task_constants.dart';
import '../services/recurring_task_service.dart';

class RecurrenceManagementScreen extends StatefulWidget {
  final String? initialTitle;
  final TimeOfDay? initialTime;
  final List<TimeOfDay>? initialAdditionalTimes;
  final List<bool>? initialSelectedDays;
  final DateTime? initialEndDate;
  final bool isEditing;
  final Map<String, dynamic>? editingTaskPattern;
  final String? editingSignature;

  const RecurrenceManagementScreen({
    super.key,
    this.initialTitle,
    this.initialTime,
    this.initialAdditionalTimes,
    this.initialSelectedDays,
    this.initialEndDate,
    this.isEditing = false,
    this.editingTaskPattern,
    this.editingSignature,
  });

  @override
  State<RecurrenceManagementScreen> createState() =>
      _RecurrenceManagementScreenState();
}

class _RecurrenceManagementScreenState
    extends State<RecurrenceManagementScreen> {
  late DateTime _endDate;
  late List<bool> _selectedDays;
  late TimeOfDay _selectedTime;
  late List<TimeOfDay> _additionalTimes;
  late String _title;
  late String _selectedCategory;
  late bool _isImportant;

  // Controllers
  final _titleController = TextEditingController();
  final _yearController = TextEditingController();
  final _monthController = TextEditingController();
  final _dayController = TextEditingController();
  final _hourController = TextEditingController();
  final _minuteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeValues();
    _initializeControllers();
  }

  void _initializeValues() {
    _selectedTime = widget.initialTime ?? RecurringTaskConstants.defaultTime;
    _additionalTimes = widget.initialAdditionalTimes ?? [];
    _title = widget.initialTitle ?? '반복 일정';
    _selectedCategory = TaskCategories.general;
    _isImportant = false;
    // 기본 종료일을 오늘로 설정
    _endDate = widget.initialEndDate ?? DateTime.now();

    if (widget.isEditing) {
      _selectedDays = widget.initialSelectedDays ?? List.filled(7, false);
    } else {
      _selectedDays = List.filled(7, false);
    }
  }

  void _initializeControllers() {
    _titleController.text = _title;
    _yearController.text = _endDate.year.toString();
    _monthController.text = _endDate.month.toString().padLeft(2, '0');
    _dayController.text = _endDate.day.toString().padLeft(2, '0');
    _hourController.text = _selectedTime.hour.toString().padLeft(2, '0');
    _minuteController.text = _selectedTime.minute.toString().padLeft(2, '0');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildTitleInput(scaleFactor),
                      const SizedBox(height: 24),
                      _buildRecurrenceSettingsPanel(scaleFactor),
                    ],
                  ),
                ),
              ),
              _buildBottomButtons(scaleFactor),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('반복일정 설정'),
      backgroundColor: RecurringTaskConstants.cardColor,
      foregroundColor: RecurringTaskConstants.textPrimaryColor,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
    );
  }

  Widget _buildTitleInput(double scaleFactor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '제목',
          style: TextStyle(
            fontSize: 16 * scaleFactor,
            fontWeight: FontWeight.w600,
            color: RecurringTaskConstants.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: '반복 일정 제목을 입력하세요',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                RecurringTaskConstants.inputBorderRadius,
              ),
              borderSide: const BorderSide(
                color: RecurringTaskConstants.borderColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                RecurringTaskConstants.inputBorderRadius,
              ),
              borderSide: const BorderSide(
                color: RecurringTaskConstants.borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                RecurringTaskConstants.inputBorderRadius,
              ),
              borderSide: const BorderSide(
                color: RecurringTaskConstants.primaryColor,
              ),
            ),
            filled: true,
            fillColor: RecurringTaskConstants.cardColor,
          ),
          onChanged: (value) {
            setState(() {
              _title = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildRecurrenceSettingsPanel(double scaleFactor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RecurringTaskConstants.cardColor,
        borderRadius: BorderRadius.circular(
          RecurringTaskConstants.inputBorderRadius,
        ),
        // 테두리 제거
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 제목 제거
          _buildDateSection(),
          const SizedBox(height: 16),
          _buildWeekdaySelector(),
          const SizedBox(height: 20),
          _buildTimeSection(),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '요일 및 기간',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: RecurringTaskConstants.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '종료일',
          style: TextStyle(
            fontSize: 14,
            color: RecurringTaskConstants.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildDateField(
              '년',
              _yearController,
              () => _showYearPicker(context),
            ),
            const SizedBox(width: 8),
            _buildDateField(
              '월',
              _monthController,
              () => _showMonthPicker(context),
            ),
            const SizedBox(width: 8),
            _buildDateField('일', _dayController, () => _showDayPicker(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    TextEditingController controller,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: RecurringTaskConstants.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: RecurringTaskConstants.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: RecurringTaskConstants.borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: RecurringTaskConstants.textPrimaryColor,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdaySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: RecurringTaskConstants.dayNames.asMap().entries.map((entry) {
        final index = entry.key;
        final dayName = entry.value;
        final isSelected = _selectedDays[index];

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDays[index] = !isSelected;
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? RecurringTaskConstants.primaryColor
                  : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                dayName,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainTimeSelector(),
        const SizedBox(height: 16),
        _buildAddTimeButton(),
        if (_additionalTimes.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildAdditionalTimesList(),
        ],
      ],
    );
  }

  Widget _buildMainTimeSelector() {
    return Row(
      children: [
        const Text(
          '기본 시간: ',
          style: TextStyle(
            fontSize: 14,
            color: RecurringTaskConstants.textSecondaryColor,
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _showTimePicker(context, isMainTime: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: RecurringTaskConstants.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      RecurringTaskConstants.formatTime12Hour(_selectedTime),
                      style: const TextStyle(
                        fontSize: 14,
                        color: RecurringTaskConstants.textPrimaryColor,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddTimeButton() {
    return GestureDetector(
      onTap: () {
        // 중복 방지: 기존 메인/추가 시간과 겹치지 않는 시간만 추가
        final existing = <String>{
          '${_selectedTime.hour}:${_selectedTime.minute}',
          ..._additionalTimes.map((t) => '${t.hour}:${t.minute}'),
        };
        TimeOfDay candidate = TimeOfDay(
          hour: (_selectedTime.hour + 1) % 24,
          minute: _selectedTime.minute,
        );
        bool added = false;
        for (int i = 0; i < 24; i++) {
          final key = '${candidate.hour}:${candidate.minute}';
          if (!existing.contains(key)) {
            setState(() {
              _additionalTimes.add(candidate);
            });
            added = true;
            break;
          }
          candidate = TimeOfDay(
            hour: (candidate.hour + 1) % 24,
            minute: candidate.minute,
          );
        }
        if (!added) {
          _showErrorMessage(context, '이미 24시간이 모두 추가되어 있습니다');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: RecurringTaskConstants.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: RecurringTaskConstants.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: RecurringTaskConstants.primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              '시간 추가하기',
              style: TextStyle(
                fontSize: 14,
                color: RecurringTaskConstants.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalTimesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '추가 시간',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: RecurringTaskConstants.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        ..._additionalTimes.asMap().entries.map((entry) {
          final index = entry.key;
          final time = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showTimePicker(context, index: index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: RecurringTaskConstants.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: RecurringTaskConstants.borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              RecurringTaskConstants.formatTime12Hour(time),
                              style: const TextStyle(
                                fontSize: 14,
                                color: RecurringTaskConstants.textPrimaryColor,
                              ),
                            ),
                          ),
                          const Icon(Icons.edit, color: Colors.grey, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _additionalTimes.removeAt(index);
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomButtons(double scaleFactor) {
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
      child: Row(
        children: [
          if (widget.isEditing) ...[
            Expanded(
              child: ElevatedButton(
                onPressed: () => _confirmDelete(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD35445),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      RecurringTaskConstants.inputBorderRadius,
                    ),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '삭제',
                  style: TextStyle(
                    fontSize: 18 * scaleFactor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          if (!widget.isEditing) ...[
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RecurringTaskConstants.cardColor,
                  foregroundColor: RecurringTaskConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      RecurringTaskConstants.inputBorderRadius,
                    ),
                  ),
                  elevation: 0,
                  side: const BorderSide(
                    color: RecurringTaskConstants.primaryColor,
                  ),
                ),
                child: Text(
                  '취소',
                  style: TextStyle(
                    fontSize: 18 * scaleFactor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: () => _saveRecurrenceSchedule(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: RecurringTaskConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    RecurringTaskConstants.inputBorderRadius,
                  ),
                ),
                elevation: 0,
              ),
              child: Text(
                '반복 일정 저장',
                style: TextStyle(
                  fontSize: 18 * scaleFactor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('반복 일정 삭제'),
          content: const Text('정말로 이 반복 일정을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final taskProvider = context.read<TaskProvider>();
                await _performDeleteByPattern(taskProvider);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD35445),
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDeleteByPattern(TaskProvider taskProvider) async {
    final signature = widget.editingTaskPattern != null
        ? widget.editingTaskPattern!['signature'] as String?
        : null;
    final title = widget.editingTaskPattern != null
        ? widget.editingTaskPattern!['title'] as String
        : _title;
    final category = widget.editingTaskPattern != null
        ? widget.editingTaskPattern!['category'] as String
        : _selectedCategory;

    final tasks = RecurringTaskService.findRecurringTasksByPattern(
      taskProvider.tasks,
      title,
      category,
      signature: signature,
    );
    final ids = tasks.map((t) => t.id).toList();
    if (ids.isNotEmpty) {
      await taskProvider.deleteTasks(ids);
    }
  }

  void _saveRecurrenceSchedule(BuildContext context) {
    // 유효성 검사
    if (!_validateInput(context)) return;

    final taskProvider = context.read<TaskProvider>();

    // 편집 모드일 때 기존 반복일정 삭제
    if (widget.isEditing && widget.editingTaskPattern != null) {
      _applyDiffRecurringTasks(taskProvider, context);
    } else {
      _createNewRecurringTasks(taskProvider, context);
    }
  }

  Future<void> _createNewRecurringTasks(
    TaskProvider taskProvider,
    BuildContext context,
  ) async {
    try {
      // 새로운 반복 일정 생성
      final allTimes = _getAllTimes();
      final endDate = _getSelectedEndDate()!;

      debugPrint('🔄 반복 일정 생성 시작');
      debugPrint('  - 제목: $_title');
      debugPrint('  - 종료일: $endDate');
      debugPrint(
        '  - 시간들: ${allTimes.map((t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}').join(', ')}',
      );

      final newTasks = RecurringTaskService.generateRecurringTasks(
        title: _title,
        selectedDays: _selectedDays,
        times: allTimes,
        endDate: endDate,
        category: _selectedCategory,
        isImportant: _isImportant,
      );

      if (newTasks.isEmpty) {
        _showErrorMessage(context, '생성할 반복 일정이 없습니다. 설정을 확인해주세요.');
        return;
      }

      // 생성된 일정들을 일괄 추가 (저장/알람 경쟁 상태 방지)
      await taskProvider.addTasks(newTasks);

      debugPrint('✅ 반복 일정 생성 완료: ${newTasks.length}개');

      Navigator.pop(context);
      _showSuccessMessage(context);
      return;
    } catch (e) {
      debugPrint('❌ 반복 일정 생성 실패: $e');
      _showErrorMessage(context, '반복 일정 생성 중 오류가 발생했습니다.');
      return;
    }
  }

  // 기존 패턴과 신규 설정의 차이만 적용 (삭제/추가/업데이트 최소화)
  Future<void> _applyDiffRecurringTasks(
    TaskProvider taskProvider,
    BuildContext context,
  ) async {
    try {
      final originalSignature =
          widget.editingTaskPattern!['signature'] as String?;
      final title = widget.editingTaskPattern!['title'] as String;
      final category = widget.editingTaskPattern!['category'] as String;

      // 1) 기존 패턴 일정들 수집
      final existingTasks = RecurringTaskService.findRecurringTasksByPattern(
        taskProvider.tasks,
        title,
        category,
        signature: originalSignature,
      );

      // 2) 목표 타임라인 생성
      final allTimes = _getAllTimes();
      final endDate = _getSelectedEndDate()!;
      final targetTasks = RecurringTaskService.generateRecurringTasks(
        title: _title,
        selectedDays: _selectedDays,
        times: allTimes,
        endDate: endDate,
        category: _selectedCategory,
        isImportant: _isImportant,
      );

      // 신(목표) recurrence 메타 고정
      final RecurrenceInfo? newRecurrence = targetTasks.isNotEmpty
          ? targetTasks.first.recurrence
          : null;

      String key(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

      final existingMap = {for (final t in existingTasks) key(t.date): t};
      final targetMap = {for (final t in targetTasks) key(t.date): t};

      // 3) 업데이트(공통 교집합)
      for (final k in existingMap.keys) {
        if (targetMap.containsKey(k)) {
          final oldTask = existingMap[k]!;
          final updated = oldTask.copyWith(
            title: _title,
            isImportant: _isImportant,
            category: _selectedCategory,
            recurrence: newRecurrence ?? oldTask.recurrence,
          );
          await taskProvider.updateTask(updated);
        }
      }

      // 4) 삭제(기존 - 목표)
      final idsToDelete = <String>[];
      for (final k in existingMap.keys) {
        if (!targetMap.containsKey(k)) {
          idsToDelete.add(existingMap[k]!.id);
        }
      }
      if (idsToDelete.isNotEmpty) {
        await taskProvider.deleteTasks(idsToDelete);
      }

      // 5) 추가(목표 - 기존)
      final toAdd = <Task>[];
      for (final k in targetMap.keys) {
        if (!existingMap.containsKey(k)) {
          toAdd.add(targetMap[k]!);
        }
      }
      if (toAdd.isNotEmpty) {
        await taskProvider.addTasks(toAdd);
      }

      Navigator.pop(context);
      _showSuccessMessage(context);
    } catch (e) {
      debugPrint('❌ 반복 일정 diff 적용 실패: $e');
      _showErrorMessage(context, '반복 일정 수정 중 오류가 발생했습니다.');
    }
  }

  bool _validateInput(BuildContext context) {
    // 제목 검사
    if (!RecurringTaskService.isValidTitle(_titleController.text)) {
      _showErrorMessage(context, RecurringTaskConstants.errorEmptyTitle);
      return false;
    }

    // 종료일 검사
    final endDate = _getSelectedEndDate();
    if (endDate == null) {
      _showErrorMessage(context, RecurringTaskConstants.errorInvalidDate);
      return false;
    }

    if (!RecurringTaskService.isValidEndDate(endDate)) {
      _showErrorMessage(context, RecurringTaskConstants.errorPastEndDate);
      return false;
    }

    // 요일 선택 검사
    if (!RecurringTaskService.isValidDaySelection(_selectedDays)) {
      _showErrorMessage(context, RecurringTaskConstants.errorNoDaySelected);
      return false;
    }

    return true;
  }

  DateTime? _getSelectedEndDate() {
    return RecurringTaskService.parseDate(
      _yearController.text,
      _monthController.text,
      _dayController.text,
    );
  }

  List<TimeOfDay> _getAllTimes() {
    final allTimes = <TimeOfDay>[_selectedTime];
    for (final additionalTime in _additionalTimes) {
      if (!allTimes.any(
        (time) =>
            time.hour == additionalTime.hour &&
            time.minute == additionalTime.minute,
      )) {
        allTimes.add(additionalTime);
      }
    }
    return allTimes;
  }

  // 사용되지 않던 삭제 유틸은 제거되었습니다. 편집 모드 삭제는 _performDeleteByPattern 사용.

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessMessage(BuildContext context) {
    final message = widget.isEditing
        ? RecurringTaskConstants.successRecurrenceUpdated
        : RecurringTaskConstants.successRecurrenceCreated;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Date/Time Picker Methods
  int _parseOrDefault(String text, int fallback) {
    final v = int.tryParse(text);
    return v == null || v <= 0 ? fallback : v;
  }

  int _daysInMonth(int year, int month) {
    if (month == 12) return DateTime(year + 1, 1, 0).day;
    return DateTime(year, month + 1, 0).day;
  }

  void _updateEndDate({int? year, int? month, int? day}) {
    final y = year ?? _parseOrDefault(_yearController.text, _endDate.year);
    final m = month ?? _parseOrDefault(_monthController.text, _endDate.month);
    var d = day ?? _parseOrDefault(_dayController.text, _endDate.day);
    final maxDay = _daysInMonth(y, m);
    if (d > maxDay) d = maxDay;

    setState(() {
      _yearController.text = y.toString();
      _monthController.text = m.toString().padLeft(2, '0');
      _dayController.text = d.toString().padLeft(2, '0');
      _endDate = DateTime(y, m, d);
    });
  }

  void _showYearPicker(BuildContext context) {
    final years = List<int>.generate(2100 - 2020 + 1, (i) => 2020 + i);
    int tempYear = _parseOrDefault(_yearController.text, _endDate.year);
    final initialIndex = years.indexOf(tempYear).clamp(0, years.length - 1);

    showCupertinoModalPopup(
      context: context,
      builder: (_) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 50,
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('취소'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text('확인'),
                      onPressed: () {
                        _updateEndDate(year: tempYear);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex,
                  ),
                  onSelectedItemChanged: (idx) => tempYear = years[idx],
                  children: years
                      .map((y) => Center(child: Text('$y년')))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMonthPicker(BuildContext context) {
    final months = List<int>.generate(12, (i) => i + 1);
    int tempMonth = _parseOrDefault(_monthController.text, _endDate.month);
    final initialIndex = (tempMonth - 1).clamp(0, 11);

    showCupertinoModalPopup(
      context: context,
      builder: (_) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 50,
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('취소'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text('확인'),
                      onPressed: () {
                        _updateEndDate(month: tempMonth);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex,
                  ),
                  onSelectedItemChanged: (idx) => tempMonth = months[idx],
                  children: months
                      .map(
                        (m) => Center(
                          child: Text('${m.toString().padLeft(2, '0')}월'),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDayPicker(BuildContext context) {
    final year = _parseOrDefault(_yearController.text, _endDate.year);
    final month = _parseOrDefault(_monthController.text, _endDate.month);
    final maxDay = _daysInMonth(year, month);
    final days = List<int>.generate(maxDay, (i) => i + 1);

    int tempDay = _parseOrDefault(
      _dayController.text,
      _endDate.day,
    ).clamp(1, maxDay);
    final initialIndex = (tempDay - 1).clamp(0, maxDay - 1);

    showCupertinoModalPopup(
      context: context,
      builder: (_) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 50,
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('취소'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text('확인'),
                      onPressed: () {
                        _updateEndDate(day: tempDay);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex,
                  ),
                  onSelectedItemChanged: (idx) => tempDay = days[idx],
                  children: days
                      .map(
                        (d) => Center(
                          child: Text('${d.toString().padLeft(2, '0')}일'),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 사용하지 않음 (단일 컬럼 피커로 대체)
  // void _showDatePicker(BuildContext context, Function(DateTime) onDateChanged) {}

  void _showTimePicker(
    BuildContext context, {
    bool isMainTime = false,
    int? index,
  }) {
    TimeOfDay currentTime;
    if (isMainTime) {
      currentTime = _selectedTime;
    } else {
      currentTime = _additionalTimes[index!];
    }

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 50,
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('취소'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text('확인'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                    2024,
                    1,
                    1,
                    currentTime.hour,
                    currentTime.minute,
                  ),
                  onDateTimeChanged: (DateTime newDateTime) {
                    final newTime = TimeOfDay(
                      hour: newDateTime.hour,
                      minute: newDateTime.minute,
                    );

                    // 중복 검사
                    bool isDuplicate = false;
                    if (isMainTime) {
                      for (final t in _additionalTimes) {
                        if (t.hour == newTime.hour &&
                            t.minute == newTime.minute) {
                          isDuplicate = true;
                          break;
                        }
                      }
                    } else {
                      if (_selectedTime.hour == newTime.hour &&
                          _selectedTime.minute == newTime.minute) {
                        isDuplicate = true;
                      }
                      for (int i = 0; i < _additionalTimes.length; i++) {
                        if (i == index) continue;
                        final t = _additionalTimes[i];
                        if (t.hour == newTime.hour &&
                            t.minute == newTime.minute) {
                          isDuplicate = true;
                          break;
                        }
                      }
                    }

                    if (isDuplicate) {
                      _showErrorMessage(context, '이미 설정된 시간입니다');
                      return;
                    }

                    setState(() {
                      if (isMainTime) {
                        _selectedTime = newTime;
                      } else {
                        _additionalTimes[index!] = newTime;
                      }

                      _hourController.text = newDateTime.hour
                          .toString()
                          .padLeft(2, '0');
                      _minuteController.text = newDateTime.minute
                          .toString()
                          .padLeft(2, '0');
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
