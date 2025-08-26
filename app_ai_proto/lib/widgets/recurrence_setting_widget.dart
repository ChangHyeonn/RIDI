import 'package:flutter/material.dart';
import '../models/task.dart';

class RecurrenceSettingWidget extends StatefulWidget {
  final bool isRecurring;
  final RecurrenceInfo? initialRecurrence;
  final Function(bool isRecurring, RecurrenceInfo? recurrence) onChanged;

  const RecurrenceSettingWidget({
    super.key,
    required this.isRecurring,
    this.initialRecurrence,
    required this.onChanged,
  });

  @override
  State<RecurrenceSettingWidget> createState() =>
      _RecurrenceSettingWidgetState();
}

class _RecurrenceSettingWidgetState extends State<RecurrenceSettingWidget> {
  late bool _isRecurring;
  late RecurrenceInfo? _recurrence;
  late List<bool> _selectedDays;
  late DateTime? _endDate;
  late List<RecurrenceTime> _times;
  bool get _isDailyActive => _selectedDays.every((d) => d);

  @override
  void initState() {
    super.initState();
    _isRecurring = widget.isRecurring;
    _recurrence = widget.initialRecurrence;
    _selectedDays = List.filled(7, false); // 월~일
    _endDate = _recurrence?.endDate;
    _times = _recurrence?.times ?? [RecurrenceTime(time: "09:00", label: "오전")];

    // 초기 반복 정보가 있으면 요일 선택 상태 설정
    if (_recurrence != null) {
      _updateSelectedDaysFromRecurrence();
    }
  }

  void _updateSelectedDaysFromRecurrence() {
    if (_recurrence?.type == 'daily') {
      _selectedDays = List.filled(7, true);
    } else if (_recurrence?.type == 'weekdays') {
      _selectedDays = [true, true, true, true, true, false, false]; // 월~금
    } else if (_recurrence?.type == 'weekends') {
      _selectedDays = [false, false, false, false, false, true, true]; // 토~일
    } else if (_recurrence?.type == 'custom_days' &&
        _recurrence?.daysOfWeek != null) {
      _selectedDays = List.filled(7, false);
      for (int day in _recurrence!.daysOfWeek!) {
        if (day >= 0 && day < 7) {
          _selectedDays[day] = true;
        }
      }
    }
  }

  void _updateRecurrence() {
    if (!_isRecurring) {
      _recurrence = null;
    } else {
      String type = _getRecurrenceType();
      _recurrence = RecurrenceInfo(
        type: type,
        times: _times,
        endDate: _endDate,
        daysOfWeek: type == 'custom_days' ? _getSelectedDayIndices() : null,
      );
    }
    widget.onChanged(_isRecurring, _recurrence);
  }

  void _toggleDaily() {
    setState(() {
      if (_isDailyActive) {
        // 매일 해제: 전부 해제 상태로 전환
        _selectedDays = List.filled(7, false);
      } else {
        // 매일 설정: 전부 선택
        _selectedDays = List.filled(7, true);
      }
    });
    _updateRecurrence();
  }

  String _getRecurrenceType() {
    int selectedCount = _selectedDays.where((day) => day).length;

    if (selectedCount == 7) return 'daily';
    if (selectedCount == 5 &&
        _selectedDays[0] &&
        _selectedDays[1] &&
        _selectedDays[2] &&
        _selectedDays[3] &&
        _selectedDays[4] &&
        !_selectedDays[5] &&
        !_selectedDays[6]) {
      return 'weekdays';
    }
    if (selectedCount == 2 &&
        !_selectedDays[0] &&
        !_selectedDays[1] &&
        !_selectedDays[2] &&
        !_selectedDays[3] &&
        !_selectedDays[4] &&
        _selectedDays[5] &&
        _selectedDays[6]) {
      return 'weekends';
    }
    return 'custom_days';
  }

  List<int> _getSelectedDayIndices() {
    List<int> indices = [];
    for (int i = 0; i < _selectedDays.length; i++) {
      if (_selectedDays[i]) {
        indices.add(i);
      }
    }
    return indices;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 반복 일정 활성화 토글
        Row(
          children: [
            Text(
              '반복일정',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const Spacer(),
            Switch(
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value;
                  if (!value) {
                    _recurrence = null;
                  }
                });
                _updateRecurrence();
              },
              activeThumbColor: Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 반복 설정 상세 옵션 (반복이 활성화된 경우에만 표시)
        if (_isRecurring) ...[
          // 요일 및 기간
          Text(
            '요일 및 기간',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),

          // 기간 설정
          GestureDetector(
            onTap: _selectEndDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    _endDate != null
                        ? '${_endDate!.year}년 ${_endDate!.month}월 ${_endDate!.day}일 까지'
                        : '무기한',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 요일 선택 + 매일 토글
          Row(
            children: [
              // 매일 칩 (맨 왼쪽)
              Expanded(
                child: GestureDetector(
                  onTap: _toggleDaily,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isDailyActive ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 14,
                          color: _isDailyActive
                              ? Colors.white
                              : Colors.grey[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '매일',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isDailyActive
                                ? Colors.white
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 요일 칩들
              ...['월', '화', '수', '목', '금', '토', '일'].asMap().entries.map((
                entry,
              ) {
                int index = entry.key;
                String day = entry.value;
                bool isSelected = _selectedDays[index];

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_isDailyActive) {
                          // 매일 활성 상태에서 개별 요일을 탭하면 매일 해제 후 해당 요일만 선택
                          _selectedDays = List.filled(7, false);
                          _selectedDays[index] = true;
                        } else {
                          _selectedDays[index] = !isSelected;
                        }
                      });
                      _updateRecurrence();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
          const SizedBox(height: 24),

          // 시간 설정
          Text(
            '시간 설정',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),

          // 시간 목록
          ..._times.asMap().entries.map((entry) {
            int index = entry.key;
            RecurrenceTime time = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${time.label} ${time.time} 에 반복 알람 설정',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const Spacer(),
                  if (_times.length > 1)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _times.removeAt(index);
                        });
                        _updateRecurrence();
                      },
                      child: Icon(
                        Icons.remove_circle_outline,
                        size: 20,
                        color: Colors.red[400],
                      ),
                    ),
                ],
              ),
            );
          }),

          // 시간 추가 버튼
          GestureDetector(
            onTap: _addTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Text(
                    '시간 추가하기',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const Spacer(),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 기능 설명
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '시간 추가하기를 누르면',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
                Text(
                  '바로 위에 있는 시간을 추가해서',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
                Text(
                  '한 반복 알람 내에 알람 시간을 추가해준다',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('ko', 'KR'),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
      _updateRecurrence();
    }
  }

  Future<void> _addTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        String timeString =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        String label = picked.hour < 12 ? '오전' : '오후';
        _times.add(RecurrenceTime(time: timeString, label: label));
      });
      _updateRecurrence();
    }
  }
}
