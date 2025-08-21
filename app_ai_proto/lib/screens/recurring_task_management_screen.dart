import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
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

  const RecurrenceManagementScreen({
    super.key,
    this.initialTitle,
    this.initialTime,
    this.initialAdditionalTimes,
    this.initialSelectedDays,
    this.initialEndDate,
    this.isEditing = false,
    this.editingTaskPattern,
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
    _endDate = widget.initialEndDate ?? RecurringTaskConstants.defaultEndDate;

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
        color: const Color(0xFFf8f9fa),
        borderRadius: BorderRadius.circular(
          RecurringTaskConstants.inputBorderRadius,
        ),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '반복일정',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: RecurringTaskConstants.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 20),
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
                border: Border.all(color: Colors.grey[300]!),
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
              color: isSelected ? Colors.blue : Colors.grey[200],
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
        setState(() {
          final newTime = TimeOfDay(
            hour: (_selectedTime.hour + 1) % 24,
            minute: _selectedTime.minute,
          );
          _additionalTimes.add(newTime);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: RecurringTaskConstants.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.blue,
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
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
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
        }).toList(),
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

  void _saveRecurrenceSchedule(BuildContext context) {
    // 유효성 검사
    if (!_validateInput(context)) return;

    final taskProvider = context.read<TaskProvider>();

    // 편집 모드일 때 기존 반복일정 삭제
    if (widget.isEditing && widget.editingTaskPattern != null) {
      _deleteExistingTasks(taskProvider);
      // 삭제 후 잠시 대기하여 상태 안정화
      Future.delayed(const Duration(milliseconds: 100), () {
        _createNewRecurringTasks(taskProvider, context);
      });
    } else {
      _createNewRecurringTasks(taskProvider, context);
    }
  }

  void _createNewRecurringTasks(
    TaskProvider taskProvider,
    BuildContext context,
  ) {
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

      // 생성된 일정들을 추가
      for (final task in newTasks) {
        taskProvider.addTask(task);
      }

      debugPrint('✅ 반복 일정 생성 완료: ${newTasks.length}개');

      Navigator.pop(context);
      _showSuccessMessage(context);
    } catch (e) {
      debugPrint('❌ 반복 일정 생성 실패: $e');
      _showErrorMessage(context, '반복 일정 생성 중 오류가 발생했습니다.');
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

  void _deleteExistingTasks(TaskProvider taskProvider) {
    final title = widget.editingTaskPattern!['title'];
    final category = widget.editingTaskPattern!['category'];

    debugPrint('🗑️ 기존 반복 일정 삭제 시작: $title');

    final existingTasks = RecurringTaskService.findRecurringTasksByPattern(
      taskProvider.tasks,
      title,
      category,
    );

    debugPrint('  - 삭제할 일정 개수: ${existingTasks.length}');

    for (final existingTask in existingTasks) {
      taskProvider.deleteTask(existingTask.id);
      debugPrint('  - 삭제: ${existingTask.date} (ID: ${existingTask.id})');
    }

    // 혹시 모르는 중복 제거 (제목만으로도 한번 더 확인)
    final allTasksWithSameTitle = taskProvider.tasks
        .where((task) => task.isRecurring && task.title == title)
        .toList();

    for (final duplicateTask in allTasksWithSameTitle) {
      if (!existingTasks.contains(duplicateTask)) {
        taskProvider.deleteTask(duplicateTask.id);
        debugPrint(
          '  - 중복 삭제: ${duplicateTask.date} (ID: ${duplicateTask.id})',
        );
      }
    }

    debugPrint('✅ 기존 일정 삭제 완료');
  }

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
                    setState(() {
                      final newTime = TimeOfDay(
                        hour: newDateTime.hour,
                        minute: newDateTime.minute,
                      );

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
