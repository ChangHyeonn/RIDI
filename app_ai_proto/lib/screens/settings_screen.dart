import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/global_voice_button.dart';
import '../services/ai_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfafafa),
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
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1f2937),
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF6366f1),
                          inactiveTrackColor: const Color(0xFFd1d5db),
                          thumbColor: const Color(0xFF6366f1),
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

                // 글씨 크기 슬라이더 (실시간 미리보기 반영)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '글씨크기: ${(taskProvider.fontSize * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF6366f1),
                          inactiveTrackColor: const Color(0xFFd1d5db),
                          thumbColor: const Color(0xFF6366f1),
                          overlayColor: Colors.transparent,
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: taskProvider.fontSize,
                          min: 0.25,
                          max: 0.75,
                          onChanged: (value) {
                            print('📝 글씨 크기 슬라이더 변경: $value');
                            taskProvider.setFontSize(value);
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // AI 서버 연결 테스트 버튼 (슬라이더 바로 아래)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10b981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            try {
                              final isConnected =
                                  await AIService.testConnection();
                              final snack = SnackBar(
                                content: Text(
                                  isConnected
                                      ? 'AI 서버에 연결되었습니다.'
                                      : 'AI 서버에 연결할 수 없습니다.',
                                ),
                                backgroundColor: isConnected
                                    ? Colors.green
                                    : Colors.red,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(snack);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('연결 테스트 중 오류: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.wifi_tethering),
                          label: const Text(
                            'AI 서버 연결 테스트',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
      floatingActionButton: const GlobalVoiceButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
