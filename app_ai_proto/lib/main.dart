import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/task_provider.dart';
import 'screens/login_screen.dart';
import 'screens/schedule_list_screen.dart';
import 'screens/delete_schedule_screen.dart';
import 'models/task.dart';
// 사용되지 않는 import 제거
import 'permissions_init.dart';

// 전역 NavigatorKey 정의
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // iOS 18.6 검은 화면 문제 해결을 위한 초기화 순서
  WidgetsFlutterBinding.ensureInitialized();

  // iOS 권한 초기화
  await initializeDateFormatting('ko_KR', null);

  // 앱 실행 후 권한 요청 (첫 프레임 렌더링 방해 방지)
  runApp(const MyApp());

  // 앱 실행 후 권한 요청
  Future.delayed(const Duration(milliseconds: 1000), () async {
    try {
      await PermissionsInit.requestNecessaryPermissions();
      print('✅ iOS 18.6 권한 초기화 완료');
    } catch (e) {
      print('❌ iOS 18.6 권한 초기화 중 오류: $e');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TaskProvider(),
      child: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          // 0.75~1.5 범위에서 전역 텍스트 스케일 적용 (기본 1.0)
          final textScale = 0.75 + taskProvider.fontSize * 0.75;
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: MaterialApp(
              navigatorKey: navigatorKey, // 전역 NavigatorKey 설정
              title: '메모알림앱',
              theme: ThemeData(
                primarySwatch: Colors.purple,
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('ko', 'KR')],
              home: const LoginScreen(),
              routes: {
                '/delete-schedule': (context) {
                  final Object? args = ModalRoute.of(
                    context,
                  )?.settings.arguments;
                  final Map<String, dynamic> arguments = (args is Map)
                      ? Map<String, dynamic>.from(args)
                      : {};
                  return DeleteScheduleScreen(
                    schedules:
                        (arguments['schedules'] as List?)?.cast<Task>() ??
                        const <Task>[],
                    searchCriteria:
                        arguments['searchCriteria']?.toString() ?? '',
                  );
                },
                '/schedule-list': (context) {
                  final Object? args = ModalRoute.of(
                    context,
                  )?.settings.arguments;
                  final Map<String, dynamic> arguments = (args is Map)
                      ? Map<String, dynamic>.from(args)
                      : {};
                  return ScheduleListScreen(
                    schedules:
                        (arguments['schedules'] as List?)?.cast<Task>() ??
                        const <Task>[],
                    searchCriteria:
                        arguments['searchCriteria']?.toString() ?? '',
                  );
                },
              },
              debugShowCheckedModeBanner: false,
            ),
          );
        },
      ),
    );
  }
}

class PatchedAppFallback extends StatelessWidget {
  const PatchedAppFallback({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(child: Text('🏁 Flutter iOS 초기화 완료 — 화면 구성 대기 중')),
      ),
    );
  }
}
