import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      // 간단한 로그인 로직 (실제로는 서버 인증이 필요)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final fontSize = taskProvider.fontSize;
        final baseFontSize = 32.0;
        final adjustedFontSize = baseFontSize * (0.5 + fontSize);
        
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 앱 제목
                    Text(
                      '메모알림앱',
                      style: TextStyle(
                        fontSize: adjustedFontSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6B73FF),
                      ),
                    ),
                    SizedBox(height: 48 * (0.5 + fontSize)),
                    
                    // 아이디 입력 필드
                    TextFormField(
                      controller: _usernameController,
                      style: TextStyle(fontSize: 16 * (0.5 + fontSize)),
                      decoration: InputDecoration(
                        labelText: '아이디',
                        labelStyle: TextStyle(fontSize: 14 * (0.5 + fontSize)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF6B73FF)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '아이디를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16 * (0.5 + fontSize)),
                    
                    // 비밀번호 입력 필드
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(fontSize: 16 * (0.5 + fontSize)),
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        labelStyle: TextStyle(fontSize: 14 * (0.5 + fontSize)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF6B73FF)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 32 * (0.5 + fontSize)),
                    
                    // 시작하기 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9C27B0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '시작하기',
                          style: TextStyle(
                            fontSize: 18 * (0.5 + fontSize),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 