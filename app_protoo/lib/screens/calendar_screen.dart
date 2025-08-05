import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import 'add_task_screen.dart';
import 'date_detail_screen.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 앱바
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Expanded(
                    child: Text(
                      '달력',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // 뒤로가기 버튼과 균형 맞추기
                ],
              ),
            ),

            // 커스텀 헤더 (한자 년/월 표시 + 화살표)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 왼쪽 화살표
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(
                          _focusedDay.year,
                          _focusedDay.month - 1,
                        );
                      });
                    },
                    icon: const Icon(Icons.chevron_left),
                    color: Colors.black,
                  ),
                  // 년/월 표시
                  Column(
                    children: [
                      // 년도 (작은 폰트)
                      Text(
                        '${_focusedDay.year}年',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF9C27B0),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // 월 (큰 폰트)
                      Text(
                        '${_focusedDay.month}月',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9C27B0),
                        ),
                      ),
                    ],
                  ),
                  // 오른쪽 화살표
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(
                          _focusedDay.year,
                          _focusedDay.month + 1,
                        );
                      });
                    },
                    icon: const Icon(Icons.chevron_right),
                    color: Colors.black,
                  ),
                ],
              ),
            ),

            // 달력
            Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                return TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });

                    // 선택된 날짜의 상세 화면으로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DateDetailScreen(
                          date: selectedDay,
                          title: '${selectedDay.month}/${selectedDay.day}',
                        ),
                      ),
                    );
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarFormat: CalendarFormat.month,
                  headerVisible: false, // 헤더 완전히 숨기기
                  calendarStyle: const CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Color(0xFF9C27B0),
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Color(0xFFE1BEE7),
                      shape: BoxShape.circle,
                    ),
                    outsideDaysVisible: false,
                    // 날짜 셀 높이 더 증가
                    cellMargin: const EdgeInsets.symmetric(vertical: 38),
                    // 날짜 텍스트 스타일 명시적 설정
                    defaultTextStyle: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    selectedTextStyle: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    todayTextStyle: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.grey),
                    weekendStyle: TextStyle(color: Colors.grey),
                  ),
                  // 요일을 한글로 변경
                  daysOfWeekHeight: 40,
                  locale: 'ko_KR',
                  // 일정이 있는 날에 점 표시
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      final tasks = taskProvider.getTasksForDate(date);
                      if (tasks.isNotEmpty) {
                        return Positioned(
                          right: 1,
                          top: 1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF6B35), // 주황색 점
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                    // 날짜 텍스트 직접 렌더링
                    defaultBuilder: (context, date, focusedDay) {
                      return Center(
                        child: Text(
                          '${date.day}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      );
                    },
                    selectedBuilder: (context, date, focusedDay) {
                      return Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(0xFF9C27B0),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(0xFF9C27B0),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    todayBuilder: (context, date, focusedDay) {
                      return Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE1BEE7),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // 일정 추가 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddTaskScreen(selectedDate: _selectedDay),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '일정추가',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
