import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/alarm_service.dart';

class AddTaskScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Task? editingTask; // 편집할 일정 (null이면 새 일정 추가)

  const AddTaskScreen({
    super.key, 
    required this.selectedDate,
    this.editingTask,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _hourController = TextEditingController();
  final _minuteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _selectedHour = 12;
  int _selectedMinute = 0;
  bool _isImportant = false; // 별표시 상태 추가
  bool _isPM = false; // 오전/오후 토글 상태

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _selectedHour = DateTime.now().hour;
    _selectedMinute = DateTime.now().minute;
    _isPM = _selectedHour >= 12;
    _hourController.text = (_selectedHour % 12 == 0 ? 12 : _selectedHour % 12).toString().padLeft(2, '0');
    _minuteController.text = _selectedMinute.toString().padLeft(2, '0');

    // 편집 모드일 때 기존 일정 정보로 초기화
    if (widget.editingTask != null) {
      final task = widget.editingTask!;
      _titleController.text = task.title;
      _selectedDate = task.date;
      _selectedHour = task.date.hour;
      _selectedMinute = task.date.minute;
      _isImportant = task.isImportant;
      _isPM = _selectedHour >= 12;
      _hourController.text = (_selectedHour % 12 == 0 ? 12 : _selectedHour % 12).toString().padLeft(2, '0');
      _minuteController.text = _selectedMinute.toString().padLeft(2, '0');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ko', 'KR'), // 한국어 설정
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _getTimePeriod(int hour) {
    if (hour >= 12 && hour < 24) {
      return '오후';
    } else {
      return '오전';
    }
  }

  void _toggleTimePeriod() {
    setState(() {
      _isPM = !_isPM;
    });
  }

  void _handleHourInput(String value) {
    final hour = int.tryParse(value) ?? 0;
    
    if (hour >= 24) {
      // 24 이상이면 자동으로 오전/오후 전환하고 0~12 사이로 변환
      setState(() {
        _isPM = !_isPM;
        final convertedHour = hour % 12;
        _hourController.text = (convertedHour == 0 ? 12 : convertedHour).toString().padLeft(2, '0');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${hour}시는 ${_isPM ? '오후' : '오전'} ${hour % 12 == 0 ? 12 : hour % 12}시로 변환되었습니다.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (hour > 12) {
      // 13~23이면 오후로 설정하고 1~12로 변환
      setState(() {
        _isPM = true;
        final convertedHour = hour - 12;
        _hourController.text = convertedHour.toString().padLeft(2, '0');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${hour}시는 오후 ${hour - 12}시로 변환되었습니다.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (hour < 0) {
      // 음수면 12로 설정
      setState(() {
        _hourController.text = '12';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('시간은 1시~12시 사이로 입력해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleMinuteInput(String value) {
    final minute = int.tryParse(value) ?? 0;
    
    if (minute > 59) {
      // 59보다 크면 안내 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('분은 0분~59분 사이로 입력해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      // 입력값을 59로 제한
      setState(() {
        _minuteController.text = '59';
      });
    } else if (minute < 0) {
      // 음수면 0으로 설정
      setState(() {
        _minuteController.text = '00';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('분은 0분~59분 사이로 입력해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _addTask() {
    if (_formKey.currentState!.validate()) {
      // 시간과 분 입력값 검증
      final hourInput = int.tryParse(_hourController.text) ?? 0;
      final minute = int.tryParse(_minuteController.text) ?? 0;
      
      if (hourInput < 1 || hourInput > 12 || minute < 0 || minute > 59) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('올바른 시간을 입력해주세요 (1시~12시, 0분~59분)')),
        );
        return;
      }

      // 12시간 형식을 24시간 형식으로 변환
      int hour24;
      if (_isPM) {
        hour24 = hourInput == 12 ? 12 : hourInput + 12;
      } else {
        hour24 = hourInput == 12 ? 0 : hourInput;
      }

      final task = Task(
        id: widget.editingTask?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        date: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          hour24,
          minute,
        ),
        isCompleted: widget.editingTask?.isCompleted ?? false, // 편집 시 완료 상태 유지
        isImportant: _isImportant, // 별표시 상태 추가
      );

      // 편집 모드인지 새 일정인지에 따라 다른 액션 수행
      if (widget.editingTask != null) {
        // 편집 모드: 일정 업데이트
        context.read<TaskProvider>().updateTask(task);
      } else {
        // 새 일정: 일정 추가
        context.read<TaskProvider>().addTask(task);
        
        // 알람 설정 (새 일정에만)
        final alarmService = AlarmService();
        alarmService.scheduleAlarm(task, context);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.editingTask != null ? '일정수정' : '일정추가'),
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

              // 별표시 토글
              Row(
                children: [
                  const Text(
                    '중요한 일정',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isImportant = !_isImportant;
                      });
                    },
                    child: Icon(
                      _isImportant ? Icons.star : Icons.star_border,
                      color: _isImportant ? Colors.orange : Colors.grey,
                      size: 32, // 별표 크기 증가
                    ),
                  ),
                ],
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
                      Container(
                        height: 20,
                        width: 1,
                        color: Colors.grey,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      const Text(
                        '달력',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                    // 시간 입력
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _hourController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                color: Color(0xFF9C27B0),
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                hintText: '12',
                              ),
                              onChanged: _handleHourInput,
                            ),
                          ),
                          const Text(
                            ':',
                            style: TextStyle(
                              fontSize: 24,
                              color: Color(0xFF9C27B0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _minuteController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.grey,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                hintText: '00',
                              ),
                              onChanged: _handleMinuteInput,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 오전/오후 토글 버튼
                    GestureDetector(
                      onTap: _toggleTimePeriod,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isPM ? const Color(0xFF9C27B0) : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _isPM ? '오후' : '오전',
                          style: TextStyle(
                            fontSize: 16,
                            color: _isPM ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.bold,
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
                      child: Text(widget.editingTask != null ? '수정' : '추가'),
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
