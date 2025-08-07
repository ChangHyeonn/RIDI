# 🤖 AI-애플리케이션 연동 가이드

## 📋 개요

이 문서는 AI 서버와 Flutter 애플리케이션 간의 연동을 위한 가이드입니다. 
AI 서버가 제공하는 액션 기반 JSON 응답을 통해 애플리케이션이 즉시 실행 가능한 지시사항을 받을 수 있습니다.

## 🚀 주요 개선사항

### ✅ **기존 문제점**
- AI 서버 응답이 데이터 중심으로만 구성
- 애플리케이션이 응답을 받아도 추가 처리 필요
- UI 업데이트 지시사항 부재

### ✅ **개선된 구조**
- **액션 중심**: 즉시 실행 가능한 지시사항 포함
- **UI 지시사항**: 화면 전환, 알림, 애니메이션 포함
- **음성 응답**: 자동 재생 및 고령자 최적화
- **우선순위**: 액션의 중요도에 따른 처리 순서

## 📱 애플리케이션 연동 방법

### **1. 기본 응답 구조**

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
    // 음성 응답 (선택사항)
  },
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### **2. 액션 타입별 처리**

#### **일정 추가 (`schedule_add`)**
```json
{
  "action": {
    "type": "schedule_add",
    "priority": "high",
    "data": {
      "title": "병원 예약",
      "datetime": "2024-01-20T14:00:00",
      "description": "내과 진료 예약",
      "category": "건강",
      "priority": "important"
    },
    "ui_instructions": {
      "screen": "calendar",
      "highlight_date": "2024-01-20",
      "show_confirmation": true,
      "notification": {
        "type": "success",
        "title": "일정 추가됨",
        "message": "병원 예약이 추가되었습니다"
      }
    }
  },
  "voice_response": {
    "text": "내일 오후 2시에 병원 예약을 추가했습니다.",
    "play_automatically": true,
    "elderly_optimized": {
      "slow_speech": true,
      "high_volume": true
    }
  }
}
```

**애플리케이션 처리 방법:**
1. 캘린더 화면으로 이동
2. 2024-01-20 날짜 하이라이트
3. 성공 알림 표시
4. 음성 응답 자동 재생

#### **일정 삭제 (`schedule_delete`)**
```json
{
  "action": {
    "type": "schedule_delete",
    "priority": "high",
    "data": {
      "id": "schedule_1705312200",
      "title": "병원 예약",
      "date": "2024-01-20"
    },
    "ui_instructions": {
      "screen": "calendar",
      "remove_item": "schedule_1705312200",
      "notification": {
        "type": "info",
        "title": "일정 삭제됨",
        "message": "일정이 삭제되었습니다"
      }
    }
  }
}
```

**애플리케이션 처리 방법:**
1. 캘린더 화면에서 해당 일정 제거
2. 삭제 알림 표시

#### **일정 조회 (`schedule_list`)**
```json
{
  "action": {
    "type": "schedule_list",
    "priority": "medium",
    "data": {
      "schedules": [
        {
          "id": "schedule_1705312200",
          "title": "병원 예약",
          "datetime": "2024-01-20T14:00:00",
          "description": "내과 진료 예약",
          "category": "건강",
          "priority": "important"
        }
      ]
    },
    "ui_instructions": {
      "screen": "schedule_list",
      "refresh_data": true,
      "highlight_important": true
    }
  }
}
```

**애플리케이션 처리 방법:**
1. 일정 목록 화면으로 이동
2. 일정 데이터 새로고침
3. 중요 일정 하이라이트

#### **설정 변경 (`settings_update`)**
```json
{
  "action": {
    "type": "settings_update",
    "priority": "medium",
    "data": {
      "setting_type": "accessibility",
      "changes": {
        "font_size": "large",
        "volume_level": 1.5,
        "speech_rate": 0.8
      }
    },
    "ui_instructions": {
      "screen": "settings",
      "refresh_settings": true,
      "show_preview": true,
      "notification": {
        "type": "success",
        "title": "설정 변경됨",
        "message": "설정이 변경되었습니다"
      }
    }
  }
}
```

**애플리케이션 처리 방법:**
1. 설정 화면으로 이동
2. 설정값 즉시 적용
3. 변경사항 미리보기 표시
4. 성공 알림 표시

