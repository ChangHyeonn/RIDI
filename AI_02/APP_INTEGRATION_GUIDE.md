# 🤖 AI-애플리케이션 연동 가이드 (Text-based)

## 📋 개요

이 문서는 **텍스트 기반 AI 서버**와 Flutter 애플리케이션 간의 연동을 위한 가이드입니다. 
AI 서버는 LLM 중심의 통합 텍스트 처리 파이프라인을 통해 사용자의 텍스트 명령을 분석하고, 
메모리 기반 데이터 관리로 일정을 처리하며, 텍스트 응답을 생성합니다.

**주요 특징:**
- ✅ **텍스트 기반 처리**: STT/TTS는 Flutter 애플리케이션에서 처리
- ✅ **경량화된 서버**: 음성 처리 의존성 제거로 빠른 응답
- ✅ **명확한 책임 분리**: AI 서버는 텍스트 AI 처리만 담당

## 🏗️ 시스템 아키텍처

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Flutter   │    │   AI Server │    │  MongoDB    │
│  App        │◄──►│  (Python)   │◄──►│  Database   │
└─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │
       │                   │                   │
   STT 처리            LLM 처리            일정 저장
   TTS 처리            텍스트 응답         데이터 조회
   UI 업데이트         명확화 요청         일정 삭제
```

### **데이터 흐름**

1. **App → AI Server**: JSON 텍스트 요청
2. **AI Server → MongoDB**: 구조화된 일정 데이터
3. **AI Server → App**: JSON 텍스트 응답

## 🔄 상호작용 구조

### **1. 텍스트 명령 처리 흐름**

```
Flutter App에서 STT 처리
    ↓
텍스트 명령 전송 (JSON)
    ↓
LLM 분석 (OpenAI GPT-4o-mini)
    ↓
명령 분류 및 정보 추출
    ↓
ScheduleManager 처리
    ↓
MongoDB 저장/조회/삭제
    ↓
텍스트 응답 생성
    ↓
JSON 응답 전송
    ↓
Flutter App에서 TTS 처리
```

### **2. 명확화 요청 처리**

```
정보 부족/모호함 감지
    ↓
명확화 요청 생성
    ↓
App에 후속 질문 전송
    ↓
사용자 추가 정보 제공
    ↓
재처리 및 완료
```

## 🎯 API 엔드포인트

### **텍스트 처리 API**
```http
POST /api/v1/process_text
Content-Type: application/json

Request Body:
{
  "text": "내일 오후 3시에 병원 예약이 있어",
  "user_id": "user123"
}

Response: JSON 텍스트 응답
```

### **서버 상태 확인**
```http
GET /api/v1/health
```

## 📊 데이터 형식

### **1. App → AI Server (요청)**

#### **텍스트 명령 처리**
```http
POST /api/v1/process_text
Content-Type: application/json

{
  "text": "내일 오후 3시에 병원 예약이 있어",
  "user_id": "user123"
}
```

**요청 필드 설명:**
- `text` (필수): 처리할 텍스트 명령
- `user_id` (선택): 사용자 식별자 (기본값: "default_user")

**요청 예시:**
```json
// 일정 추가 (일반)
{
  "text": "내일 오후 3시에 병원 예약이 있어",
  "user_id": "user123"
}

// 일정 추가 (중요)
{
  "text": "다음주 월요일 오전 9시에 중요한 회의가 있어",
  "user_id": "user123"
}

// 일정 조회
{
  "text": "내일 일정이 뭐야?",
  "user_id": "user123"
}

// 일정 삭제
{
  "text": "병원 예약 취소해줘",
  "user_id": "user123"
}

// 일반 대화
{
  "text": "안녕하세요",
  "user_id": "user123"
}
```

**요청 검증 규칙:**
- ✅ **텍스트 길이**: 1자 이상, 1000자 이하
- ✅ **텍스트 형식**: 문자열만 허용
- ✅ **보안 검증**: XSS, JavaScript 인젝션 등 위험한 패턴 차단
- ✅ **사용자 ID**: 문자열 형식 (기본값: "default_user")

**오류 응답 예시:**
```json
// 텍스트 누락
{
  "error": "텍스트가 제공되지 않았습니다"
}

// 텍스트 너무 짧음
{
  "error": "텍스트가 너무 짧습니다"
}

