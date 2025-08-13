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
LLM 분석 (Gemini)
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

#### **일정 추가**
```http
POST /api/v1/schedule/add
Content-Type: application/json
X-User-ID: user123

{
  "title": "병원 예약",
  "datetime": "2024-01-15 15:00:00",
  "description": "정기 검진",
  "priority": "important"
}
```

#### **일정 조회**
```http
GET /api/v1/schedule/list?user_id=user123
```

#### **일정 삭제**
```http
DELETE /api/v1/schedule/delete
Content-Type: application/json
X-User-ID: user123

{
  "schedule_id": "schedule_1234567890",
  "title": "병원 예약",
  "date": "2024-01-15"
}
```

### **2. AI Server → App (응답)**

#### **기본 응답 구조**
```json
{
  "success": true,
  "action": {
    "type": "schedule_add",
    "priority": "high",
    "data": {
      "id": "schedule_1234567890",
      "title": "병원 예약",
      "datetime": "2024-01-15 15:00:00"
    },
    "ui_instructions": {
      "screen": "calendar",
      "refresh_data": true,
      "show_confirmation": true,
      "notification": {
        "type": "success",
        "title": "일정 추가됨",
        "message": "병원 예약이 추가되었습니다"
      }
    }
  },
  "text_response": {
    "text": "내일 오후 3시에 병원 예약을 추가했습니다.",
    "display_automatically": true
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

#### **에러 응답 구조**
```json
{
  "success": false,
  "action": {
    "type": "error",
    "priority": "high",
    "data": {
      "error_type": "text_processing",
      "message": "텍스트 처리 중 오류가 발생했습니다"
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "텍스트 처리 중 오류가 발생했습니다",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

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
    final response = await http.post(
      Uri.parse('$baseUrl/process_text'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'text': text,
        'user_id': userId,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to process text');
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
      
      // 2. AI 서버 요청
      Map<String, dynamic> response = await _aiService.processText(
        userText, 
        'user123'
      );
      
      // 3. 응답 처리
      if (response['success']) {
        String responseText = response['text_response']['text'];
        
        // 4. TTS 처리
        await _textToSpeech.speak(responseText);
        
        // 5. UI 업데이트
        _updateUI(response['action']);
      } else {
        // 에러 처리
        _handleError(response);
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  
  void _updateUI(Map<String, dynamic> action) {
    // UI 지시사항에 따른 화면 업데이트
    switch (action['type']) {
      case 'schedule_add':
        _showScheduleAdded(action['data']);
        break;
      case 'schedule_list':
        _showScheduleList(action['data']);
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

#### **일정 목록 (`schedule_list`)**
```dart
void _showScheduleList(Map<String, dynamic> data) {
  // 일정 목록 화면으로 이동
  Navigator.pushNamed(context, '/schedule-list');
  
  // 일정 데이터 업데이트
  _updateScheduleList(data['schedules']);
  
  // 중요 일정 하이라이트
  if (data['filter'] == 'important') {
    _highlightImportantSchedules();
  }
}
```

#### **설정 변경 (`settings_update`)**
```dart
void _updateSettings(Map<String, dynamic> changes) {
  // 설정 화면으로 이동
  Navigator.pushNamed(context, '/settings');
  
  // 설정 변경사항 적용
  _applySettings(changes);
  
  // 설정 미리보기 표시
  _showSettingsPreview(changes);
}
```

## 🔒 보안 및 인증

### **API 키 인증 (선택사항)**
```dart
class AIService {
  static const String apiKey = 'your_api_key_here';
  
  Future<Map<String, dynamic>> processText(String text, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/process_text'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,  // API 키 헤더
      },
      body: jsonEncode({
        'text': text,
        'user_id': userId,
      }),
    );
    
    // ... 응답 처리
  }
}
```

### **요청 제한 처리**
```dart
class RateLimiter {
  static const int maxRequestsPerMinute = 100;
  static final Map<String, List<DateTime>> _requestHistory = {};
  
  static bool canMakeRequest(String userId) {
    final now = DateTime.now();
    final userRequests = _requestHistory[userId] ?? [];
    
    // 1분 이내 요청만 유지
    final recentRequests = userRequests
        .where((time) => now.difference(time).inMinutes < 1)
        .toList();
    
    if (recentRequests.length >= maxRequestsPerMinute) {
      return false;
    }
    
    // 요청 기록 업데이트
    recentRequests.add(now);
    _requestHistory[userId] = recentRequests;
    
    return true;
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
  final errorType = response['action']['data']['error_type'];
  final errorMessage = response['action']['data']['message'];
  
  switch (errorType) {
    case 'text_processing':
      _showErrorDialog('텍스트 처리 오류', errorMessage);
      break;
    case 'validation_error':
      _showErrorDialog('입력 검증 오류', errorMessage);
      break;
    case 'schedule_add_error':
      _showErrorDialog('일정 추가 오류', errorMessage);
      break;
    default:
      _showErrorDialog('오류', errorMessage);
  }
}
```

## 📊 성능 최적화

### **1. 요청 캐싱**
```dart
class RequestCache {
  static final Map<String, Map<String, dynamic>> _cache = {};
  static const Duration cacheExpiry = Duration(minutes: 5);
  
  static Map<String, dynamic>? get(String key) {
    final cached = _cache[key];
    if (cached != null) {
      final timestamp = cached['timestamp'] as DateTime;
      if (DateTime.now().difference(timestamp) < cacheExpiry) {
        return cached['data'];
      }
    }
    return null;
  }
  
  static void set(String key, Map<String, dynamic> data) {
    _cache[key] = {
      'data': data,
      'timestamp': DateTime.now(),
    };
  }
}
```

### **2. 배치 요청**
```dart
class BatchProcessor {
  static final List<String> _pendingRequests = [];
  static Timer? _batchTimer;
  
  static void addRequest(String text) {
    _pendingRequests.add(text);
    
    if (_batchTimer == null) {
      _batchTimer = Timer(Duration(milliseconds: 500), _processBatch);
    }
  }
  
  static void _processBatch() async {
    if (_pendingRequests.isEmpty) return;
    
    final batchText = _pendingRequests.join(' ');
    _pendingRequests.clear();
    _batchTimer = null;
    
    // 배치 요청 처리
    await _aiService.processText(batchText, 'user123');
  }
}
```

## 🔧 설정 및 환경

### **환경별 설정**
```dart
class Environment {
  static const String development = 'development';
  static const String production = 'production';
  
  static String get baseUrl {
    switch (const String.fromEnvironment('ENVIRONMENT', defaultValue: development)) {
      case production:
        return 'https://your-production-server.com/api/v1';
      case development:
      default:
        return 'http://localhost:8080/api/v1';
    }
  }
  
  static bool get enableLogging {
    return const String.fromEnvironment('ENVIRONMENT') == development;
  }
}
```

### **로깅 설정**
```dart
class Logger {
  static void log(String message) {
    if (Environment.enableLogging) {
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
- [ ] **보안**: API 키 인증 (필요시)
- [ ] **성능**: 캐싱 및 배치 처리
- [ ] **로깅**: 디버깅을 위한 로그 시스템

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
   - 대용량 텍스트 처리
   - 메모리 사용량 확인

## 🚀 배포 가이드

### **1. AI 서버 배포**
```bash
# AI_02 폴더에서
cd AI_02/Server
python3 app.py --host 0.0.0.0 --port 8080
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
export GOOGLE_API_KEY="your_google_api_key"
export LLM_TYPE="gemini"
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