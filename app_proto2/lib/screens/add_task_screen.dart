import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/alarm_service.dart';

class AddTaskScreen extends StatefulWidget {
  final DateTime selectedDate;

  const AddTaskScreen({super.key, required this.selectedDate});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isAM = true;
  bool _isImportant = false;
  Timer? _continuousTimer;
  bool _isContinuousIncrement = false;
  bool _isContinuousDecrement = false;
  bool _isHourSelected = true; // 시간 선택 여부

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _continuousTimer?.cancel();
    super.dispose();
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

  void _addTask() {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        date: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        isImportant: _isImportant,
      );

      context.read<TaskProvider>().addTask(task);

      // 알람 설정
      final alarmService = AlarmService();
      alarmService.scheduleAlarm(task, context);

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('일정추가'),
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
                    // 시간 설정
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 시간 (시)
                          Row(
                            children: [
                              Text(
                                '${_selectedTime.hour.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 32,
                                  color: _isHourSelected
                                      ? const Color(0xFF9C27B0)
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isHourSelected = true; // 시간 선택
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
                                    },
                                    onLongPressStart: (details) {
                                      _startContinuousIncrement();
                                    },
                                    onLongPressEnd: (details) {
                                      _stopContinuousIncrement();
                                    },
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        Icons.keyboard_arrow_up,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isHourSelected = true; // 시간 선택
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
                                    },
                                    onLongPressStart: (details) {
                                      _startContinuousDecrement();
                                    },
                                    onLongPressEnd: (details) {
                                      _stopContinuousDecrement();
                                    },
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
                          // 시간 (분)
                          Row(
                            children: [
                              Text(
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
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isHourSelected = false; // 분 선택
                                        int newMinute =
                                            _selectedTime.minute + 1;
                                        if (newMinute > 59) newMinute = 0;
                                        _selectedTime = TimeOfDay(
                                          hour: _selectedTime.hour,
                                          minute: newMinute,
                                        );
                                      });
                                    },
                                    onLongPressStart: (details) {
                                      _startContinuousMinuteIncrement();
                                    },
                                    onLongPressEnd: (details) {
                                      _stopContinuousMinuteIncrement();
                                    },
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        Icons.keyboard_arrow_up,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isHourSelected = false; // 분 선택
                                        int newMinute =
                                            _selectedTime.minute - 1;
                                        if (newMinute < 0) newMinute = 59;
                                        _selectedTime = TimeOfDay(
                                          hour: _selectedTime.hour,
                                          minute: newMinute,
                                        );
                                      });
                                    },
                                    onLongPressStart: (details) {
                                      _startContinuousMinuteDecrement();
                                    },
                                    onLongPressEnd: (details) {
                                      _stopContinuousMinuteDecrement();
                                    },
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 오전/오후 선택
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isAM = true;
                              // 오전으로 변경 시 시간도 12시간제로 변환
                              if (_selectedTime.hour > 12) {
                                _selectedTime = TimeOfDay(
                                  hour: _selectedTime.hour - 12,
                                  minute: _selectedTime.minute,
                                );
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _isAM
                                  ? const Color(0xFF9C27B0)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _isAM
                                    ? const Color(0xFF9C27B0)
                                    : Colors.grey,
                              ),
                            ),
                            child: Text(
                              '오전',
                              style: TextStyle(
                                color: _isAM ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isAM = false;
                              // 오후로 변경 시 시간도 12시간제로 변환
                              if (_selectedTime.hour <= 12) {
                                _selectedTime = TimeOfDay(
                                  hour: _selectedTime.hour + 12,
                                  minute: _selectedTime.minute,
                                );
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: !_isAM
                                  ? const Color(0xFF9C27B0)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: !_isAM
                                    ? const Color(0xFF9C27B0)
                                    : Colors.grey,
                              ),
                            ),
                            child: Text(
                              '오후',
                              style: TextStyle(
                                color: !_isAM ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE1BEE7)),
                ),
                child: Row(
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
                                ? const Color(0xFFFFD700) // 노란색
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isImportant
                                  ? const Color(0xFFFFD700)
                                  : Colors.grey,
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
                                '중요한 일정',
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
                                color: !_isImportant
                                    ? Colors.white
                                    : Colors.grey,
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
              ),
              const Spacer(),

              // 하단 버튼들
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C27B0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('추가'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C27B0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('취소'),
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
