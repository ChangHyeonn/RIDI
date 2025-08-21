import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../constants/categories.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _hourController = TextEditingController();
  final _minuteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isAM = true;
  bool _isImportant = false;
  String _selectedCategory = TaskCategories.general; // 카테고리 선택
  Timer? _continuousTimer;
  bool _isContinuousIncrement = false;
  bool _isContinuousDecrement = false;
  bool _isHourSelected = true; // 시간 선택 여부
  bool _isEditingHour = false; // 시간 직접 입력 모드
  bool _isEditingMinute = false; // 분 직접 입력 모드

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.task.date.year,
      widget.task.date.month,
      widget.task.date.day,
    );
    // DateTime을 TimeOfDay로 변환 (24시간 형식으로)
    _selectedTime = TimeOfDay(
      hour: widget.task.date.hour,
      minute: widget.task.date.minute,
    );
    _titleController.text = widget.task.title;
    _selectedCategory = widget.task.category; // 기존 카테고리 설정
    _isImportant = widget.task.isImportant;
    _isAM = widget.task.date.hour < 12;
    _updateTimeControllers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _continuousTimer?.cancel();
    super.dispose();
  }

  int _getDisplayHour() {
    // 24시간 형식을 12시간 형식으로 변환하여 표시
    int displayHour = _selectedTime.hour;
    if (displayHour == 0) {
      displayHour = 12;
    } else if (displayHour > 12) {
      displayHour = displayHour - 12;
    }
    return displayHour;
  }

  void _updateTimeControllers() {
    _hourController.text = _getDisplayHour().toString().padLeft(2, '0');
    _minuteController.text = _selectedTime.minute.toString().padLeft(2, '0');
  }

  void _updateTimeFromControllers() {
    final hour = int.tryParse(_hourController.text) ?? 12;
    final minute = int.tryParse(_minuteController.text) ?? 0;

    // 입력 검증
    if (hour < 1 || hour > 12 || minute < 0 || minute >= 60) {
      // 잘못된 입력 알림
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('알림'),
            content: const Text('잘못된 입력입니다.\n시간: 1-12, 분: 0-59 범위로 입력해주세요.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // 컨트롤러를 원래 값으로 복원
                  _updateTimeControllers();
                },
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      return;
    }

    // 12시간 형식을 24시간 형식으로 변환
    int hour24;
    if (_isAM) {
      if (hour == 12) {
        hour24 = 0; // 오전 12시는 00시
      } else {
        hour24 = hour; // 1-11시는 그대로
      }
    } else {
      if (hour == 12) {
        hour24 = 12; // 오후 12시는 12시
      } else {
        hour24 = hour + 12; // 1-11시는 +12
      }
    }

    setState(() {
      _selectedTime = TimeOfDay(hour: hour24, minute: minute);
      // 컨트롤러 업데이트
      _hourController.text = hour.toString().padLeft(2, '0');
      _minuteController.text = minute.toString().padLeft(2, '0');
    });
  }

  void _startContinuousIncrement() {
    _isContinuousIncrement = true;
    _continuousTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) {
      if (_isContinuousIncrement) {
        setState(() {
          int currentHour24 = _selectedTime.hour;
          int newHour24;
          bool newIsAM;

          // 24시간 형식으로 계산
          newHour24 = (currentHour24 + 1) % 24;

          // AM/PM 상태 업데이트
          newIsAM = newHour24 < 12;

          _selectedTime = TimeOfDay(
            hour: newHour24,
            minute: _selectedTime.minute,
          );
          _isAM = newIsAM;
          _updateTimeControllers();
        });
      }
    });
  }

  void _stopContinuousIncrement() {
    _isContinuousIncrement = false;
    _continuousTimer?.cancel();
  }

  void _startContinuousDecrement() {
    _isContinuousDecrement = true;
    _continuousTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) {
      if (_isContinuousDecrement) {
        setState(() {
          int currentHour24 = _selectedTime.hour;
          int newHour24;
          bool newIsAM;

          // 24시간 형식으로 계산
          newHour24 = (currentHour24 - 1 + 24) % 24;

          // AM/PM 상태 업데이트
          newIsAM = newHour24 < 12;

          _selectedTime = TimeOfDay(
            hour: newHour24,
            minute: _selectedTime.minute,
          );
          _isAM = newIsAM;
          _updateTimeControllers();
        });
      }
    });
  }

  void _stopContinuousDecrement() {
    _isContinuousDecrement = false;
    _continuousTimer?.cancel();
  }

  void _startContinuousMinuteIncrement() {
    _continuousTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) {
      setState(() {
        int newMinute = _selectedTime.minute + 1;
        if (newMinute > 59) newMinute = 0;
        _selectedTime = TimeOfDay(hour: _selectedTime.hour, minute: newMinute);
      });
    });
  }

  void _stopContinuousMinuteIncrement() {
    _continuousTimer?.cancel();
  }

  void _startContinuousMinuteDecrement() {
    _continuousTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) {
      setState(() {
        int newMinute = _selectedTime.minute - 1;
        if (newMinute < 0) newMinute = 59;
        _selectedTime = TimeOfDay(hour: _selectedTime.hour, minute: newMinute);
      });
    });
  }

  void _stopContinuousMinuteDecrement() {
    _continuousTimer?.cancel();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF9C27B0)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _updateTask() {
    if (_formKey.currentState!.validate()) {
      // 디버깅을 위한 로그 추가
      print('🔍 _updateTask 디버깅:');
      print('  원본 task.date: ${widget.task.date}');
      print('  _selectedDate: $_selectedDate');
      print('  _selectedTime: $_selectedTime');
      print('  _isAM: $_isAM');
      print('  _isImportant: $_isImportant');

      // _selectedTime은 이미 24시간 형식이므로 그대로 사용
      final selectedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      print('  생성된 selectedDateTime: $selectedDateTime');

      // 현재 시간과 비교
      final now = DateTime.now();

      // 이미 지난 시간인지 체크
      if (selectedDateTime.isBefore(now)) {
        // 경고 메시지 표시
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('알림'),
              content: const Text('이미 지난 시간입니다.\n미래의 시간을 선택해주세요.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
        return; // 일정 수정 중단
      }

      // 유효한 시간인 경우 일정 수정
      final updatedTask = Task(
        id: widget.task.id, // 기존 ID 유지
        title: _titleController.text,
        date: selectedDateTime,
        isCompleted: widget.task.isCompleted, // 완료 상태 유지
        isImportant: _isImportant,
        category: _selectedCategory,
      );

      context.read<TaskProvider>().updateTask(updatedTask);
      // 알람은 TaskProvider에서 자동으로 재설정됨

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfafafa),
      appBar: AppBar(
        title: const Text('일정수정'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1f2937),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목 입력 필드
                const Text(
                  '제목',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: '일정 제목을 입력하세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFd1d5db)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFd1d5db)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF6366f1)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '제목을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 날짜 입력 필드
                const Text(
                  '날짜',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFd1d5db)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const Icon(Icons.calendar_today, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 24),

                // 시간 입력 필드
                const Text(
                  '시간',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFd1d5db)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 시간 설정 (왼쪽)
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 시간 (시) - 탭하면 직접 입력
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isHourSelected = true;
                                  _isEditingHour = true;
                                  _isEditingMinute = false;
                                  // 기존 숫자 지우기
                                  _hourController.clear();
                                });
                              },
                              child: _isEditingHour
                                  ? Container(
                                      width: 60,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: const Color(0xFF6366f1),
                                        ),
                                      ),
                                      child: TextFormField(
                                        controller: _hourController,
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF6366f1),
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                        ),
                                        onChanged: (value) {
                                          // 입력 중에는 변환하지 않음
                                        },
                                        onEditingComplete: () {
                                          // 입력 완료 시에만 변환
                                          _updateTimeFromControllers();
                                          setState(() {
                                            _isEditingHour = false;
                                          });
                                        },
                                      ),
                                    )
                                  : Text(
                                      '${_getDisplayHour().toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 32,
                                        color: _isHourSelected
                                            ? const Color(0xFF6366f1)
                                            : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    // 편집 중이면 버튼 비활성화
                                    if (_isEditingHour || _isEditingMinute)
                                      return;

                                    setState(() {
                                      _isHourSelected = true;
                                      int currentHour24 = _selectedTime.hour;
                                      int newHour24 = (currentHour24 + 1) % 24;
                                      bool newIsAM = newHour24 < 12;

                                      _selectedTime = TimeOfDay(
                                        hour: newHour24,
                                        minute: _selectedTime.minute,
                                      );
                                      _isAM = newIsAM;
                                      _updateTimeControllers();
                                    });
                                  },
                                  onLongPressStart: (details) {
                                    // 편집 중이면 버튼 비활성화
                                    if (_isEditingHour || _isEditingMinute)
                                      return;
                                    _startContinuousIncrement();
                                  },
                                  onLongPressEnd: (details) {
                                    _stopContinuousIncrement();
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color:
                                          (_isEditingHour || _isEditingMinute)
                                          ? Colors.grey[100]
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.keyboard_arrow_up,
                                      color:
                                          (_isEditingHour || _isEditingMinute)
                                          ? Colors.grey[300]
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () {
                                    // 편집 중이면 버튼 비활성화
                                    if (_isEditingHour || _isEditingMinute)
                                      return;

                                    setState(() {
                                      _isHourSelected = true;
                                      int currentHour24 = _selectedTime.hour;
                                      int newHour24 =
                                          (currentHour24 - 1 + 24) % 24;
                                      bool newIsAM = newHour24 < 12;

                                      _selectedTime = TimeOfDay(
                                        hour: newHour24,
                                        minute: _selectedTime.minute,
                                      );
                                      _isAM = newIsAM;
                                      _updateTimeControllers();
                                    });
                                  },
                                  onLongPressStart: (details) {
                                    // 편집 중이면 버튼 비활성화
                                    if (_isEditingHour || _isEditingMinute)
                                      return;
                                    _startContinuousDecrement();
                                  },
                                  onLongPressEnd: (details) {
                                    _stopContinuousDecrement();
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color:
                                          (_isEditingHour || _isEditingMinute)
                                          ? Colors.grey[100]
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.keyboard_arrow_down,
                                      color:
                                          (_isEditingHour || _isEditingMinute)
                                          ? Colors.grey[300]
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        ':',
                        style: TextStyle(
                          fontSize: 32,
                          color: Color(0xFF6366f1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 시간 (분) - 탭하면 직접 입력
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isHourSelected = false;
                                  _isEditingMinute = true;
                                  _isEditingHour = false;
                                  // 기존 숫자 지우기
                                  _minuteController.clear();
                                });
                              },
                              child: _isEditingMinute
                                  ? Container(
                                      width: 60,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: const Color(0xFF9C27B0),
                                        ),
                                      ),
                                      child: TextFormField(
                                        controller: _minuteController,
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF6366f1),
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                        ),
                                        onChanged: (value) {
                                          // 입력 중에는 변환하지 않음
                                        },
                                        onEditingComplete: () {
                                          // 입력 완료 시에만 변환
                                          _updateTimeFromControllers();
                                          setState(() {
                                            _isEditingMinute = false;
                                          });
                                        },
                                      ),
                                    )
                                  : Text(
                                      '${_selectedTime.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 32,
                                        color: !_isHourSelected
                                            ? const Color(0xFF6366f1)
                                            : Colors.grey,
                                        fontWeight: !_isHourSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    // 편집 중이면 버튼 비활성화
                                    if (_isEditingHour || _isEditingMinute)
                                      return;

                                    setState(() {
                                      _isHourSelected = false;
                                      int currentMinute = _selectedTime.minute;
                                      int newMinute = (currentMinute + 1) % 60;

                                      _selectedTime = TimeOfDay(
                                        hour: _selectedTime.hour,
                                        minute: newMinute,
                                      );
                                      _updateTimeControllers();
                                    });
                                  },
                                  onLongPressStart: (details) {
                                    // 편집 중이면 버튼 비활성화
                                    if (_isEditingHour || _isEditingMinute)
                                      return;
                                    _startContinuousMinuteIncrement();
                                  },
                                  onLongPressEnd: (details) {
                                    _stopContinuousMinuteIncrement();
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color:
                                          (_isEditingHour || _isEditingMinute)
                                          ? Colors.grey[100]
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.keyboard_arrow_up,
                                      color:
                                          (_isEditingHour || _isEditingMinute)
                                          ? Colors.grey[300]
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () {
                                    // 편집 중이면 버튼 비활성화
                                    if (_isEditingHour || _isEditingMinute)
                                      return;

                                    setState(() {
                                      _isHourSelected = false;
                                      int currentMinute = _selectedTime.minute;
                                      int newMinute =
                                          (currentMinute - 1 + 60) % 60;

                                      _selectedTime = TimeOfDay(
                                        hour: _selectedTime.hour,
                                        minute: newMinute,
                                      );
                                      _updateTimeControllers();
                                    });
                                  },
                                  onLongPressStart: (details) {
                                    // 편집 중이면 버튼 비활성화
                                    if (_isEditingHour || _isEditingMinute)
                                      return;
                                    _startContinuousMinuteDecrement();
                                  },
                                  onLongPressEnd: (details) {
                                    _stopContinuousMinuteDecrement();
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color:
                                          (_isEditingHour || _isEditingMinute)
                                          ? Colors.grey[100]
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.keyboard_arrow_down,
                                      color:
                                          (_isEditingHour || _isEditingMinute)
                                          ? Colors.grey[300]
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 오전/오후 선택 (오른쪽) - 하나의 토글 버튼
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () {
                            // 편집 중이면 버튼 비활성화
                            if (_isEditingHour || _isEditingMinute) return;
                            setState(() {
                              _isAM = !_isAM;
                              // AM/PM 변경 시 시간도 업데이트
                              int currentHour24 = _selectedTime.hour;
                              if (_isAM) {
                                // PM에서 AM으로 변경: 12시간을 빼거나 12시간을 더함
                                if (currentHour24 >= 12) {
                                  currentHour24 = currentHour24 - 12;
                                }
                              } else {
                                // AM에서 PM으로 변경: 12시간을 더함
                                if (currentHour24 < 12) {
                                  currentHour24 = currentHour24 + 12;
                                }
                              }
                              _selectedTime = TimeOfDay(
                                hour: currentHour24,
                                minute: _selectedTime.minute,
                              );
                              _updateTimeControllers();
                            });
                          },
                          child: Container(
                            height: 80,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: (_isEditingHour || _isEditingMinute)
                                  ? Colors.grey[300]
                                  : const Color(0xFF6366f1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF6366f1),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isAM
                                      ? Icons.wb_sunny
                                      : Icons.nightlight_round,
                                  color: (_isEditingHour || _isEditingMinute)
                                      ? Colors.grey[400]
                                      : Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isAM ? '오전' : '오후',
                                  style: TextStyle(
                                    color: (_isEditingHour || _isEditingMinute)
                                        ? Colors.grey[400]
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 카테고리 선택
                const Text(
                  '카테고리',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: TaskCategories.allCategories.map((category) {
                    final isSelected = _selectedCategory == category;
                    final categoryInfo = TaskCategories.getCategoryInfo(
                      category,
                    );

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                            // 건강 카테고리 선택 시 자동으로 중요도 설정
                            if (category == TaskCategories.health) {
                              _isImportant = true;
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(categoryInfo?['color'] ?? 0xFF2196F3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Color(categoryInfo?['color'] ?? 0xFF2196F3)
                                  : const Color(0xFFd1d5db),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                categoryInfo?['icon'] ?? '📅',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                categoryInfo?['name'] ?? category,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // 중요도 선택
                const Text(
                  '중요도',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isImportant = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _isImportant
                                ? const Color(0xFFfbbf24)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isImportant
                                  ? const Color(0xFFfbbf24)
                                  : const Color(0xFFd1d5db),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star,
                                color: _isImportant
                                    ? Colors.white
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '중요 일정',
                                style: TextStyle(
                                  color: _isImportant
                                      ? Colors.white
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // 건강 카테고리일 때는 일반 일정 선택 불가
                          if (_selectedCategory == TaskCategories.health) {
                            return;
                          }
                          setState(() => _isImportant = false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: !_isImportant
                                ? const Color(0xFFfbbf24)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: !_isImportant
                                  ? const Color(0xFFfbbf24)
                                  : const Color(0xFFd1d5db),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star_border,
                                color:
                                    _selectedCategory == TaskCategories.health
                                    ? Colors.grey[400] // 건강 카테고리일 때 더 어둡게
                                    : (!_isImportant
                                          ? Colors.white
                                          : Colors.grey),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '일반 일정',
                                style: TextStyle(
                                  color:
                                      _selectedCategory == TaskCategories.health
                                      ? Colors.grey[400] // 건강 카테고리일 때 더 어둡게
                                      : (!_isImportant
                                            ? Colors.white
                                            : Colors.grey),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40), // 버튼 위치를 아래로 조정
                // 하단 버튼들
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _updateTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366f1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '수정',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // 삭제 확인 다이얼로그 표시
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
                                    // 일정 삭제
                                    context.read<TaskProvider>().deleteTask(
                                      widget.task.id,
                                    );
                                    Navigator.pop(context); // 다이얼로그 닫기
                                    Navigator.pop(context); // 수정창 닫기
                                  },
                                  child: const Text('삭제'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFef4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '삭제',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