// 텍스트 너무 김
{
  "error": "텍스트가 너무 깁니다. (최대 1000자)"
}

// 위험한 패턴 포함
{
  "error": "허용되지 않는 텍스트 패턴이 포함되어 있습니다"
}
```

**참고**: 모든 일정 관련 요청은 `/api/v1/process_text` 엔드포인트를 통해 텍스트 명령으로 처리됩니다.

### **2. AI Server → App (응답)**

#### **기본 응답 구조**
```json
{
  "success": true,
  "user_text": "내일 오후 3시에 병원 예약이 있어",
  "processing_result": {
    "action": "schedule_add",
    "result": {
      "action": "schedule_added",
      "message": "내일 오후 3시에 병원 예약을 추가했습니다.",
      "schedule_data": {
        "title": "병원 예약",
        "datetime": "2024-01-15 15:00:00",
        "description": "병원 예약"
      }
    }
  },
  "response_text": "내일 오후 3시에 병원 예약을 추가했습니다.",
  "processing_time": 1.234,
  "timestamp": "2024-01-14T10:30:00.123456",
  "pipeline_info": {
    "pipeline_type": "Unified Text Pipeline",
    "components": {
      "request_processor": {
        "processor_type": "Unified Request Processor",
        "llm_model": {
          "model_name": "gpt-4o-mini",
          "provider": "OpenAI"
        }
      }
    },
    "features": {
      "llm_centered": true,
      "text_to_text": true,
      "no_stt_tts": true
    }
  }
}
```

#### **에러 응답 구조**
```json
{
  "success": false,
  "error": "텍스트 처리 중 오류가 발생했습니다",
  "processing_time": 0.123,
  "timestamp": "2024-01-14T10:30:00.123456",
  "pipeline_info": {
    "pipeline_type": "Unified Text Pipeline",
    "components": {
      "request_processor": {
        "processor_type": "Unified Request Processor"
      }
    },
    "features": {
      "llm_centered": true,
      "text_to_text": true,
      "no_stt_tts": true
    }
  }
}
```

### **액션 타입별 의미**
- `schedule_add`: 일정 추가 요청
- `schedule_read`: 일정 조회 요청  
- `schedule_delete`: 일정 삭제 요청
- `schedule_modify`: 일정 수정 요청
- `accessibility`: 접근성 설정 변경
- `other`: 일반 대화 또는 기타 요청

### **일정 관련 데이터 구조**

#### **일정 추가 응답에서 중요도 필드**
```json
{
  "processing_result": {
    "action": "schedule_add",
    "result": {
      "schedule_data": {
        "title": "병원 예약",
        "datetime": "2024-01-15 15:00",
        "category": "건강",
        "is_important": false,  // boolean: true=중요, false=일반
        "location": "서울대병원",
        "description": "정기 검진"
      }
    }
  }
}
```

#### **중요도 판단 기준**
AI 서버는 다음 키워드를 기반으로 중요도를 자동 판단합니다:
- **중요 (true)**: "중요", "긴급", "urgent", "critical", "high", "높음" 등
- **일반 (false)**: 기본값, 중요 키워드가 없는 경우

## 🔧 Flutter 애플리케이션 구현

### **1. STT 처리 (Flutter에서)**

```dart
import 'package:speech_to_text/speech_to_text.dart';

class VoiceRecorder {
  final SpeechToText _speechToText = SpeechToText();
  
  Future<String> recognizeSpeech() async {
    // 음성 녹음 및 텍스트 변환
    String userText = await _speechToText.recognize();
    return userText;
  }
}
```

### **2. AI 서버 요청**

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  static const String baseUrl = 'http://localhost:8080/api/v1';
  
  Future<Map<String, dynamic>> processText(String text, String userId) async {
    try {
      // 요청 데이터 구성
      final requestData = {
        'text': text,
        'user_id': userId,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/process_text'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // HTTP 오류 처리
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('요청 처리 중 오류가 발생했습니다: $e');
    }
  }
  
  // 서버 상태 확인
  Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
```

### **3. TTS 처리 (Flutter에서)**

```dart
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeech {
  final FlutterTts _flutterTts = FlutterTts();
  
  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }
}
```

### **4. 통합 사용 예시**

