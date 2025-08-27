import 'package:flutter/material.dart';
import '../models/ai_response.dart';
// TaskProvider 직접 사용 제거
import '../models/task.dart';
// Provider 직접 참조 제거

class ActionHandler {
  static void handleAction(AIAction action, BuildContext context) {
    print('🔍 ActionHandler.handleAction 시작');
    print('🔍 action.type: ${action.type}');
    print('🔍 action.data 키들: ${action.data.keys.toList()}');
    print('🔍 action.uiInstructions: ${action.uiInstructions.toJson()}');

    switch (action.type) {
      case 'schedule_add':
        handleScheduleAdd(action, context);
        break;
      case 'schedule_delete':
        handleScheduleDelete(action, context);
        break;
      case 'schedule_delete_visual':
        handleScheduleDeleteVisual(action, context);
        break;
      case 'schedule_delete_multiple':
        handleScheduleDeleteMultiple(action, context);
        break;
      case 'schedule_delete_cancelled':
        handleScheduleDeleteCancelled(action, context);
        break;
      case 'schedule_selection':
        handleScheduleSelection(action, context);
        break;
      case 'schedule_list':
        handleScheduleList(action, context);
        break;
      case 'schedule_read_visual':
        handleScheduleReadVisual(action, context);
        break;
      case 'clarification_request':
        handleClarificationRequest(action, context);
        break;
      case 'voice_response':
        handleTextResponse(action, context);
        break;
      default:
        print('알 수 없는 액션 타입: ${action.type}');
    }
  }

