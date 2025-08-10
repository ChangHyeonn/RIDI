# 🤖 AI-애플리케이션 연동 가이드

## 📋 개요

이 문서는 AI 서버와 Flutter 애플리케이션 간의 연동을 위한 가이드입니다. 
AI 서버는 LLM 중심의 통합 음성 처리 파이프라인을 통해 사용자의 음성 명령을 분석하고, 
MongoDB 데이터베이스와 연동하여 일정을 관리하며, TTS를 통해 음성 응답을 생성합니다.

## 🏗️ 시스템 아키텍처

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Flutter   │    │   AI Server │    │  MongoDB    │
│  App        │◄──►│  (Python)   │◄──►│  Database   │
└─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │
       │                   │                   │
   음성 입력            LLM 처리            일정 저장
   UI 업데이트         TTS 생성            데이터 조회
   음성 재생            명확화 요청         일정 삭제
```

### **데이터 흐름**

1. **App → AI Server**: 음성 파일 (multipart/form-data)
2. **AI Server → MongoDB**: 구조화된 일정 데이터
3. **AI Server → App**: JSON 응답 + Base64 인코딩된 음성 파일

## 🔄 상호작용 구조

### **1. 음성 명령 처리 흐름**

```
사용자 음성 입력
    ↓
STT (Google Cloud STT)
    ↓
LLM 분석 (Gemini)
    ↓
명령 분류 및 정보 추출
    ↓
ScheduleManager 처리
    ↓
MongoDB 저장/조회/삭제
    ↓
TTS 음성 생성
    ↓
JSON + 음성 응답 전송
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

### **음성 처리 API**
```http
POST /api/v1/process_voice
Content-Type: multipart/form-data

Form Data:
- audio: [오디오 파일] (필수)
- user_id: "user123" (선택사항)

Response: JSON + Base64 음성 데이터
```

### **서버 상태 확인**
```http
GET /api/v1/health
```

## 📊 데이터 형식

### **1. App → AI Server (요청)**

#### **음성 파일 업로드**
```http
POST /api/v1/process_voice
Content-Type: multipart/form-data

Form Data:
- audio: [WAV/MP3/M4A/FLAC/OGG 파일]
- user_id: "user123"
```

### **2. AI Server → App (응답)**