```dart
class VoiceAssistant {
  final VoiceRecorder _voiceRecorder = VoiceRecorder();
  final AIService _aiService = AIService();
  final TextToSpeech _textToSpeech = TextToSpeech();
  
  Future<void> processVoiceCommand() async {
    try {
      // 1. STT 처리
      String userText = await _voiceRecorder.recognizeSpeech();
      
      // 2. 서버 상태 확인 (선택사항)
      bool isServerHealthy = await _aiService.checkServerHealth();
      if (!isServerHealthy) {
        _showErrorDialog('서버 연결 오류', 'AI 서버에 연결할 수 없습니다.');
        return;
      }
      
      // 3. AI 서버 요청
      Map<String, dynamic> response = await _aiService.processText(
        userText, 
        'user123'
      );
      
      // 4. 응답 처리
      if (response['success']) {
        String responseText = response['response_text'];
        
        // 5. TTS 처리
        await _textToSpeech.speak(responseText);
        
        // 6. UI 업데이트
        _updateUI(response['processing_result']);
        
        // 7. 처리 시간 로깅 (선택사항)
        double processingTime = response['processing_time'] ?? 0.0;
        print('처리 시간: ${processingTime.toStringAsFixed(3)}초');
      } else {
        // 에러 처리
        _handleError(response);
      }
    } catch (e) {
      print('Error: $e');
      _showErrorDialog('오류', '요청 처리 중 오류가 발생했습니다: $e');
    }
  }
  
     void _updateUI(Map<String, dynamic> processingResult) {
     // 처리 결과에 따른 화면 업데이트
     String action = processingResult['action'];
     Map<String, dynamic> result = processingResult['result'];
     
     switch (action) {
       case 'schedule_add':
         _showScheduleAdded(result['schedule_data']);
         break;
       case 'schedule_read':
         _showScheduleList(result);
         break;
       case 'schedule_delete':
         _showScheduleDeleted(result);
         break;
       // ... 기타 액션들
     }
   }
}
```

## 📱 UI 지시사항 처리

### **액션 타입별 UI 업데이트**

#### **일정 추가 (`schedule_add`)**
```dart
void _showScheduleAdded(Map<String, dynamic> scheduleData) {
  // 캘린더 화면으로 이동
  Navigator.pushNamed(context, '/calendar');
  
  // 해당 날짜 하이라이트
  _highlightDate(scheduleData['datetime']);
  
  // 성공 알림 표시
  _showNotification(
    title: '일정 추가됨',
    message: '${scheduleData['title']}이 추가되었습니다',
    type: 'success'
  );
}
```

#### **일정 조회 (`schedule_read`)**
```dart
void _showScheduleList(Map<String, dynamic> result) {
  // 일정 목록 화면으로 이동
  Navigator.pushNamed(context, '/schedule-list');
  
  // 일정 데이터 업데이트
  if (result['schedules']) {
    _updateScheduleList(result['schedules']);
  }
  
  // 메시지 표시
  if (result['message']) {
    _showNotification(
      title: '일정 조회',
      message: result['message'],
      type: 'info'
    );
  }
}
```

#### **일정 삭제 (`schedule_delete`)**
```dart
void _showScheduleDeleted(Map<String, dynamic> result) {
  // 캘린더 화면으로 이동
  Navigator.pushNamed(context, '/calendar');
  
  // 삭제된 일정 정보 표시
  if (result['deleted_schedule']) {
    _showNotification(
      title: '일정 삭제됨',
      message: '${result['deleted_schedule']['title']}이 삭제되었습니다',
      type: 'success'
    );
  }
  
  // 일정 목록 새로고침
  _refreshScheduleList();
}
```

## 🔒 보안 및 인증

### **기본 보안 (선택사항)**
```dart
class AIService {
  // API 키가 필요한 경우
  static const String apiKey = 'your_api_key_here';
  
  Future<Map<String, dynamic>> processText(String text, String userId) async {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    // API 키가 설정된 경우에만 헤더에 추가
    if (apiKey.isNotEmpty) {
      headers['X-API-Key'] = apiKey;
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/process_text'),
      headers: headers,
      body: jsonEncode({
        'text': text,
        'user_id': userId,
      }),
    );
    
    // ... 응답 처리
  }
}
```