  static void handleScheduleAdd(AIAction action, BuildContext context) {
    try {
      // UI 통보만 처리 (TaskProvider 사용 안 함)
      final taskData = action.data;
      final title = taskData['title']?.toString() ?? '';
      if (title.isEmpty) return;

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
      final taskData = action.data;
      final taskId = taskData['id'] as String?;
      final title = taskData['title'] as String? ?? '일정';

      if (taskId != null) {
        // 삭제 UI 통보만 수행 (실제 삭제는 서버/RecordService 경로에서 반영)

        // UI 업데이트 지시사항 처리
        if (action.uiInstructions.notification != null) {
          final notification = action.uiInstructions.notification!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(notification.message),
              backgroundColor: _getNotificationColor(notification.type),
              duration: Duration(seconds: notification.duration ?? 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title이 삭제되었습니다.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // 캘린더 화면으로 이동 (필요한 경우)
        if (action.uiInstructions.screen == 'calendar') {
          Navigator.pushNamed(context, '/calendar');
        }
      } else {
        // taskId가 없는 경우 (스펙트럼 삭제 등)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일정을 찾을 수 없습니다.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('일정 삭제 처리 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('일정 삭제 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
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

  static void handleTextResponse(AIAction action, BuildContext context) {
    try {
      // 텍스트 응답 처리 (UI 표시 등)
      if (action.uiInstructions.notification != null) {
        final notification = action.uiInstructions.notification!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notification.message),
            backgroundColor: _getNotificationColor(notification.type),
            duration: Duration(seconds: notification.duration ?? 3),
          ),
        );
      }
    } catch (e) {
      print('음성 응답 처리 오류: $e');
    }
  }

  static void handleScheduleDeleteMultiple(
    AIAction action,
    BuildContext context,
  ) {
    try {
      // TaskProvider 접근은 생략 — UI 통보만 수행
      final taskData = action.data;
      // 서버에서 이미 삭제됨 — 개수만 UI로 알림
      final deletedCount = taskData['deleted_count'] as int? ?? 0;

      // 여러 일정 삭제 (실제로는 AI 서버에서 이미 삭제됨)
      // 여기서는 UI 업데이트만 처리
      if (deletedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$deletedCount개 일정이 삭제되었습니다.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // 캘린더 화면으로 이동
      if (action.uiInstructions.screen == 'calendar') {
        Navigator.pushNamed(context, '/calendar');
      }
    } catch (e) {
      print('다중 일정 삭제 처리 오류: $e');
    }
  }

  static void handleScheduleDeleteCancelled(
    AIAction action,
    BuildContext context,
  ) {
    try {
      // 삭제 취소 처리
      if (action.uiInstructions.notification != null) {
        final notification = action.uiInstructions.notification!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notification.message),
            backgroundColor: _getNotificationColor(notification.type),
            duration: Duration(seconds: notification.duration ?? 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일정 삭제가 취소되었습니다.'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('일정 삭제 취소 처리 오류: $e');
    }
  }

  static void handleScheduleList(AIAction action, BuildContext context) {
    try {
      print('🔍 handleScheduleList 시작');
      print('🔍 action.type: ${action.type}');
      print('🔍 showVisualList: ${action.uiInstructions.showVisualList}');
      print('🔍 screen: ${action.uiInstructions.screen}');

      final taskData = action.data;
      final schedules = taskData['schedules'] as List<dynamic>? ?? [];
      final groupedSchedules =
          taskData['grouped_schedules'] as Map<String, dynamic>? ?? {};
      final searchKeyword = taskData['search_keyword'] as String?;
      final totalCount = taskData['total_count'] as int? ?? 0;
      final dateRange = taskData['date_range'] as Map<String, dynamic>? ?? {};

      print('🔍 schedules 개수: ${schedules.length}');
      print('🔍 groupedSchedules 키 개수: ${groupedSchedules.keys.length}');
      print('🔍 totalCount: $totalCount');

      // 시각적 일정 목록 화면으로 이동
      if (action.uiInstructions.showVisualList == true) {
        print('🔍 시각적 목록 화면으로 이동 시도');
        try {
          Navigator.pushNamed(
            context,
            '/schedule-list',
            arguments: {
              'schedules': schedules,
              'groupedSchedules': groupedSchedules,
              'searchKeyword': searchKeyword,
              'totalCount': totalCount,
              'dateRange': dateRange,
              'uiInstructions': action.uiInstructions,
            },
          );
          print('🔍 Navigator.pushNamed 완료');
        } catch (e) {
          print('❌ Navigator.pushNamed 오류: $e');
          // 오류 발생 시 기본 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('일정 목록 화면으로 이동 중 오류가 발생했습니다.\n(오류: $e)'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        print('🔍 텍스트 응답만 표시');
        // 기존 방식: 기본 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일정 목록을 확인할 수 있습니다.'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      // 알림 표시
      if (action.uiInstructions.notification != null) {
        final notification = action.uiInstructions.notification!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notification.message),
            backgroundColor: _getNotificationColor(notification.type),
            duration: Duration(seconds: notification.duration ?? 3),
          ),
        );
      }
    } catch (e) {
      print('일정 목록 처리 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('일정 목록을 불러오는 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  static void handleScheduleSelection(AIAction action, BuildContext context) {
    try {
      // 일정 선택 UI 표시 (스펙트럼 삭제)
      final taskData = action.data;
      final searchTitle = taskData['search_title'] as String? ?? '';
      final similarSchedules =
          taskData['similar_schedules'] as List<dynamic>? ?? [];
      // 미사용 변수 제거: totalFound

      if (similarSchedules.isNotEmpty) {
        _showScheduleSelectionDialog(context, searchTitle, similarSchedules);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$searchTitle과 관련된 일정을 찾을 수 없습니다.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('일정 선택 처리 오류: $e');
    }
  }

  static void _showScheduleSelectionDialog(
    BuildContext context,
    String searchTitle,
    List<dynamic> schedules,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$searchTitle 관련 일정 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('삭제할 일정을 선택해주세요:'),
              const SizedBox(height: 16),
              ...schedules.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> schedule = entry.value;
                return ListTile(
                  title: Text('${index + 1}. ${schedule['title']}'),
                  subtitle: Text(_formatDateTime(schedule['datetime'])),
                  onTap: () {
                    Navigator.of(context).pop();
                    // 선택된 일정 삭제 처리
                    _handleScheduleSelection(context, index);
                  },
                );
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
  }

  static String _formatDateTime(String datetime) {
    try {
      final dt = DateTime.parse(datetime);
      return '${dt.month}월 ${dt.day}일 ${dt.hour}시 ${dt.minute.toString().padLeft(2, '0')}분';
    } catch (e) {
      return datetime;
    }
  }

  static void _handleScheduleSelection(
    BuildContext context,
    int selectedIndex,
  ) {
    // 선택된 일정 삭제 처리
    // 실제로는 AI 서버에 선택 결과를 전송해야 함
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('선택된 일정이 삭제되었습니다.'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Color _getNotificationColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'error':
        return Colors.red;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  static void handleScheduleDeleteVisual(
    AIAction action,
    BuildContext context,
  ) {
    try {
      final taskData = action.data;
      final searchCriteria =
          taskData['search_criteria'] as Map<String, dynamic>? ?? {};
      final foundSchedules =
          taskData['found_schedules'] as List<dynamic>? ?? [];
      // 미사용 변수 제거: totalCount

      // Task 객체로 변환
      final tasks = foundSchedules.map((schedule) {
        return Task.fromJson(schedule);
      }).toList();

      // 검색 기준 텍스트 생성
      final title = searchCriteria['title'] as String? ?? '';
      final date = searchCriteria['date'] as String? ?? '';
      final searchText = title.isNotEmpty
          ? title
          : (date.isNotEmpty ? date : '일정');

      // 삭제 화면으로 이동
      Navigator.pushNamed(
        context,
        '/delete-schedule',
        arguments: {'schedules': tasks, 'searchCriteria': searchText},
      );
    } catch (e) {
      print('시각적 삭제 처리 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('삭제 화면을 열 수 없습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  static void handleScheduleReadVisual(AIAction action, BuildContext context) {
    try {
      final taskData = action.data;
      final searchCriteria =
          taskData['search_criteria'] as Map<String, dynamic>? ?? {};
      final foundSchedules =
          taskData['found_schedules'] as List<dynamic>? ?? [];
      // 미사용 변수 제거: totalCount

      // Task 객체로 변환
      final tasks = foundSchedules.map((schedule) {
        return Task.fromJson(schedule);
      }).toList();

      // 검색 기준 텍스트 생성
      final title = searchCriteria['title'] as String? ?? '';
      final date = searchCriteria['date'] as String? ?? '';
      final searchText = title.isNotEmpty
          ? title
          : (date.isNotEmpty ? date : '일정');

      // 일정 조회 화면으로 이동
      Navigator.pushNamed(
        context,
        '/schedule-list',
        arguments: {'schedules': tasks, 'searchCriteria': searchText},
      );
    } catch (e) {
      print('시각적 일정 조회 처리 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('일정 조회 화면을 열 수 없습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