#### **기본 응답 구조**
```json
{
  "success": true,
  "action": {
    "type": "액션_타입",
    "priority": "high|medium|low",
    "data": {
      // 액션별 데이터
    },
    "ui_instructions": {
      // UI 업데이트 지시사항
    }
  },
  "voice_response": {
    "text": "음성 응답 텍스트",
    "play_automatically": true,
    "audio_url": "data:audio/mp3;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIG2m98OScTgwOUarm7blmGgU7k9n1unEiBC13yO/eizEIHWq+8+OWT..."
  },
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### **3. 액션 타입별 응답**

#### **일정 추가 (`schedule_add`)**
```json
{
  "success": true,
  "action": {
    "type": "schedule_add",
    "priority": "high",
    "data": {
      "id": "507f1f77bcf86cd799439011",
      "title": "병원 예약",
      "datetime": "2024-01-20 14:00"
    },
    "ui_instructions": {
      "screen": "calendar",
      "highlight_date": "2024-01-20",
      "show_confirmation": true
    }
  },
  "voice_response": {
    "text": "내일 오후 2시에 병원 예약을 추가했습니다.",
    "play_automatically": true,
    "audio_url": "data:audio/mp3;base64,..."
  }
}
```

#### **일정 삭제 (`schedule_delete`)**
```json
{
  "success": true,
  "action": {
    "type": "schedule_delete",
    "priority": "high",
    "data": {
      "id": "507f1f77bcf86cd799439011",
      "title": "병원 예약",
      "date": "2024-01-20"
    },
    "ui_instructions": {
      "screen": "calendar",
      "remove_item": "507f1f77bcf86cd799439011"
    }
  },
  "voice_response": {
    "text": "병원 예약 일정을 삭제했습니다.",
    "play_automatically": true,
    "audio_url": "data:audio/mp3;base64,..."
  }
}
```

#### **일정 조회 (`schedule_list`)**
```json
{
  "success": true,
  "action": {
    "type": "schedule_list",
    "priority": "medium",
    "data": {
      "schedules": [
        {
          "id": "507f1f77bcf86cd799439011",
          "title": "병원 예약",
          "datetime": "2024-01-20 14:00",
          "category": "건강",
          "priority": "important"
        }
      ]
    },
    "ui_instructions": {
      "screen": "schedule_list",
      "refresh_data": true
    }
  },
  "voice_response": {
    "text": "내일 일정을 조회했습니다.",
    "play_automatically": true,
    "audio_url": "data:audio/mp3;base64,..."
  }
}
```

#### **명확화 요청 (`clarification_request`)**
```json
{
  "success": true,
  "action": {
    "type": "clarification_request",
    "priority": "high",
    "data": {
      "message": "일정 제목을 알려주세요.",
      "candidates": [
        {
          "id": "507f1f77bcf86cd799439011",
          "title": "병원 예약",
          "datetime": "2024-01-20 14:00"
        }
      ]
    },
    "ui_instructions": {
      "screen": "conversation",
      "show_input_prompt": true
    }
  },
  "voice_response": {
    "text": "일정 제목을 알려주세요.",
    "play_automatically": true,
    "audio_url": "data:audio/mp3;base64,..."
  }
}
```

#### **음성 응답 (`voice_response`)**
```json
{
  "success": true,
  "action": {
    "type": "voice_response",
    "priority": "low",
    "data": {},
    "ui_instructions": {
      "show_voice_indicator": true
    }
  },
  "voice_response": {
    "text": "요청을 처리했습니다.",
    "play_automatically": true,
    "audio_url": "data:audio/mp3;base64,..."
  }
}
```

### **4. AI Server → MongoDB (데이터베이스)**

#### **일정 문서 구조**
```json
{
  "_id": ObjectId("507f1f77bcf86cd799439011"),
  "user_id": "user123",
  "title": "병원 예약",
  "start_dt": ISODate("2024-01-20T14:00:00Z"),
  "category": "건강",
  "priority": "important",
  "location": "서울대병원",
  "description": "내과 진료 예약",
  "source": "voice",
  "status": "active",
  "created_at": ISODate("2024-01-15T10:30:00Z"),
  "updated_at": ISODate("2024-01-15T10:30:00Z")
}
```

#### **사용자 문서 구조**
```json
{
  "_id": ObjectId("507f1f77bcf86cd799439012"),
  "user_id": "user123",
  "settings": {
    "font_size": "medium",
    "volume_level": 1.0,
    "speech_rate": 1.0,
    "high_contrast": false
  },
  "created_at": ISODate("2024-01-15T10:30:00Z"),
  "updated_at": ISODate("2024-01-15T10:30:00Z")
}
```

## 🎯 Flutter 구현 가이드

### **1. HTTP 클라이언트 설정**

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class AIService {
  static const String baseUrl = 'http://your-ai-server:5000';
  
  static Future<AIResponse> processVoice(String audioPath) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/v1/process_voice'),
    );
    
    request.files.add(
      await http.MultipartFile.fromPath('audio', audioPath),
    );
    request.fields['user_id'] = 'user123';
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    return AIResponse.fromJson(json.decode(responseData));
  }
}
```

### **2. 응답 모델 클래스**

```dart
class AIResponse {
  final bool success;
  final Action? action;
  final VoiceResponse? voiceResponse;
  final String timestamp;

  AIResponse({
    required this.success,
    this.action,
    this.voiceResponse,
    required this.timestamp,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      success: json['success'] ?? false,
      action: json['action'] != null ? Action.fromJson(json['action']) : null,
      voiceResponse: json['voice_response'] != null 
          ? VoiceResponse.fromJson(json['voice_response']) 
          : null,
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class Action {
  final String type;
  final String priority;
  final Map<String, dynamic> data;
  final UIInstructions uiInstructions;

  Action({
    required this.type,
    required this.priority,
    required this.data,
    required this.uiInstructions,
  });

  factory Action.fromJson(Map<String, dynamic> json) {
    return Action(
      type: json['type'] ?? '',
      priority: json['priority'] ?? 'medium',
      data: json['data'] ?? {},
      uiInstructions: UIInstructions.fromJson(json['ui_instructions'] ?? {}),
    );
  }
}

class VoiceResponse {
  final String text;
  final bool playAutomatically;
  final String? audioUrl;

  VoiceResponse({
    required this.text,
    required this.playAutomatically,
    this.audioUrl,
  });

  factory VoiceResponse.fromJson(Map<String, dynamic> json) {
    return VoiceResponse(
      text: json['text'] ?? '',
      playAutomatically: json['play_automatically'] ?? false,
      audioUrl: json['audio_url'],
    );
  }
}
```

### **3. 액션 처리 함수**

