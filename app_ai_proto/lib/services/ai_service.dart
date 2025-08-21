import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ai_response.dart';

class AIService {
  // 개발 환경별 서버 URL 설정
  static String get baseUrl => _getBaseUrl();

  static String _getBaseUrl() {
    // 웹 환경에서는 Platform 클래스 사용 불가
    if (kIsWeb) {
      // 웹 환경에서는 로컬 서버 IP 사용
      return 'http://172.20.150.140:8080';
    }

    // 디버그 모드에서 플랫폼별 다른 URL 사용
    if (kDebugMode) {
      if (Platform.isAndroid) {
        // Android 에뮬레이터에서 로컬 서버 접근
        return 'http://172.20.150.140:8080';
      } else if (Platform.isIOS) {
        // iOS 시뮬레이터에서 로컬 서버 접근
        return 'http://172.20.150.140:8080';
      }
    }

    // 실제 기기나 릴리즈 모드에서는 실제 IP 사용
    return 'http://172.20.150.140:8080'; // 실제 서버 IP
  }

  static Future<AIResponse> processVoice(String audioPath) async {
    print('=== AI 음성 처리 시작 ===');
    print('서버 URL: $baseUrl');
    print('오디오 파일 경로: $audioPath');

    try {
      // 서버 연결 상태 먼저 확인
      print('서버 연결 상태 확인 중...');
      final isConnected = await testConnection();
      if (!isConnected) {
        print('❌ 서버 연결 실패 - 서버가 실행 중인지 확인하세요');
        throw Exception('AI 서버에 연결할 수 없습니다. 서버가 실행 중인지 확인하세요.');
      }
      print('✅ 서버 연결 성공');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v1/process_voice'),
      );

      print('📤 요청 준비 중...');
      request.files.add(await http.MultipartFile.fromPath('audio', audioPath));
      request.fields['user_id'] = 'user123';

      print('📡 서버에 요청 전송 중...');
      final startTime = DateTime.now();
      var response = await request.send();
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      print('📥 서버 응답 수신 완료');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 시간: ${duration.inMilliseconds}ms');

      var responseData = await response.stream.bytesToString();
      print('응답 데이터 크기: ${responseData.length} bytes');

      // 200(성공)과 400(오류) 모두 정상적인 응답으로 처리
      if (response.statusCode == 200 || response.statusCode == 400) {
        print('📥 서버 응답 수신 완료');
        print('응답 데이터: $responseData');

        final aiResponse = AIResponse.fromJson(json.decode(responseData));
        print('=== AI 응답 분석 ===');
        print('응답 성공 여부: ${aiResponse.success}');
        print('응답 타임스탬프: ${aiResponse.timestamp}');
        if (aiResponse.processingResult != null) {
          print('처리 결과 액션: ${aiResponse.processingResult!.action}');
          print('처리 결과 데이터: ${aiResponse.processingResult!.result}');
        }
        if (aiResponse.responseText != null) {
          print('응답 텍스트: ${aiResponse.responseText}');
        }
        print('====================');

        return aiResponse;
      } else {
        print('❌ 서버 오류 발생');
        print('오류 상태 코드: ${response.statusCode}');
        print('오류 응답: $responseData');
        throw Exception('서버 오류: ${response.statusCode} - $responseData');
      }
    } catch (e) {
      print('❌ AI 음성 처리 실패');
      print('오류 내용: $e');
      print('오류 타입: ${e.runtimeType}');

      if (e is SocketException) {
        print('네트워크 연결 오류 - 서버가 실행 중인지 확인하세요');
      } else if (e is TimeoutException) {
        print('요청 시간 초과 - 서버 응답이 너무 느립니다');
      }

      throw Exception('네트워크 오류: $e');
    }
  }

  // 텍스트 처리 API (새로 추가)
  static Future<AIResponse> processText(String text) async {
    print('=== AI 텍스트 처리 시작 ===');
    print('서버 URL: $baseUrl');
    print('처리할 텍스트: $text');

    try {
      // 서버 연결 확인 임시 비활성화 (디버깅용)
      print('⚠️ 서버 연결 사전 확인 건너뜀 (디버깅)');
      // final isConnected = await testConnection();
      // if (!isConnected) {
      //   print('❌ 서버 연결 실패 - 서버가 실행 중인지 확인하세요');
      //   throw Exception('AI 서버에 연결할 수 없습니다. 서버가 실행 중인지 확인하세요.');
      // }
      // print('✅ 서버 연결 성공');

      final requestBody = {
        'text': text,
        'user_id': 'user123',
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('📤 요청 준비 중...');
      print('요청 데이터: $requestBody');

      print('📡 서버에 요청 전송 중...');
      print('📡 요청 URL: $baseUrl/api/v1/process_text');
      print('📡 요청 헤더: {"Content-Type": "application/json"}');
      print('📡 요청 본문: ${json.encode(requestBody)}');

      // 타임아웃 30초 유지, 1회 재시도 (백오프)
      const timeoutDuration = Duration(seconds: 30);
      const maxAttempts = 1;
      Object? lastError;
      late http.Response response;
      late DateTime startTime;
      late DateTime endTime;

      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          print(
            '📡 요청 시도 $attempt/$maxAttempts (타임아웃: ${timeoutDuration.inSeconds}s)',
          );
          startTime = DateTime.now();
          response = await http
              .post(
                Uri.parse('$baseUrl/api/v1/process_text'),
                headers: {'Content-Type': 'application/json'},
                body: json.encode(requestBody),
              )
              .timeout(timeoutDuration);
          endTime = DateTime.now();
          break; // 성공 시 루프 탈출
        } catch (e) {
          lastError = e;
          print('⚠️ 요청 시도 $attempt 실패: $e');
          if (attempt < maxAttempts) {
            print('⏳ 재시도 전 대기 800ms');
            await Future.delayed(const Duration(milliseconds: 800));
            continue;
          } else {
            rethrow; // 최종 실패는 상위에서 처리
          }
        }
      }
      final duration = endTime.difference(startTime);

      print('📥 서버 응답 수신 완료');
      print('⏱️ 응답 시간: ${duration.inMilliseconds}ms');
      print('📊 응답 상태 코드: ${response.statusCode}');
      print('📋 응답 헤더: ${response.headers}');

      var responseData = response.body;
      // 선행 BOM 제거 (일부 서버/프록시 환경에서 발생)
      if (responseData.isNotEmpty && responseData.codeUnitAt(0) == 0xFEFF) {
        print('⚠️ 응답 앞의 BOM(\uFEFF) 제거');
        responseData = responseData.substring(1);
      }
      print('📄 응답 데이터 크기: ${responseData.length} bytes');
      print('📄 원본 응답 데이터:');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print(responseData);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // JSON 형식 검증
      if (responseData.trim().isEmpty) {
        print('❌ 응답 데이터가 비어있습니다!');
        throw Exception('서버에서 빈 응답을 받았습니다.');
      }

      // JSON 형식인지 확인
      if (!responseData.trim().startsWith('{') &&
          !responseData.trim().startsWith('[')) {
        print('❌ 응답이 JSON 형식이 아닙니다!');
        print(
          '응답 시작 부분: ${responseData.substring(0, responseData.length > 100 ? 100 : responseData.length)}',
        );
        throw Exception('서버 응답이 JSON 형식이 아닙니다.');
      }

      // 2xx(성공)과 4xx(클라이언트 오류)는 본문 JSON을 정상적으로 처리
      if ((response.statusCode >= 200 && response.statusCode < 300) ||
          (response.statusCode >= 400 && response.statusCode < 500)) {
        print('✅ 서버 응답 성공');
        print('📊 응답 상태 코드: ${response.statusCode}');

        try {
          print('🔍 JSON 파싱 시작...');
          final jsonData = json.decode(responseData);
          print('🔍 JSON 파싱 완료');

          // JSON 구조 분석
          print('📋 파싱된 JSON 구조:');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          _printJsonStructure(jsonData, 0);
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

          // JSON 키 분석
          print('🔍 JSON 키 분석:');
          if (jsonData is Map<String, dynamic>) {
            print('📋 최상위 키들: ${jsonData.keys.toList()}');

            // success 필드 확인
            if (jsonData.containsKey('success')) {
              print(
                '✅ success 필드 발견: ${jsonData['success']} (타입: ${jsonData['success'].runtimeType})',
              );
            } else {
              print('⚠️ success 필드 없음');
            }

            // action 필드 확인 (AI_03 구형 구조)
            if (jsonData.containsKey('action')) {
              print('✅ action 필드 발견 (AI_03 구형 구조)');
              final action = jsonData['action'];
              if (action is Map<String, dynamic>) {
                print('  - action.type: ${action['type']}');
                print(
                  '  - action.data 키들: ${action['data'] is Map ? (action['data'] as Map).keys.toList() : 'data가 Map이 아님'}',
                );
              }
            } else {
              print('⚠️ action 필드 없음');
            }

            // text_response 필드 확인 (AI_03 구형 구조)
            if (jsonData.containsKey('text_response')) {
              print('✅ text_response 필드 발견 (AI_03 구형 구조)');
              final textResponse = jsonData['text_response'];
              if (textResponse is Map<String, dynamic>) {
                print('  - text_response.text: ${textResponse['text']}');
                print(
                  '  - text_response.display_automatically: ${textResponse['display_automatically']}',
                );
              }
            } else {
              print('⚠️ text_response 필드 없음');
            }

            // processing_result 필드 확인 (AI_02 신형 구조)
            if (jsonData.containsKey('processing_result')) {
              print('✅ processing_result 필드 발견 (AI_02 신형 구조)');
            } else {
              print('⚠️ processing_result 필드 없음');
            }

            // response_text 필드 확인 (AI_02 신형 구조)
            if (jsonData.containsKey('response_text')) {
              print(
                '✅ response_text 필드 발견 (AI_02 신형 구조): ${jsonData['response_text']}',
              );
            } else {
              print('⚠️ response_text 필드 없음');
            }
          }

          print('🔍 AIResponse.fromJson 호출 시작...');
          final aiResponse = AIResponse.fromJson(jsonData);
          // 수신한 JSON 구조를 통째로 로깅 (디버깅용)
          try {
            final pretty = const JsonEncoder.withIndent(
              '  ',
            ).convert(aiResponse.toJson());
            print('🧾 수신 JSON 정규화 결과:\n$pretty');
          } catch (e) {
            print('수신 JSON pretty-print 중 오류: $e');
          }
          print('🤖 === AI 응답 분석 ===');
          print('✅ 응답 성공 여부: ${aiResponse.success}');
          print('⏰ 응답 타임스탬프: ${aiResponse.timestamp}');

          if (aiResponse.processingResult != null) {
            print('🎯 처리 결과 정보:');
            print('   액션: ${aiResponse.processingResult!.action}');
            print('   결과: ${aiResponse.processingResult!.result}');
          }

          if (aiResponse.responseText != null) {
            print('🔊 응답 텍스트 정보:');
            print('   텍스트: ${aiResponse.responseText}');
          }

          print('⏰ AI 처리 완료 시간: ${DateTime.now().toIso8601String()}');
          print('🤖 === AI 응답 분석 완료 ===');
          return aiResponse;
        } catch (e) {
          print('❌ AI 응답 파싱 오류: $e');
          print('📄 파싱 실패한 응답: $responseData');
          throw Exception('AI 응답 파싱 오류: $e');
        }
      } else {
        // 5xx 등 서버 오류일 때도 응답 본문이 JSON이면 파싱 시도하여 메시지 표시
        print('⚠️ 서버 오류 상태 코드: ${response.statusCode}');
        try {
          final jsonData = json.decode(responseData);
          final aiResponse = AIResponse.fromJson(jsonData);
          print('⚠️ 서버 오류 코드이지만 JSON 파싱 성공 — 에러 메시지 전달');
          return aiResponse;
        } catch (_) {
          print('❌ 서버 오류 및 JSON 아님 — 예외로 처리');
          print('📄 오류 응답: $responseData');
          print('⏰ 오류 발생 시간: ${DateTime.now().toIso8601String()}');
          throw Exception('서버 오류: ${response.statusCode} - $responseData');
        }
      }
    } catch (e) {
      print('❌ AI 텍스트 처리 실패');
      print('🔍 오류 내용: $e');
      print('🔍 오류 타입: ${e.runtimeType}');
      print('⏰ 오류 발생 시간: ${DateTime.now().toIso8601String()}');

      if (e is SocketException) {
        print('🔌 소켓 오류 - 서버가 실행되지 않았거나 네트워크 문제');
        print('🔍 소켓 오류 세부사항: ${e.message}');
        print('🔍 소켓 오류 주소: ${e.address}');
        print('🔍 소켓 오류 포트: ${e.port}');
      } else if (e is TimeoutException) {
        print('⏰ 시간 초과 - 서버 응답이 너무 느림 (30초 초과)');
      } else if (e.toString().contains('XMLHttpRequest')) {
        print('🌐 웹 환경 CORS 오류 가능성');
      }

      print('💡 해결 방법:');
      print('   1. AI 서버가 실행 중인지 확인');
      print('   2. 서버 URL 확인: $baseUrl');
      print('   3. 방화벽 설정 확인');
      print('   4. 네트워크 연결 상태 확인');
      print('   5. 서버 로그 확인');

      print('⏰ AI 텍스트 처리 실패 시간: ${DateTime.now().toIso8601String()}');
      print('🤖 === AI 텍스트 처리 실패 ===');
      throw Exception('AI 텍스트 처리 오류: $e');
    }
  }

  static Future<bool> testConnection() async {
    print('=== 서버 연결 테스트 시작 ===');
    print('테스트 URL: $baseUrl/api/v1/health');

    try {
      final startTime = DateTime.now();
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/v1/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      print('연결 테스트 응답 시간: ${duration.inMilliseconds}ms');
      print('응답 상태 코드: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');
      print('응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          // 복잡한 응답 구조에서 status 찾기
          String? status;
          if (data['status'] != null) {
            status = data['status'];
          } else if (data['action'] != null && data['action']['data'] != null) {
            status = data['action']['data']['status'];
          }

          final success = status == 'healthy';
          print('서버 상태: ${success ? "정상" : "오류"}');
          print('서버 정보: $data');
          return success;
        } catch (e) {
          print('응답 파싱 오류: $e');
          return false;
        }
      } else {
        print('서버 응답 오류: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('서버 연결 테스트 실패: $e');
      print('오류 타입: ${e.runtimeType}');

      if (e is SocketException) {
        print('소켓 오류 - 서버가 실행되지 않았거나 네트워크 문제');
      } else if (e is TimeoutException) {
        print('시간 초과 - 서버 응답이 너무 느림');
      }

      return false;
    }
  }

  static Future<void> checkServerStatus() async {
    print('=== 서버 상태 확인 ===');
    final isConnected = await testConnection();
    if (!isConnected) {
      print('❌ 서버 연결 실패');
      throw Exception('AI 서버에 연결할 수 없습니다. 서버가 실행 중인지 확인하세요.');
    }
    print('✅ 서버 연결 성공');
  }

  // 서버 상태 상세 정보 조회
  static Future<Map<String, dynamic>> getServerInfo() async {
    print('=== 서버 상세 정보 조회 ===');
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/v1/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('서버 정보: $data');
        return data;
      } else {
        print('서버 정보 조회 실패: ${response.statusCode}');
        return {'error': '서버 정보 조회 실패'};
      }
    } catch (e) {
      print('서버 정보 조회 오류: $e');
      return {'error': '서버 정보 조회 오류: $e'};
    }
  }

  // 네트워크 상태 진단
  static Future<void> diagnoseNetwork() async {
    print('=== 네트워크 진단 시작 ===');
    print('현재 플랫폼: ${Platform.operatingSystem}');
    print('서버 URL: $baseUrl');

    try {
      // DNS 확인
      print('DNS 확인 중...');
      final uri = Uri.parse(baseUrl);
      print('호스트: ${uri.host}');
      print('포트: ${uri.port}');

      // 연결 테스트
      await checkServerStatus();
      print('✅ 네트워크 진단 완료 - 정상');
    } catch (e) {
      print('❌ 네트워크 진단 실패: $e');
      print('해결 방법:');
      print('1. AI 서버가 실행 중인지 확인');
      print('2. 방화벽 설정 확인');
      print('3. 네트워크 연결 상태 확인');
    }
  }

  // 간단한 연결 테스트 (UI에서 호출용)
  static Future<Map<String, dynamic>> quickConnectionTest() async {
    print('=== 빠른 연결 테스트 ===');
    final result = <String, dynamic>{};

    try {
      final startTime = DateTime.now();
      final isConnected = await testConnection();
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      result['success'] = isConnected;
      result['responseTime'] = duration.inMilliseconds;
      result['timestamp'] = DateTime.now().toIso8601String();

      if (isConnected) {
        result['message'] = '서버 연결 성공';
        result['status'] = 'connected';
      } else {
        result['message'] = '서버 연결 실패';
        result['status'] = 'disconnected';
      }

      print('연결 테스트 결과: $result');
      return result;
    } catch (e) {
      result['success'] = false;
      result['error'] = e.toString();
      result['message'] = '연결 테스트 중 오류 발생';
      result['status'] = 'error';
      result['timestamp'] = DateTime.now().toIso8601String();

      print('연결 테스트 오류: $result');
      return result;
    }
  }

  // 서버 정보 요약 (UI 표시용)
  static Future<Map<String, dynamic>> getServerSummary() async {
    print('=== 서버 정보 요약 ===');
    try {
      final serverInfo = await getServerInfo();

      if (serverInfo.containsKey('error')) {
        return {
          'status': 'error',
          'message': serverInfo['error'],
          'details': '서버 정보를 가져올 수 없습니다',
        };
      }

      final status = serverInfo['status'] ?? 'unknown';
      final device = serverInfo['device'] ?? 'unknown';
      final llmType = serverInfo['llm_type'] ?? 'unknown';
      final sttModel = serverInfo['stt_model'] ?? 'unknown';

      return {
        'status': status,
        'device': device,
        'llmType': llmType,
        'sttModel': sttModel,
        'message': status == 'healthy' ? '서버 정상 작동 중' : '서버 상태 불량',
        'timestamp': serverInfo['timestamp'] ?? 'unknown',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': '서버 정보 조회 실패',
        'details': e.toString(),
      };
    }
  }

  // JSON 구조를 보기 좋게 출력하는 헬퍼 메서드
  static void _printJsonStructure(dynamic data, int indent) {
    final indentStr = '  ' * indent;

    if (data is Map) {
      data.forEach((key, value) {
        if (value is Map || value is List) {
          print('$indentStr$key:');
          _printJsonStructure(value, indent + 1);
        } else {
          print('$indentStr$key: $value');
        }
      });
    } else if (data is List) {
      for (int i = 0; i < data.length; i++) {
        print('$indentStr[$i]:');
        _printJsonStructure(data[i], indent + 1);
      }
    } else {
      print('$indentStr$data');
    }
  }
}
