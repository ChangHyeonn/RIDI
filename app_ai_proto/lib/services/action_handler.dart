import 'package:flutter/material.dart';
import '../models/ai_response.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import 'package:provider/provider.dart';

class ActionHandler {
  static void handleAction(AIAction action, BuildContext context) {
    switch (action.type) {
      case 'schedule_add':
        handleScheduleAdd(action, context);
        break;
      case 'schedule_delete':
        handleScheduleDelete(action, context);
        break;
      case 'schedule_list':
        handleScheduleList(action, context);
        break;
      case 'clarification_request':
        handleClarificationRequest(action, context);
        break;
      case 'voice_response':
        handleVoiceResponse(action, context);
        break;
      default:
        print('알 수 없는 액션 타입: ${action.type}');
    }
  }

  static void handleScheduleAdd(AIAction action, BuildContext context) {
    try {
      final taskProvider = context.read<TaskProvider>();

      // AI 서버에서 받은 일정 데이터를 Task 모델로 변환
      final taskData = action.data;
      final title = taskData['title'] as String? ?? '';
      final datetimeStr = taskData['datetime'] as String? ?? '';

      if (title.isNotEmpty && datetimeStr.isNotEmpty) {
        final dateTime = DateTime.parse(datetimeStr);

        // Task 객체 생성
        final task = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          date: dateTime,
          isImportant: taskData['priority'] == 'important',
        );

        // TaskProvider를 통해 일정 추가
        taskProvider.addTask(task);

        // UI 업데이트 지시사항 처리
        if (action.uiInstructions.showConfirmation == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('일정이 추가되었습니다: $title'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // 캘린더 화면으로 이동 (필요한 경우)
        if (action.uiInstructions.screen == 'calendar') {
          Navigator.pushNamed(context, '/calendar');
        }
      }
    } catch (e) {
      print('일정 추가 처리 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('일정 추가 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  static void handleScheduleDelete(AIAction action, BuildContext context) {
    try {
      final taskProvider = context.read<TaskProvider>();
      final taskData = action.data;
      final taskId = taskData['id'] as String?;

      if (taskId != null) {
        // TaskProvider를 통해 일정 삭제
        // 실제 구현에서는 taskId를 사용하여 삭제
        // 현재 TaskProvider에는 id 기반 삭제가 없으므로 임시로 처리
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일정 삭제 기능은 아직 구현되지 않았습니다.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('일정 삭제 처리 오류: $e');
    }
  }

  static void handleScheduleList(AIAction action, BuildContext context) {
    try {
      final taskProvider = context.read<TaskProvider>();

      // 일정 목록 새로고침
      if (action.uiInstructions.refreshData == true) {
        taskProvider.loadTasks();
      }

      // 일정 목록 화면으로 이동 (필요한 경우)
      if (action.uiInstructions.screen == 'schedule_list') {
        Navigator.pushNamed(context, '/calendar');
      }
    } catch (e) {
      print('일정 목록 처리 오류: $e');
    }
  }

  static void handleClarificationRequest(
    AIAction action,
    BuildContext context,
  ) {
    try {
      final message = action.data['message'] as String? ?? '추가 정보가 필요합니다.';

      // 명확화 요청 다이얼로그 표시
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('추가 정보 필요'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('명확화 요청 처리 오류: $e');
    }
  }

  static void handleVoiceResponse(AIAction action, BuildContext context) {
    try {
      // 음성 응답 처리 (UI 표시 등)
      if (action.uiInstructions.showVoiceIndicator == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('음성 응답을 재생합니다.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('음성 응답 처리 오류: $e');
    }
  }
}