```dart
class ActionHandler {
  static void handleAction(Action action, BuildContext context) {
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
    }
  }

  static void handleScheduleAdd(Action action, BuildContext context) {
    // 1. 캘린더 화면으로 이동
    Navigator.pushNamed(context, '/calendar');
    
    // 2. 날짜 하이라이트
    if (action.uiInstructions.highlightDate != null) {
      highlightDate(action.uiInstructions.highlightDate!);
    }
    
    // 3. 성공 알림 표시
    if (action.uiInstructions.showConfirmation == true) {
      showSuccessNotification('일정이 추가되었습니다.');
    }
  }

  static void handleClarificationRequest(Action action, BuildContext context) {
    // 1. 대화 화면으로 이동
    Navigator.pushNamed(context, '/conversation');
    
    // 2. 입력 프롬프트 표시
    if (action.uiInstructions.showInputPrompt == true) {
      showInputPrompt(action.data['message']);
    }
    
    // 3. 후보 일정 표시 (있는 경우)
    if (action.data['candidates'] != null) {
      showCandidates(action.data['candidates']);
    }
  }
}
```

### **4. 음성 재생 처리**

```dart
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> playAudioFromBase64(String audioUrl) async {
    try {
      if (audioUrl.startsWith('data:audio/mp3;base64,')) {
        String base64Data = audioUrl.replaceFirst('data:audio/mp3;base64,', '');
        Uint8List audioBytes = base64Decode(base64Data);
        
        // 임시 파일로 저장
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_audio.mp3');
        await tempFile.writeAsBytes(audioBytes);
        
        // 재생
        await _audioPlayer.play(DeviceFileSource(tempFile.path));
      }
    } catch (e) {
      print('음성 재생 오류: $e');
    }
  }
}
```

## 📊 설정 및 환경 변수

### **AI 서버 설정**
```bash
# 데이터베이스 설정
DB_ENGINE=mongodb
MONGO_URI=mongodb://localhost:27017/
MONGO_DB=ridi_ai

# AI 모델 설정
LLM_TYPE=gemini
STT_MODEL=default

# 서버 설정
HOST=0.0.0.0
PORT=5000
DEBUG=False

# 보안 설정
API_KEY=your_api_key_here
MAX_AUDIO_SIZE=10485760  # 10MB
```

### **MongoDB 인덱스**
```javascript
// schedules 컬렉션 인덱스
db.schedules.createIndex({"user_id": 1, "start_dt": 1})
db.schedules.createIndex({"user_id": 1, "title": "text"})
db.schedules.createIndex({"user_id": 1, "category": 1})
db.schedules.createIndex({"status": 1})

// users 컬렉션 인덱스
db.users.createIndex({"user_id": 1})
```

## 🚀 배포 및 운영

### **1. AI 서버 실행**
```bash
cd AI
python main.py --llm-type gemini
```

### **2. MongoDB 실행**
```bash
# Docker로 실행
docker run -d -p 27017:27017 --name mongodb mongo:latest

# 또는 로컬 설치
brew install mongodb-community  # macOS
sudo systemctl start mongod     # Linux
```

### **3. Flutter 앱 빌드**
```bash
cd app_protoo
flutter build apk --release
flutter build ios --release
```

## 📊 성능 최적화

### **1. 음성 처리 최적화**
- 오디오 파일 크기 제한 (10MB)
- 지원 형식: WAV, MP3, M4A, FLAC, OGG
- STT 결과 캐싱

### **2. 데이터베이스 최적화**
- MongoDB 인덱스 활용
- 사용자별 데이터 분리
- 일정 상태 관리 (active/inactive)

### **3. 네트워크 최적화**
- Base64 음성 데이터 압축
- JSON 응답 크기 최소화
- 연결 재사용

## 🔒 보안 고려사항

### **1. 인증 및 권한**
- 사용자별 데이터 격리
- API 키 기반 인증
- 요청 크기 제한

### **2. 데이터 보호**
- 민감 정보 암호화
- 로그 데이터 마스킹
- 백업 및 복구

## 📊 문제 해결

### **1. 일반적인 오류**

#### **음성 인식 실패**
```json
{
  "success": false,
  "action": {
    "type": "error",
    "priority": "high",
    "data": {
      "error_type": "voice_processing",
      "message": "음성을 인식할 수 없습니다. 다시 말씀해 주세요."
    }
  }
}
```

#### **일정 추가 실패**
```json
{
  "success": false,
  "action": {
    "type": "error",
    "priority": "high",
    "data": {
      "error_type": "schedule_add",
      "message": "일정 추가 중 오류가 발생했습니다."
    }
  }
}
```

### **2. 디버깅 방법**
- AI 서버 로그 확인
- MongoDB 쿼리 로그
- Flutter 앱 디버그 콘솔
- 네트워크 요청/응답 모니터링

## 🎯 다음 단계

1. **Flutter 앱에 음성 녹음 기능 추가**
2. **실시간 음성 처리 구현**
3. **오프라인 모드 지원**
4. **푸시 알림 연동**
5. **다국어 지원**
6. **성능 모니터링 도구 추가**

이 가이드를 따라 구현하면 AI 서버와 MongoDB 데이터베이스가 완벽하게 연동되는 
고성능 일정 관리 애플리케이션을 만들 수 있습니다! 🎯
