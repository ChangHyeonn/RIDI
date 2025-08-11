import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ai_response.dart';

class AIService {
  // 개발 환경별 서버 URL 설정
  static String get baseUrl => _getBaseUrl();

  static String _getBaseUrl() {
    // 디버그 모드에서 플랫폼별 다른 URL 사용
    if (kDebugMode) {
      if (Platform.isAndroid) {
        // Android 에뮬레이터에서 로컬 서버 접근
        return 'http://10.0.2.2:8080';
      } else if (Platform.isIOS) {
        // iOS 시뮬레이터에서 로컬 서버 접근
        return 'http://localhost:8080';
      }
    }

    // 실제 기기나 릴리즈 모드에서는 실제 IP 사용
    return 'http://192.168.1.100:8080'; // 실제 서버 IP
  }

  static Future<AIResponse> processVoice(String audioPath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v1/process_voice'),
      );

      request.files.add(await http.MultipartFile.fromPath('audio', audioPath));
      request.fields['user_id'] = 'user123';

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return AIResponse.fromJson(json.decode(responseData));
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/health'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('서버 연결 테스트 실패: $e');
      return false;
    }
  }

  static Future<void> checkServerStatus() async {
    final isConnected = await testConnection();
    if (!isConnected) {
      throw Exception('AI 서버에 연결할 수 없습니다. 서버가 실행 중인지 확인하세요.');
    }
  }
}
