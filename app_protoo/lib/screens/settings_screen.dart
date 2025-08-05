import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _soundVolume = 0.5;
  double _fontSize = 0.5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = context.read<TaskProvider>();
      setState(() {
        _soundVolume = taskProvider.soundVolume;
        _fontSize = taskProvider.fontSize;
      });
    });
  }

  void _updateSettings() {
    context.read<TaskProvider>().setFontSize(_fontSize);
  }

  void _updateSoundVolume() {
    context.read<TaskProvider>().setSoundVolume(_soundVolume);
  }

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
                  const Text(
                    '소리크기',
                    style: TextStyle(
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
                      value: _soundVolume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (value) {
                        setState(() {
                          _soundVolume = value;
                        });
                        _updateSoundVolume();
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
                  const Text(
                    '글씨크기',
                    style: TextStyle(
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
                      value: _fontSize,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (value) {
                        setState(() {
                          _fontSize = value;
                        });
                        _updateSettings();
                      },
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 탈퇴 버튼
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('탈퇴 확인'),
                        content: const Text('정말로 탈퇴하시겠습니까?\n모든 데이터가 삭제됩니다.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () {
                              // 탈퇴 로직 구현
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: const Text('탈퇴'),
                          ),
                        ],
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
                    '탈퇴',
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
