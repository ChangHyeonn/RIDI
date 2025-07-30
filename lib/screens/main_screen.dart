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
                  // 상단 두 개의 패널
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
                            height: 120,
                            decoration: BoxDecoration(
                              color: isTodayCompleted ? Colors.green : Colors.red,
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
                                    fontSize: 18 * (0.5 + fontSize),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8 * (0.5 + fontSize)),
                                ...todayTasks.take(2).map((task) => Padding(
                                  padding: EdgeInsets.only(bottom: 4 * (0.5 + fontSize)),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          task.title,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14 * (0.5 + fontSize),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(
                                        task.isCompleted
                                            ? Icons.check_circle
                                            : Icons.remove,
                                        color: Colors.white,
                                        size: 16 * (0.5 + fontSize),
                                      ),
                                    ],
                                  ),
                                )),
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
                                  date: DateTime.now().add(const Duration(days: 1)),
                                  title: '내일',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: isTomorrowCompleted ? Colors.green : Colors.red,
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
                                    fontSize: 18 * (0.5 + fontSize),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8 * (0.5 + fontSize)),
                                ...tomorrowTasks.take(2).map((task) => Padding(
                                  padding: EdgeInsets.only(bottom: 4 * (0.5 + fontSize)),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          task.title,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14 * (0.5 + fontSize),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(
                                        task.isCompleted
                                            ? Icons.check_circle
                                            : Icons.remove,
                                        color: Colors.white,
                                        size: 16 * (0.5 + fontSize),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24 * (0.5 + fontSize)),
                  
                  // 일정 더보기 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CalendarScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '일정더보기',
                        style: TextStyle(
                          fontSize: 18 * (0.5 + fontSize),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  
                  // 하단 버튼들
                  Row(
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
                            child: Text(
                              '녹음',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16 * (0.5 + fontSize),
                                fontWeight: FontWeight.bold,
                              ),
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
                            child: const Center(
                              child: Icon(
                                Icons.settings,
                                size: 24,
                                color: Colors.black,
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