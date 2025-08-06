import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            print('🔧 설정 화면 - 현재 볼륨: ${taskProvider.soundVolume}');
            print('🔧 설정 화면 - 현재 글씨 크기: ${taskProvider.fontSize}');

            return Column(
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
                          '설정',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9C27B0),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // 뒤로가기 버튼과 균형 맞추기
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 소리 크기 슬라이더
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '소리크기: ${(taskProvider.soundVolume * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9C27B0),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF9C27B0),
                          inactiveTrackColor: const Color(0xFFE1BEE7),
                          thumbColor: Colors.black,
                          overlayColor: Colors.transparent,
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: taskProvider.soundVolume,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (value) {
                            print('🔊 슬라이더 변경: $value');
                            taskProvider.setSoundVolume(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 글씨 크기 슬라이더
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '글씨크기: ${(taskProvider.fontSize * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9C27B0),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF9C27B0),
                          inactiveTrackColor: const Color(0xFFE1BEE7),
                          thumbColor: Colors.black,
                          overlayColor: Colors.transparent,
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: taskProvider.fontSize,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (value) {
                            print('📝 글씨 크기 슬라이더 변경: $value');
                            taskProvider.setFontSize(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),
              ],
            );
          },
        ),
      ),
    );
  }
}
