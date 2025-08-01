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

  // 날짜 포맷 (월/일)
  String _formatDate(DateTime date) {
    return '(${date.month}/${date.day})';
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
                  // 상단 두 개의 패널 (크기 증가)
                  Row(
                    children: [
                      // 오늘 패널
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
                            height: 400, // 높이 증가 (300 -> 400)
                            decoration: BoxDecoration(
                              color: todayTasks.isEmpty
                                  ? Colors.grey[400]
                                  : (isTodayCompleted
                                        ? Colors.green
                                        : Colors.red),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '오늘${_formatDate(DateTime.now())}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20 * (0.5 + fontSize),
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _showTodayImportantOnly
                                              ? const Color(0xFFFFD700)
                                              : Colors.white.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: _showTodayImportantOnly
                                                  ? Colors.black
                                                  : Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '중요',
                                              style: TextStyle(
                                                color: _showTodayImportantOnly
                                                    ? Colors.black
                                                    : Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12 * (0.5 + fontSize)),
                                if (todayTasks.isEmpty)
                                  Text(
                                    '일정이 없습니다',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14 * (0.5 + fontSize),
                                    ),
                                  )
                                else
                                  ...(_showTodayImportantOnly
                                          ? todayTasks.where(
                                              (task) => task.isImportant,
                                            )
                                          : todayTasks)
                                      .take(2) // 화면 크기에 맞게 더 보수적으로 조정
                                      .map(
                                        (task) => Padding(
                                          padding: EdgeInsets.only(
                                            bottom: 8 * (0.5 + fontSize),
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.all(
                                              8 * (0.5 + fontSize),
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                // 중요도 표시 (별표)
                                                if (task.isImportant)
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          right: 8,
                                                        ),
                                                    child: const Icon(
                                                      Icons.star,
                                                      color: Color(0xFFFFD700),
                                                      size: 16,
                                                    ),
                                                  ),
                                                // 일정 제목과 시간 (수정)
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          task.title,
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize:
                                                                14 *
                                                                (0.5 +
                                                                    fontSize),
                                                            fontWeight:
                                                                FontWeight.w900,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _formatTime(task.date),
                                                        style: TextStyle(
                                                          color: Colors.black54,
                                                          fontSize:
                                                              12 *
                                                              (0.5 + fontSize),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: task.isCompleted
                                                        ? Colors.green
                                                        : Colors.red,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    task.isCompleted
                                                        ? Icons.check
                                                        : Icons.remove,
                                                    color: Colors.white,
                                                    size: 12 * (0.5 + fontSize),
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
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 내일 패널
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
                            height: 400, // 높이 증가 (300 -> 400)
                            decoration: BoxDecoration(
                              color: tomorrowTasks.isEmpty
                                  ? Colors.grey[400]
                                  : (isTomorrowCompleted
                                        ? Colors.green
                                        : Colors.red),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '내일${_formatDate(DateTime.now().add(const Duration(days: 1)))}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20 * (0.5 + fontSize),
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _showTomorrowImportantOnly
                                              ? const Color(0xFFFFD700)
                                              : Colors.white.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: _showTomorrowImportantOnly
                                                  ? Colors.black
                                                  : Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '중요',
                                              style: TextStyle(
                                                color:
                                                    _showTomorrowImportantOnly
                                                    ? Colors.black
                                                    : Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12 * (0.5 + fontSize)),
                                if (tomorrowTasks.isEmpty)
                                  Text(
                                    '일정이 없습니다',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14 * (0.5 + fontSize),
                                    ),
                                  )
                                else
                                  ...(_showTomorrowImportantOnly
                                          ? tomorrowTasks.where(
                                              (task) => task.isImportant,
                                            )
                                          : tomorrowTasks)
                                      .take(2) // 화면 크기에 맞게 더 보수적으로 조정
                                      .map(
                                        (task) => Padding(
                                          padding: EdgeInsets.only(
                                            bottom: 8 * (0.5 + fontSize),
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.all(
                                              8 * (0.5 + fontSize),
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                // 중요도 표시 (별표)
                                                if (task.isImportant)
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          right: 8,
                                                        ),
                                                    child: const Icon(
                                                      Icons.star,
                                                      color: Color(0xFFFFD700),
                                                      size: 16,
                                                    ),
                                                  ),
                                                // 일정 제목과 시간 (수정)
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          task.title,
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize:
                                                                14 *
                                                                (0.5 +
                                                                    fontSize),
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _formatTime(task.date),
                                                        style: TextStyle(
                                                          color: Colors.black54,
                                                          fontSize:
                                                              12 *
                                                              (0.5 + fontSize),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: task.isCompleted
                                                        ? Colors.green
                                                        : Colors.red,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    task.isCompleted
                                                        ? Icons.check
                                                        : Icons.remove,
                                                    color: Colors.white,
                                                    size: 12 * (0.5 + fontSize),
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
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24 * (0.5 + fontSize)),

                  // 일정 더보기 영역 (Expanded로 변경하여 남은 공간 모두 차지)
                  Expanded(
                    child: Container(
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
                                builder: (context) => const CalendarScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // 화면 크기에 따라 반응형 조정
                                final isSmallScreen =
                                    constraints.maxWidth < 400;
                                final isMediumScreen =
                                    constraints.maxWidth < 600;

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: Colors.white,
                                      size: isSmallScreen
                                          ? 24
                                          : (isMediumScreen ? 32 : 48) *
                                                (0.5 + fontSize),
                                    ),
                                    SizedBox(width: isSmallScreen ? 8 : 12),
                                    if (!isSmallScreen) ...[
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '일정 더보기',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize:
                                                    (isMediumScreen ? 18 : 24) *
                                                    (0.5 + fontSize),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(
                                              height: 8 * (0.5 + fontSize),
                                            ),
                                            Text(
                                              '전체 일정을 확인하세요',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.8,
                                                ),
                                                fontSize:
                                                    (isMediumScreen ? 12 : 16) *
                                                    (0.5 + fontSize),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        '일정 더보기',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16 * (0.5 + fontSize),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24 * (0.5 + fontSize)),

                  // 하단 버튼들 (고정 크기 유지)
                  SizedBox(
                    height: 60,
                    child: Row(
                      children: [
                        // 녹음 버튼 (고정 크기)
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
                        // 설정 버튼 (고정 크기)
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
