import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/alarm_service.dart';

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
    // DateTime을 TimeOfDay로 변환 (12시간 형식으로)
    int displayHour = widget.task.date.hour;
    bool isAM = true;

    if (widget.task.date.hour == 0) {
      displayHour = 12;
      isAM = true;
    } else if (widget.task.date.hour <= 12) {
      displayHour = widget.task.date.hour;
      isAM = true;
    } else {
      displayHour = widget.task.date.hour - 12;
      isAM = false;
    }

    _selectedTime = TimeOfDay(
      hour: displayHour,
      minute: widget.task.date.minute,
    );
    _titleController.text = widget.task.title;
    _isImportant = widget.task.isImportant;
    _isAM = isAM;
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

  void _updateTimeControllers() {
    _hourController.text = _selectedTime.hour.toString().padLeft(2, '0');
    _minuteController.text = _selectedTime.minute.toString().padLeft(2, '0');
  }

  void _updateTimeFromControllers() {
    final hour = int.tryParse(_hourController.text) ?? _selectedTime.hour;
    final minute = int.tryParse(_minuteController.text) ?? _selectedTime.minute;

    // 입력 검증
    if (hour < 0 || hour > 24 || minute < 0 || minute >= 60) {
      // 잘못된 입력 알림
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('알림'),
            content: const Text('잘못된 입력입니다.\n시간: 0-24, 분: 0-59 범위로 입력해주세요.'),
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

    // 24시간 형식을 12시간 형식으로 변환
    int displayHour;
    bool newIsAM;

    if (hour == 0) {
      displayHour = 12;
      newIsAM = true;
    } else if (hour <= 12) {
      displayHour = hour;
      newIsAM = true;
    } else {
      displayHour = hour - 12;
      newIsAM = false;
    }

    setState(() {
      _selectedTime = TimeOfDay(hour: displayHour, minute: minute);
      _isAM = newIsAM;
      // 컨트롤러 업데이트
      _hourController.text = displayHour.toString().padLeft(2, '0');
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
          int currentHour = _selectedTime.hour;
          int newHour;
          bool newIsAM = _isAM;

          if (_isAM) {
            // 오전인 경우
            if (currentHour == 12) {
              newHour = 1;
              newIsAM = false; // 오후로 변경
            } else {
              newHour = currentHour + 1;
            }
          } else {
            // 오후인 경우
            if (currentHour == 12) {
              newHour = 1;
              newIsAM = true; // 오전으로 변경
            } else if (currentHour == 11) {
              newHour = 12;
            } else {
              newHour = currentHour + 1;
            }
          }

          _selectedTime = TimeOfDay(
            hour: newHour,
            minute: _selectedTime.minute,
          );
          _isAM = newIsAM;
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
          int currentHour = _selectedTime.hour;
          int newHour;
          bool newIsAM = _isAM;

          if (_isAM) {
            // 오전인 경우
            if (currentHour == 1) {
              newHour = 12;
              newIsAM = false; // 오후로 변경
            } else {
              newHour = currentHour - 1;
            }
          } else {
            // 오후인 경우
            if (currentHour == 1) {
              newHour = 12;
              newIsAM = true; // 오전으로 변경
            } else if (currentHour == 12) {
              newHour = 11;
            } else {
              newHour = currentHour - 1;
            }
          }

          _selectedTime = TimeOfDay(
            hour: newHour,
            minute: _selectedTime.minute,
          );
          _isAM = newIsAM;
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

      // 12시간 형식을 24시간 형식으로 변환
      int hour24 = _selectedTime.hour;
      if (!_isAM && _selectedTime.hour != 12) {
        hour24 = _selectedTime.hour + 12;
      } else if (_isAM && _selectedTime.hour == 12) {
        hour24 = 0;
      }

      print('  변환된 hour24: $hour24');

      // 선택된 날짜와 시간으로 DateTime 객체 생성
      final selectedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        hour24,
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
      );

      context.read<TaskProvider>().updateTask(updatedTask);

      // 알람 재설정
      final alarmService = AlarmService();
      alarmService.scheduleAlarm(updatedTask, context);

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('일정수정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목 입력 필드
              const Text(
                '제목',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: '일정 제목을 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE1BEE7)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE1BEE7)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF9C27B0)),
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
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE1BEE7)),
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
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE1BEE7)),
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
                                        color: const Color(0xFF9C27B0),
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _hourController,
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF9C27B0),
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
                                    '${_selectedTime.hour.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 32,
                                      color: _isHourSelected
                                          ? const Color(0xFF9C27B0)
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
                                    int currentHour = _selectedTime.hour;
                                    int newHour;
                                    bool newIsAM = _isAM;

                                    if (_isAM) {
                                      if (currentHour == 12) {
                                        newHour = 1;
                                        newIsAM = false;
                                      } else {
                                        newHour = currentHour + 1;
                                      }
                                    } else {
                                      if (currentHour == 12) {
                                        newHour = 1;
                                        newIsAM = true;
                                      } else if (currentHour == 11) {
                                        newHour = 12;
                                      } else {
                                        newHour = currentHour + 1;
                                      }
                                    }

                                    _selectedTime = TimeOfDay(
                                      hour: newHour,
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
                                    color: (_isEditingHour || _isEditingMinute)
                                        ? Colors.grey[100]
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.keyboard_arrow_up,
                                    color: (_isEditingHour || _isEditingMinute)
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
                                    int currentHour = _selectedTime.hour;
                                    int newHour;
                                    bool newIsAM = _isAM;

                                    if (_isAM) {
                                      if (currentHour == 1) {
                                        newHour = 12;
                                        newIsAM = false;
                                      } else {
                                        newHour = currentHour - 1;
                                      }
                                    } else {
                                      if (currentHour == 1) {
                                        newHour = 12;
                                        newIsAM = true;
                                      } else if (currentHour == 12) {
                                        newHour = 11;
                                      } else {
                                        newHour = currentHour - 1;
                                      }
                                    }

                                    _selectedTime = TimeOfDay(
                                      hour: newHour,
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
                                    color: (_isEditingHour || _isEditingMinute)
                                        ? Colors.grey[100]
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: (_isEditingHour || _isEditingMinute)
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
                        color: Color(0xFF9C27B0),
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
                                        color: Color(0xFF9C27B0),
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
                                          ? const Color(0xFF9C27B0)
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
                                    color: (_isEditingHour || _isEditingMinute)
                                        ? Colors.grey[100]
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.keyboard_arrow_up,
                                    color: (_isEditingHour || _isEditingMinute)
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
                                    color: (_isEditingHour || _isEditingMinute)
                                        ? Colors.grey[100]
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: (_isEditingHour || _isEditingMinute)
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
                          setState(() => _isAM = !_isAM);
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
                                : const Color(0xFF9C27B0),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF9C27B0)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isAM ? Icons.wb_sunny : Icons.nightlight_round,
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
                              ? const Color(0xFF9C27B0)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isImportant
                                ? const Color(0xFF9C27B0)
                                : Colors.grey,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star,
                              color: _isImportant ? Colors.white : Colors.grey,
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
                      onTap: () => setState(() => _isImportant = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: !_isImportant
                              ? const Color(0xFF9C27B0)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: !_isImportant
                                ? const Color(0xFF9C27B0)
                                : Colors.grey,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star_border,
                              color: !_isImportant ? Colors.white : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '일반 일정',
                              style: TextStyle(
                                color: !_isImportant
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
                ],
              ),
              const Spacer(),

              // 하단 버튼들
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _updateTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C27B0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('수정'),
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
                        backgroundColor: const Color(0xFFF44336), // 빨간색으로 변경
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('삭제'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