#### **음성 응답 (`voice_response`)**
```json
{
  "action": {
    "type": "voice_response",
    "priority": "low",
    "data": {},
    "ui_instructions": {
      "show_voice_indicator": true
    }
  },
  "voice_response": {
    "text": "오늘은 2024년 1월 15일 월요일입니다.",
    "play_automatically": true,
    "elderly_optimized": {
      "slow_speech": true,
      "high_volume": true
    }
  }
}
```

**애플리케이션 처리 방법:**
1. 음성 재생 인디케이터 표시
2. 음성 자동 재생
3. 고령자 최적화 설정 적용

### **3. 에러 처리**

```json
{
  "success": false,
  "action": {
    "type": "error",
    "priority": "high",
    "data": {
      "error_type": "voice_processing",
      "message": "음성 인식에 실패했습니다."
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "음성 인식에 실패했습니다.",
        "duration": 5000
      }
    }
  }
}
```

**애플리케이션 처리 방법:**
1. 에러 알림 표시 (5초간)
2. 사용자에게 재시도 안내

## 🎯 구현 가이드

### **1. Flutter에서 JSON 파싱**

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
```

### **2. 액션 처리 함수**

```dart
void handleAIAction(Action action) {
  switch (action.type) {
    case 'schedule_add':
      handleScheduleAdd(action);
      break;
    case 'schedule_delete':
      handleScheduleDelete(action);
      break;
    case 'schedule_list':
      handleScheduleList(action);
      break;
    case 'settings_update':
      handleSettingsUpdate(action);
      break;
    case 'voice_response':
      handleVoiceResponse(action);
      break;
    case 'error':
      handleError(action);
      break;
  }
}

void handleScheduleAdd(Action action) {
  // 1. 캘린더 화면으로 이동
  Navigator.pushNamed(context, '/calendar');
  
  // 2. 날짜 하이라이트
  if (action.uiInstructions.highlightDate != null) {
    highlightDate(action.uiInstructions.highlightDate!);
  }
  
  // 3. 알림 표시
  if (action.uiInstructions.notification != null) {
    showNotification(action.uiInstructions.notification!);
  }
  
  // 4. 음성 재생
  if (action.voiceResponse != null) {
    playVoiceResponse(action.voiceResponse!);
  }
}
```

### **3. UI 지시사항 처리**

```dart
class UIInstructions {
  final String? screen;
  final bool? refreshData;
  final String? highlightDate;
  final bool? showConfirmation;
  final Notification? notification;

  UIInstructions({
    this.screen,
    this.refreshData,
    this.highlightDate,
    this.showConfirmation,
    this.notification,
  });

  factory UIInstructions.fromJson(Map<String, dynamic> json) {
    return UIInstructions(
      screen: json['screen'],
      refreshData: json['refresh_data'],
      highlightDate: json['highlight_date'],
      showConfirmation: json['show_confirmation'],
      notification: json['notification'] != null 
          ? Notification.fromJson(json['notification']) 
          : null,
    );
  }
}
```

## 🔧 API 엔드포인트

### **음성 처리**
```http
POST /api/v1/process_voice
Content-Type: multipart/form-data

Form Data:
- audio: [오디오 파일]
- user_id: "user123" (선택사항)
```

### **서버 상태 확인**
```http
GET /api/v1/health
```

## 📊 성능 최적화

### **1. 우선순위 처리**
- `high`: 즉시 처리 (일정 추가/삭제)
- `medium`: 일반 처리 (설정 변경)
- `low`: 백그라운드 처리 (음성 응답)

### **2. 캐싱 전략**
- 음성 응답 캐싱
- 일정 데이터 로컬 저장
- 설정값 메모리 캐싱

### **3. 오프라인 지원**
- 로컬 일정 관리
- 음성 응답 오프라인 재생
- 동기화 큐 관리

## 🎨 사용자 경험

### **1. 고령자 친화적**
- 큰 글씨, 높은 음량
- 천천히 말하기
- 간단한 메시지
- 중요 정보 반복

### **2. 시각적 피드백**
- 로딩 인디케이터
- 성공/실패 알림
- 음성 재생 표시
- 진행 상태 표시

### **3. 접근성**
- 음성 안내
- 고대비 모드
- 단순한 UI
- 명확한 피드백

## 🚀 다음 단계

1. **Flutter 앱에 HTTP 클라이언트 추가**
2. **JSON 파싱 클래스 구현**
3. **액션 처리 함수 구현**
4. **UI 업데이트 로직 구현**
5. **음성 재생 기능 구현**
6. **에러 처리 및 재시도 로직**

이 가이드를 따라 구현하면 AI 서버와 완벽하게 연동되는 애플리케이션을 만들 수 있습니다! 🎯
