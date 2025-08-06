import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'date_detail_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _showTodayImportantOnly = false; // 오늘 중요 일정만 보기 상태
  bool _showTomorrowImportantOnly = false; // 내일 중요 일정만 보기 상태

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().initialize();
    });
  }

  // 시간 포맷 (오전/오후 형식)
  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour < 12 ? hour : (hour == 12 ? 12 : hour - 12);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$period${displayHour.toString().padLeft(2, '0')}:$displayMinute';
  }

  // 날짜 포맷 (월/일) - 수정된 형식
  String _formatDate(DateTime date) {
    return ' - ${date.month}월 ${date.day}일';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            if (taskProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final todayTasks = taskProvider.getTodayTasks();
            final tomorrowTasks = taskProvider.getTomorrowTasks();
            final isTodayCompleted = taskProvider.isTodayCompleted;
            final isTomorrowCompleted = taskProvider.isTomorrowCompleted;

            final fontSize = taskProvider.fontSize;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 상단 영역 (Expanded로 남은 공간 모두 차지)
                  Expanded(
                    child: Column(
                      children: [
                        // 오늘/내일 패널 (Column으로 변경하여 상/하 배치)
                        Expanded(
                          flex: 3, // 3/4 비율
                          child: Column(
                            children: [
                              // 오늘 패널 (위쪽)
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DateDetailScreen(
                                          date: DateTime.now(),
                                          title: '오늘',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: todayTasks.isEmpty
                                          ? Colors.grey[400]
                                          : (isTodayCompleted
                                                ? Colors.green
                                                : Colors.red),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        // 패널 높이에 따라 보여줄 일정 개수 결정
                                        final panelHeight =
                                            constraints.maxHeight;
                                        final headerHeight = 60.0; // 제목과 버튼 높이
                                        final padding = 32.0; // 상하 패딩
                                        final availableHeight =
                                            panelHeight -
                                            headerHeight -
                                            padding;
                                        final taskItemHeight =
                                            50.0; // 각 일정 아이템의 예상 높이

                                        // 사용 가능한 높이에 따라 일정 개수 계산
                                        int maxTasks;
                                        if (availableHeight > 200) {
                                          maxTasks = 6; // 큰 화면
                                        } else if (availableHeight > 150) {
                                          maxTasks = 4; // 중간 화면
                                        } else if (availableHeight > 100) {
                                          maxTasks = 3; // 작은 화면
                                        } else {
                                          maxTasks = 2; // 매우 작은 화면
                                        }

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '오늘${_formatDate(DateTime.now())}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        20 * (0.5 + fontSize),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const Spacer(),
                                                // 중요 버튼
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _showTodayImportantOnly =
                                                          !_showTodayImportantOnly;
                                                    });
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          _showTodayImportantOnly
                                                          ? const Color(
                                                              0xFFFFD700,
                                                            )
                                                          : Colors.white
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.star,
                                                          color:
                                                              _showTodayImportantOnly
                                                              ? Colors.black
                                                              : Colors.white,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          '중요',
                                                          style: TextStyle(
                                                            color:
                                                                _showTodayImportantOnly
                                                                ? Colors.black
                                                                : Colors.white,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              height: 12 * (0.5 + fontSize),
                                            ),
                                            if (todayTasks.isEmpty)
                                              Text(
                                                '일정이 없습니다',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize:
                                                      14 * (0.5 + fontSize),
                                                ),
                                              )
                                            else
                                              ...(_showTodayImportantOnly
                                                      ? todayTasks.where(
                                                          (task) =>
                                                              task.isImportant,
                                                        )
                                                      : todayTasks)
                                                  .take(maxTasks) // 유동적 개수
                                                  .map(
                                                    (task) => Padding(
                                                      padding: EdgeInsets.only(
                                                        bottom:
                                                            8 *
                                                            (0.5 + fontSize),
                                                      ),
                                                      child: Container(
                                                        padding: EdgeInsets.all(
                                                          8 * (0.5 + fontSize),
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            // 중요도 표시 (별표)
                                                            if (task
                                                                .isImportant)
                                                              Container(
                                                                margin: EdgeInsets.only(
                                                                  right:
                                                                      8 *
                                                                      (0.5 +
                                                                          fontSize),
                                                                ),
                                                                child: Icon(
                                                                  Icons.star,
                                                                  color: const Color(
                                                                    0xFFFFD700,
                                                                  ),
                                                                  size:
                                                                      16 *
                                                                      (0.5 +
                                                                          fontSize),
                                                                ),
                                                              ),
                                                            // 일정 제목과 시간
                                                            Expanded(
                                                              child: Row(
                                                                children: [
                                                                  Expanded(
                                                                    child: Text(
                                                                      task.title,
                                                                      style: TextStyle(
                                                                        color: Colors
                                                                            .black,
                                                                        fontSize:
                                                                            16 *
                                                                            (0.5 +
                                                                                fontSize),
                                                                        fontWeight:
                                                                            FontWeight.w900,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    width: 4,
                                                                  ),
                                                                  Text(
                                                                    _formatTime(
                                                                      task.date,
                                                                    ),
                                                                    style: TextStyle(
                                                                      color: Colors
                                                                          .black,
                                                                      fontSize:
                                                                          14 *
                                                                          (0.5 +
                                                                              fontSize),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            // 완료 상태
                                                            GestureDetector(
                                                              onTap: () {
                                                                taskProvider
                                                                    .toggleTaskCompletion(
                                                                      task.id,
                                                                    );
                                                              },
                                                              child: Icon(
                                                                task.isCompleted
                                                                    ? Icons
                                                                          .check_circle
                                                                    : Icons
                                                                          .radio_button_unchecked,
                                                                color:
                                                                    task.isCompleted
                                                                    ? Colors
                                                                          .green
                                                                    : Colors
                                                                          .grey,
                                                                size:
                                                                    20 *
                                                                    (0.5 +
                                                                        fontSize),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 12), // 패널 간 간격
                              // 내일 패널 (아래쪽)
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DateDetailScreen(
                                          date: DateTime.now().add(
                                            const Duration(days: 1),
                                          ),
                                          title: '내일',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: tomorrowTasks.isEmpty
                                          ? Colors.grey[400]
                                          : (isTomorrowCompleted
                                                ? Colors.green
                                                : Colors.red),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        // 패널 높이에 따라 보여줄 일정 개수 결정
                                        final panelHeight =
                                            constraints.maxHeight;
                                        final headerHeight = 60.0; // 제목과 버튼 높이
                                        final padding = 32.0; // 상하 패딩
                                        final availableHeight =
                                            panelHeight -
                                            headerHeight -
                                            padding;
                                        final taskItemHeight =
                                            50.0; // 각 일정 아이템의 예상 높이

                                        // 사용 가능한 높이에 따라 일정 개수 계산
                                        int maxTasks;
                                        if (availableHeight > 200) {
                                          maxTasks = 6; // 큰 화면
                                        } else if (availableHeight > 150) {
                                          maxTasks = 4; // 중간 화면
                                        } else if (availableHeight > 100) {
                                          maxTasks = 3; // 작은 화면
                                        } else {
                                          maxTasks = 2; // 매우 작은 화면
                                        }

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '내일${_formatDate(DateTime.now().add(const Duration(days: 1)))}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        20 * (0.5 + fontSize),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const Spacer(),
                                                // 중요 버튼 (내일 패널용)
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _showTomorrowImportantOnly =
                                                          !_showTomorrowImportantOnly;
                                                    });
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          _showTomorrowImportantOnly
                                                          ? const Color(
                                                              0xFFFFD700,
                                                            )
                                                          : Colors.white
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.star,
                                                          color:
                                                              _showTomorrowImportantOnly
                                                              ? Colors.black
                                                              : Colors.white,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          '중요',
                                                          style: TextStyle(
                                                            color:
                                                                _showTomorrowImportantOnly
                                                                ? Colors.black
                                                                : Colors.white,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              height: 12 * (0.5 + fontSize),
                                            ),
                                            if (tomorrowTasks.isEmpty)
                                              Text(
                                                '일정이 없습니다',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize:
                                                      14 * (0.5 + fontSize),
                                                ),
                                              )
                                            else
                                              ...(_showTomorrowImportantOnly
                                                      ? tomorrowTasks.where(
                                                          (task) =>
                                                              task.isImportant,
                                                        )
                                                      : tomorrowTasks)
                                                  .take(maxTasks) // 유동적 개수
                                                  .map(
                                                    (task) => Padding(
                                                      padding: EdgeInsets.only(
                                                        bottom:
                                                            8 *
                                                            (0.5 + fontSize),
                                                      ),
                                                      child: Container(
                                                        padding: EdgeInsets.all(
                                                          8 * (0.5 + fontSize),
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            // 중요도 표시 (별표)
                                                            if (task
                                                                .isImportant)
                                                              Container(
                                                                margin: EdgeInsets.only(
                                                                  right:
                                                                      8 *
                                                                      (0.5 +
                                                                          fontSize),
                                                                ),
                                                                child: Icon(
                                                                  Icons.star,
                                                                  color: const Color(
                                                                    0xFFFFD700,
                                                                  ),
                                                                  size:
                                                                      16 *
                                                                      (0.5 +
                                                                          fontSize),
                                                                ),
                                                              ),
                                                            // 일정 제목과 시간
                                                            Expanded(
                                                              child: Row(
                                                                children: [
                                                                  Expanded(
                                                                    child: Text(
                                                                      task.title,
                                                                      style: TextStyle(
                                                                        color: Colors
                                                                            .black,
                                                                        fontSize:
                                                                            16 *
                                                                            (0.5 +
                                                                                fontSize),
                                                                        fontWeight:
                                                                            FontWeight.w900,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    width: 4,
                                                                  ),
                                                                  Text(
                                                                    _formatTime(
                                                                      task.date,
                                                                    ),
                                                                    style: TextStyle(
                                                                      color: Colors
                                                                          .black,
                                                                      fontSize:
                                                                          14 *
                                                                          (0.5 +
                                                                              fontSize),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            // 완료 상태
                                                            GestureDetector(
                                                              onTap: () {
                                                                taskProvider
                                                                    .toggleTaskCompletion(
                                                                      task.id,
                                                                    );
                                                              },
                                                              child: Icon(
                                                                task.isCompleted
                                                                    ? Icons
                                                                          .check_circle
                                                                    : Icons
                                                                          .radio_button_unchecked,
                                                                color:
                                                                    task.isCompleted
                                                                    ? Colors
                                                                          .green
                                                                    : Colors
                                                                          .grey,
                                                                size:
                                                                    20 *
                                                                    (0.5 +
                                                                        fontSize),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16 * (0.5 + fontSize)),

                        // 일정 더보기 영역 (고정 높이)
                        Container(
                          height: 80,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CalendarScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: Colors.white,
                                      size: 24 * (0.5 + fontSize),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      '일정 더보기',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20 * (0.5 + fontSize),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16 * (0.5 + fontSize)),

                  // 하단 버튼들 (고정 크기, 맨 밑에 배치)
                  SizedBox(
                    height: 60,
                    child: Row(
                      children: [
                        // 녹음 버튼
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.mic,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '녹음',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // 설정 버튼
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.settings,
                                      size: 28,
                                      color: Colors.black,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '설정',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
