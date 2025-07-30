import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TaskProvider(),
      child: MaterialApp(
        title: '메모알림앱',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const LoginScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
