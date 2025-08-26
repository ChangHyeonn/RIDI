import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class NetworkService {
  static const String baseUrl = 'http://172.30.1.98:8080'; // AI 서버 URL

  // 서버에서 일정 가져오기
  static Future<List<Task>> fetchSchedulesFromServer(
    String userId,
    DateTime? lastSync,
  ) async {
    try {
      String url = '$baseUrl/api/v1/sync/schedules/$userId';

      if (lastSync != null) {
        final sinceTimestamp = lastSync.toIso8601String();
        url = '$baseUrl/api/v1/sync/schedules/$userId/since/$sinceTimestamp';
      }

      print('📡 서버에서 일정 가져오기: $url');

      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final schedules = data['schedules'] as List;
          return schedules.map((json) => Task.fromJson(json)).toList();
        } else {
          print('❌ 서버 응답 오류: ${data['error']}');
          return [];
        }
      } else {
        print('❌ HTTP 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ 네트워크 오류: $e');
      return [];
    }
  }

  // 서버에 일정 업로드
  static Future<bool> uploadScheduleToServer(Task task) async {
    try {
      final url = '$baseUrl/api/v1/sync/schedules';

      final requestBody = {
        'user_id': 'user123', // 현재는 고정
        'schedule_info': task.toJson(),
      };

      print('📤 서버에 일정 업로드: ${task.title}');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ 일정 업로드 성공: ${task.title}');
          return true;
        } else {
          print('❌ 서버 응답 오류: ${data['error']}');
          return false;
        }
      } else {
        print('❌ HTTP 오류: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ 네트워크 오류: $e');
      return false;
    }
  }

  // 서버 연결 테스트
  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/v1/sync/schedules/user123'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ 서버 연결 실패: $e');
      return false;
    }
  }

  // 서버에서 일정 삭제
  static Future<bool> deleteScheduleFromServer(
    String scheduleId,
    String userId,
  ) async {
    try {
      final url = '$baseUrl/api/v1/delete_schedule/$scheduleId?user_id=$userId';

      print('🗑️ 서버에서 일정 삭제: $scheduleId');

      final response = await http
          .delete(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ 서버 일정 삭제 성공: ${data['deleted_title']}');
          return true;
        } else {
          print('❌ 서버 응답 오류: ${data['error']}');
          return false;
        }
      } else {
        print('❌ HTTP 오류: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ 네트워크 오류: $e');
      return false;
    }
  }
}