## 🐛 에러 처리

### **네트워크 에러**
```dart
Future<Map<String, dynamic>> processText(String text, String userId) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/process_text'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': text,
        'user_id': userId,
      }),
    ).timeout(Duration(seconds: 30));  // 30초 타임아웃
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw HttpException('HTTP ${response.statusCode}');
    }
  } on SocketException {
    throw Exception('네트워크 연결을 확인해주세요');
  } on TimeoutException {
    throw Exception('요청 시간이 초과되었습니다');
  } catch (e) {
    throw Exception('알 수 없는 오류가 발생했습니다: $e');
  }
}
```

### **AI 서버 에러**
```dart
   void _handleError(Map<String, dynamic> response) {
     final errorMessage = response['error'];
     
     // 일반적인 에러 처리
     _showErrorDialog('오류', errorMessage);
   }
```

## 📊 성능 최적화

### **1. 간단한 캐싱 (선택사항)**
```dart
class SimpleCache {
  static final Map<String, String> _cache = {};
  
  static String? get(String key) {
    return _cache[key];
  }
  
  static void set(String key, String value) {
    _cache[key] = value;
  }
  
  static void clear() {
    _cache.clear();
  }
}
```

## 🔧 설정 및 환경

### **환경별 설정**
```dart
class Environment {
  // 개발 환경
  static const String devUrl = 'http://localhost:8080/api/v1';
  // 프로덕션 환경
  static const String prodUrl = 'https://your-production-server.com/api/v1';
  
  static String get baseUrl {
    // 디버그 모드에서는 개발 서버 사용
    if (kDebugMode) {
      return devUrl;
    }
    return prodUrl;
  }
}
```

### **간단한 로깅**
```dart
class Logger {
  static void log(String message) {
    if (kDebugMode) {
      print('[AI_APP] $message');
    }
  }
  
  static void logRequest(String endpoint, Map<String, dynamic> data) {
    log('REQUEST: $endpoint - ${jsonEncode(data)}');
  }
  
  static void logResponse(String endpoint, Map<String, dynamic> data) {
    log('RESPONSE: $endpoint - ${jsonEncode(data)}');
  }
}
```

## 📋 체크리스트

### **구현 완료 확인**

- [ ] **STT 처리**: Flutter에서 음성 → 텍스트 변환
- [ ] **AI 서버 연동**: JSON 텍스트 요청/응답 처리
- [ ] **TTS 처리**: Flutter에서 텍스트 → 음성 변환
- [ ] **UI 업데이트**: 액션 기반 화면 전환
- [ ] **에러 처리**: 네트워크 및 서버 에러 처리
- [ ] **보안**: 기본 보안 설정 (선택사항)
- [ ] **성능**: 기본 캐싱 (선택사항)
- [ ] **로깅**: 간단한 디버그 로그

### **테스트 시나리오**

1. **기본 텍스트 처리**
   - 정상적인 일정 추가 요청
   - 응답 텍스트 확인
   - UI 업데이트 확인

2. **에러 상황 처리**
   - 네트워크 연결 실패
   - 서버 에러 응답
   - 잘못된 입력 데이터

3. **성능 테스트**
   - 연속 요청 처리
   - 텍스트 길이 제한 확인
   - 응답 시간 측정

## 🚀 배포 가이드

### **1. AI 서버 배포**
```bash
# AI_02 폴더에서
cd AI_02
python3 main.py --host 0.0.0.0 --port 8080
```

### **2. Flutter 앱 배포**
```bash
# Flutter 프로젝트에서
flutter build apk --release
flutter build ios --release
```

### **3. 환경 변수 설정**
```bash
# AI 서버 환경 변수
export OPENAI_API_KEY="your_openai_api_key"
export LLM_TYPE="openai"
export AI_SERVER_HOST="0.0.0.0"
export AI_SERVER_PORT="8080"

# 데이터베이스 설정
export DB_ENGINE="mongodb"
export MONGO_URI="mongodb://localhost:27017/"
export MONGO_DB="ridi_ai"
```

## 📞 지원 및 문의

문제가 있거나 질문이 있으시면 이슈를 생성해주세요.

---

**버전**: 2.0.0 (Text-based)  
**최종 업데이트**: 2024년 1월  
**라이선스**: MIT