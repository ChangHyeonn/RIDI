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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().initialize();
    });
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
                            height: 300, // 높이 증가 (250 -> 300)
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
                                Text(
                                  '오늘',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20 * (0.5 + fontSize), // 글씨 크기 증가
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                  ...todayTasks
                                      .take(3)
                                      .map(
                                        (task) => Padding(
                                          // 더 많은 일정 표시
                                          padding: EdgeInsets.only(
                                            bottom: 8 * (0.5 + fontSize),
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.all(
                                              8 * (0.5 + fontSize),
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    task.title,
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize:
                                                          14 * (0.5 + fontSize),
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                            height: 300, // 높이 증가 (250 -> 300)
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
                                Text(
                                  '내일',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20 * (0.5 + fontSize), // 글씨 크기 증가
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                  ...tomorrowTasks
                                      .take(3)
                                      .map(
                                        (task) => Padding(
                                          // 더 많은 일정 표시
                                          padding: EdgeInsets.only(
                                            bottom: 8 * (0.5 + fontSize),
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.all(
                                              8 * (0.5 + fontSize),
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    task.title,
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize:
                                                          14 * (0.5 + fontSize),
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.white,
                                  size: 48 * (0.5 + fontSize),
                                ),
                                SizedBox(height: 16 * (0.5 + fontSize)),
                                Text(
                                  '일정 더보기',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24 * (0.5 + fontSize),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8 * (0.5 + fontSize)),
                                Text(
                                  '전체 일정을 확인하세요',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 16 * (0.5 + fontSize),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24 * (0.5 + fontSize)),

                  // 하단 버튼들 (아이콘으로 변경)
                  Row(
                    children: [
                      // 녹음 버튼 (아이콘으로 변경)
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
                                Icon(Icons.mic, color: Colors.white, size: 28),
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
                      // 설정 버튼 (아이콘 유지)
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
