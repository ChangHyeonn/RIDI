# 📱 AI_03 → 애플리케이션 JSON 응답 가이드

## 📋 개요

이 문서는 AI_03 서버가 Flutter 애플리케이션에 전달하는 모든 JSON 응답 형태를 정리한 가이드입니다.

## 🎯 기본 응답 구조

모든 응답은 다음과 같은 공통 구조를 가집니다:

```json
{
  "success": boolean,
  "action": {
    "type": string,
    "is_important": boolean,
    "data": object,
    "ui_instructions": object
  },
  "text_response": object (선택사항),
  "timestamp": string
}
```

## ✅ 성공 응답 (success: true)

### 1. 📅 일정 추가 성공

#### 1.1 일반 일정 추가

**요청 예시**: "내일 오후 3시에 병원 진료 예약"

```json
{
  "success": true,
  "action": {
    "type": "schedule_add",
    "is_important": true,
    "data": {
      "id": "507f1f77bcf86cd799439011",
      "user_id": "user123",
      "title": "병원 진료",
      "datetime": "2024-01-15T15:00:00",
      "category": "건강",
      "is_important": true,
      "location": "",
      "description": "병원 진료 예약",
      "is_recurring": false
    },
    "ui_instructions": {
      "screen": "calendar",
      "refresh_data": true,
      "highlight_date": "2024-01-15",
      "show_confirmation": true,
      "notification": {
        "type": "success",
        "title": "일정 추가됨",
        "message": "병원 진료이 추가되었습니다"
      }
    }
  },
  "text_response": {
    "text": "1월 15일 오후 3시에 병원 진료 일정을 추가하였습니다.",
    "display_automatically": true
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

#### 1.2 반복 일정 추가 (매일)


**타입	설명	예시
daily :	매일	"매일 아침 7시, 저녁 6시에 약 복용"
weekdays :	평일 (월~금)	"평일마다 오전 9시에 회의"
weekends :	주말 (토~일)	"주말마다 오후 3시에 운동"
custom_days :	특정 요일들	"월, 수, 금요일 오전 6시, 오후 5시에 기상 알람"
***요일 스펙트럼 : 0~6 == 월~일

**요청 예시**: "매일 아침 7시, 저녁 6시에 약 복용 알람 추가해 줘"

```json
{
  "success": true,
  "action": {
    "type": "schedule_add",
    "is_important": true,
    "data": {
      "id": "507f1f77bcf86cd799439012",
      "user_id": "user123",
      "title": "약 복용 알람",
      "datetime": "2024-01-15T07:00:00",
      "category": "건강",
      "is_important": true,
      "location": "",
      "description": "매일 약 복용",
      "is_recurring": true,
      "recurrence": {
        "type": "daily",
        "times": [
          {"time": "07:00", "label": "아침"},
          {"time": "18:00", "label": "저녁"}
        ],
        "end_date": null,
        "days_of_week": null
      }
    },
    "ui_instructions": {
      "screen": "calendar",
      "refresh_data": true,
      "highlight_date": "2024-01-15",
      "show_confirmation": true,
      "highlight_recurring": true,
      "show_multiple_times": true,
      "show_indefinite": true,
      "notification": {
        "type": "success",
        "title": "반복 일정 추가됨",
        "message": "약 복용 알람 매일 2회이 추가되었습니다"
      }
    }
  },
  "text_response": {
    "text": "매일 아침 7시와 저녁 6시에 약 복용 알람 일정을 추가하였습니다.",
    "display_automatically": true
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

#### 1.3 반복 일정 추가 (평일마다)

**요청 예시**: "평일마다 오전 9시에 회의 일정 추가해 줘"

```json
{
  "success": true,
  "action": {
    "type": "schedule_add",
    "is_important": false,
    "data": {
      "id": "507f1f77bcf86cd799439013",
      "user_id": "user123",
      "title": "회의",
      "datetime": "2024-01-15T09:00:00",
      "category": "일반",
      "is_important": false,
      "location": "",
      "description": "평일 회의",
      "is_recurring": true,
      "recurrence": {
        "type": "weekdays",
        "times": [
          {"time": "09:00", "label": "오전"}
        ],
        "end_date": null,
        "days_of_week": null
      }
    },
    "ui_instructions": {
      "screen": "calendar",
      "refresh_data": true,
      "highlight_date": "2024-01-15",
      "show_confirmation": true,
      "highlight_recurring": true,
      "show_indefinite": true,
      "notification": {
        "type": "success",
        "title": "반복 일정 추가됨",
        "message": "회의 평일마다이 추가되었습니다"
      }
    }
  },
  "text_response": {
    "text": "평일마다 오전 9시에 회의 일정을 추가하였습니다.",
    "display_automatically": true
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

#### 1.4 반복 일정 추가 (특정 요일들)

**요청 예시**: "월, 수, 금요일 오전 6시, 그리고 오후 5시에 기상 알람을 만들어 줄래?"

```json
{
  "success": true,
  "action": {
    "type": "schedule_add",
    "is_important": false,
    "data": {
      "id": "507f1f77bcf86cd799439014",
      "user_id": "user123",
      "title": "기상 알람",
      "datetime": "2024-01-15T06:00:00",
      "category": "일반",
      "is_important": false,
      "location": "",
      "description": "월, 수, 금 기상 알람",
      "is_recurring": true,
      "recurrence": {
        "type": "custom_days",
        "times": [
          {"time": "06:00", "label": "오전"},
          {"time": "17:00", "label": "오후"}
        ],
        "end_date": null,
        "days_of_week": [0, 2, 4]
      }
    },
    "ui_instructions": {
      "screen": "calendar",
      "refresh_data": true,
      "highlight_date": "2024-01-15",
      "show_confirmation": true,
      "highlight_recurring": true,
      "show_multiple_times": true,
      "show_indefinite": true,
      "show_custom_days": true,
      "notification": {
        "type": "success",
        "title": "반복 일정 추가됨",
        "message": "기상 알람 월, 화요일마다 2회이 추가되었습니다"
      }
    }
  },
  "text_response": {
    "text": "월, 수, 금요일마다 오전 6시와 오후 5시에 기상 알람 일정을 추가하였습니다.",
    "display_automatically": true
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

#### 1.5 반복 일정 추가 (종료 날짜 있음)

**요청 예시**: "내년 9월까지 매일 아침 7시, 저녁 6시마다 약 복용 알람 추가해 줘"

```json
{
  "success": true,
  "action": {
    "type": "schedule_add",
    "is_important": true,
    "data": {
      "id": "507f1f77bcf86cd799439015",
      "user_id": "user123",
      "title": "약 복용 알람",
      "datetime": "2024-01-15T07:00:00",
      "category": "건강",
      "is_important": true,
      "location": "",
      "description": "2025년 9월까지 약 복용",
      "is_recurring": true,
      "recurrence": {
        "type": "daily",
        "times": [
          {"time": "07:00", "label": "아침"},
          {"time": "18:00", "label": "저녁"}
        ],
        "end_date": "2025-09-30",
        "days_of_week": null
      }
    },
    "ui_instructions": {
      "screen": "calendar",
      "refresh_data": true,
      "highlight_date": "2024-01-15",
      "show_confirmation": true,
      "highlight_recurring": true,
      "show_multiple_times": true,
      "show_end_date": true,
      "notification": {
        "type": "success",
        "title": "반복 일정 추가됨",
        "message": "약 복용 알람 매일 2회이 추가되었습니다"
      }
    }
  },
  "text_response": {
    "text": "2025년 9월까지 매일 아침 7시와 저녁 6시에 약 복용 알람 일정을 추가하였습니다.",
    "display_automatically": true
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

### 2. 📖 일정 조회 성공

**요청 예시**: "내일 일정이 뭐야?"

```json
{
  "success": true,
  "action": {
    "type": "schedule_list",
    "is_important": false,
    "data": {
      "schedules": [
        {
          "id": "507f1f77bcf86cd799439011",
          "user_id": "user123",
          "title": "병원 진료",
          "datetime": "2024-01-15T15:00:00",
          "category": "건강",
          "is_important": true,
          "location": "서울대병원",
          "description": "정기 검진",
          "status": "scheduled"
        },
        {
          "id": "507f1f77bcf86cd799439012",
          "user_id": "user123",
          "title": "친구 만남",
          "datetime": "2024-01-15T19:00:00",
          "category": "일반",
          "is_important": false,
          "location": "강남역",
          "description": "저녁 식사",
          "status": "scheduled"
        }
      ]
    },
    "ui_instructions": {
      "screen": "schedule_list",
      "refresh_data": true,
      "highlight_important": true
    }
  },
  "text_response": {
    "text": "내일은 2개의 일정이 있습니다. 오후 3시에 병원 진료, 오후 7시에 친구 만남이 예정되어 있어요.",
    "display_automatically": true
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

### 3. 🗑️ 일정 삭제 성공

**요청 예시**: "병원 예약 취소해줘"

```json
{
  "success": true,
  "action": {
    "type": "schedule_delete",
    "is_important": true,
    "data": {
      "id": "507f1f77bcf86cd799439011",
      "user_id": "user123",
      "title": "병원 진료",
      "datetime": "2024-01-15T15:00:00",
      "category": "건강",
      "is_important": true,
      "location": "서울대병원",
      "description": "정기 검진",
      "status": "cancelled"
    },
    "ui_instructions": {
      "screen": "calendar",
      "refresh_data": true,
      "highlight_date": "2024-01-15",
      "remove_item": "507f1f77bcf86cd799439011",
      "notification": {
        "type": "info",
        "title": "일정 삭제됨",
        "message": "일정이 삭제되었습니다"
      }
    }
  },
  "text_response": {
    "text": "1월 15일 오후 3시 병원 진료 일정을 삭제하였습니다.",
    "display_automatically": true
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

### 4. 💬 일반 대화 응답

**요청 예시**: "안녕하세요"

```json
{
  "success": true,
  "action": {
    "type": "text_response",
    "is_important": false,
    "data": {},
    "ui_instructions": {
      "show_text_indicator": true
    }
  },
  "text_response": {
    "text": "안녕하세요! 무엇을 도와드릴까요? 일정 관리나 기타 질문이 있으시면 언제든 말씀해주세요.",
    "display_automatically": true
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

### 5. ⚕️ 서버 상태 확인 성공

**엔드포인트**: `GET /api/v1/health`

```json
{
  "success": true,
  "action": {
    "type": "health_check",
    "is_important": false,
    "data": {
      "status": "healthy",
      "server_info": {
        "version": "3.0.0",
        "architecture": "Clean Architecture",
        "llm_provider": "OpenAI",
        "database": "MongoDB"
      },
      "components": {
        "llm_service": "operational",
        "database": "connected",
        "schedule_manager": "ready"
      },
      "uptime": "2 hours 15 minutes",
      "memory_usage": "245MB",
      "active_connections": 3
    },
    "ui_instructions": {}
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

## ❌ 실패 응답 (success: false)

### 1. 🔍 입력 검증 에러

#### 1.1 필수 데이터 누락

**요청 예시**: `{"user_id": "user123"}` (text 필드 누락)

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "missing_required_data",
      "message": "텍스트와 사용자 ID가 필요합니다."
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "텍스트와 사용자 ID가 필요합니다.",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

#### 1.2 잘못된 Content-Type

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "missing_content_type",
      "message": "Content-Type must be application/json"
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "Content-Type must be application/json",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

### 2. 📝 일정 정보 검증 에러

#### 2.1 일정 제목 누락

**요청 예시**: "일정 추가해 줘"

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "missing_schedule_title",
      "message": "구체적인 일정 내용을 말씀해주세요. 예: \"병원 진료\", \"친구 만남\", \"회사 회의\" 등"
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "구체적인 일정 내용을 말씀해주세요. 예: \"병원 진료\", \"친구 만남\", \"회사 회의\" 등",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

#### 2.2 비구체적 일정 제목

**요청 예시**: "내일 일정 하나 추가해 줘"

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "generic_schedule_title",
      "message": "\"일정\" 대신 구체적인 내용을 말씀해주세요. 예: \"병원 진료\", \"친구 만남\" 등"
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "\"일정\" 대신 구체적인 내용을 말씀해주세요. 예: \"병원 진료\", \"친구 만남\" 등",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

#### 2.3 일정 제목이 너무 짧음

**요청 예시**: "내일 가"

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "short_schedule_title",
      "message": "일정 제목이 너무 짧습니다. 좀 더 구체적으로 설명해주세요."
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "일정 제목이 너무 짧습니다. 좀 더 구체적으로 설명해주세요.",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

#### 2.4 일정 날짜 누락

**요청 예시**: "병원 진료 추가해 줘"

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "missing_schedule_date",
      "message": "일정 날짜를 명확히 말씀해주세요. 예: \"내일\", \"모레\", \"월요일\" 등"
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "일정 날짜를 명확히 말씀해주세요. 예: \"내일\", \"모레\", \"월요일\" 등",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

#### 2.5 일정 시간 누락

**요청 예시**: "내일 병원 진료 추가해 줘"

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "missing_schedule_time",
      "message": "일정 시간을 명확히 말씀해주세요. 예: \"오전 9시\", \"오후 3시 30분\" 등"
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "일정 시간을 명확히 말씀해주세요. 예: \"오전 9시\", \"오후 3시 30분\" 등",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

#### 2.6 잘못된 날짜 형식

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "invalid_date_format",
      "message": "잘못된 날짜 형식입니다. 날짜를 다시 명확히 말씀해주세요."
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "잘못된 날짜 형식입니다. 날짜를 다시 명확히 말씀해주세요.",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

#### 2.7 잘못된 시간 형식

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "invalid_time_format",
      "message": "잘못된 시간 형식입니다. 시간을 다시 명확히 말씀해주세요."
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "잘못된 시간 형식입니다. 시간을 다시 명확히 말씀해주세요.",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

### 3. 🗄️ 데이터베이스/저장 에러

#### 3.1 일정 저장 실패

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "schedule_save_error",
      "message": "일정 저장에 실패했습니다."
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "일정 저장에 실패했습니다.",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

#### 3.2 데이터베이스 연결 오류

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "database_error",
      "message": "데이터 저장 중 오류가 발생했습니다."
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "데이터 저장 중 오류가 발생했습니다.",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

### 4. 🔍 일정 조회/삭제 에러

#### 4.1 일정을 찾을 수 없음

**요청 예시**: "병원 예약 취소해줘" (해당 일정이 없는 경우)

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "schedule_not_found",
      "message": "일정을 찾을 수 없습니다."
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "일정을 찾을 수 없습니다.",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

#### 4.2 일정 삭제 실패

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "schedule_delete_error",
      "message": "일정 삭제에 실패했습니다."
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "일정 삭제에 실패했습니다.",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

### 5. 🤖 AI 처리 에러

#### 5.1 LLM 처리 오류

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "llm_error",
      "message": "언어모델 처리 중 오류가 발생했습니다."
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "언어모델 처리 중 오류가 발생했습니다.",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

#### 5.2 의도 분석 실패

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "intent_analysis_error",
      "message": "요청 분석 중 오류가 발생했습니다."
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "요청 분석 중 오류가 발생했습니다.",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

#### 5.3 응답 생성 실패

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "response_generation_error",
      "message": "응답 생성 중 오류가 발생했습니다."
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "응답 생성 중 오류가 발생했습니다.",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

### 6. 🌐 HTTP 에러

#### 6.1 잘못된 요청 (400)

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "bad_request",
      "message": "잘못된 요청입니다."
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "잘못된 요청입니다.",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

#### 6.2 리소스를 찾을 수 없음 (404)

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "not_found",
      "message": "요청한 리소스를 찾을 수 없습니다."
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "요청한 리소스를 찾을 수 없습니다.",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

#### 6.3 서버 내부 오류 (500)

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "internal_error",
      "message": "서버 내부 오류가 발생했습니다."
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "서버 내부 오류가 발생했습니다.",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

### 7. ⚕️ 서버 상태 에러

#### 7.1 헬스체크 실패

**엔드포인트**: `GET /api/v1/health`

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "health_check_error",
      "message": "서버 상태 확인 중 오류가 발생했습니다"
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "서버 상태 확인 중 오류가 발생했습니다",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

### 8. ⚠️ 시스템 예외

#### 8.1 시스템 오류

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "system_error",
      "message": "시스템 오류가 발생했습니다."
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "시스템 오류가 발생했습니다.",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

#### 8.2 예상치 못한 오류

```json
{
  "success": false,
  "action": {
    "type": "error",
    "is_important": true,
    "data": {
      "error_type": "unexpected_error",
      "message": "예상치 못한 오류가 발생했습니다."
    },
    "ui_instructions": {
      "notification": {
        "type": "error",
        "title": "오류 발생",
        "message": "예상치 못한 오류가 발생했습니다.",
        "duration": 5000
      }
    }
  },
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

## 📊 에러 타입 분류표

| 카테고리 | 에러 타입 | 설명 |
|----------|-----------|------|
| **입력 검증** | `validation_error` | 일반적인 입력 검증 실패 |
| | `invalid_request` | 유효하지 않은 요청 |
| | `missing_content_type` | Content-Type 헤더 누락 |
| | `missing_required_data` | 필수 데이터 누락 |
| **일정 검증** | `schedule_validation_error` | 일반적인 일정 검증 실패 |
| | `missing_schedule_title` | 일정 제목 누락 |
| | `generic_schedule_title` | 비구체적 일정 제목 |
| | `short_schedule_title` | 일정 제목이 너무 짧음 |
| | `missing_schedule_date` | 일정 날짜 누락 |
| | `missing_schedule_time` | 일정 시간 누락 |
| | `invalid_date_format` | 잘못된 날짜 형식 |
| | `invalid_time_format` | 잘못된 시간 형식 |
| **데이터베이스** | `database_error` | 데이터베이스 오류 |
| | `schedule_save_error` | 일정 저장 실패 |
| | `data_parsing_error` | 데이터 파싱 오류 |
| **일정 조작** | `schedule_not_found` | 일정을 찾을 수 없음 |
| | `schedule_delete_error` | 일정 삭제 실패 |
| | `insufficient_delete_info` | 삭제 정보 부족 |
| **AI 처리** | `ai_processing_error` | AI 처리 오류 |
| | `llm_error` | 언어모델 오류 |
| | `intent_analysis_error` | 의도 분석 실패 |
| | `response_generation_error` | 응답 생성 실패 |
| **서버 상태** | `health_check_error` | 서버 상태 확인 오류 |
| | `server_error` | 서버 오류 |
| **HTTP** | `bad_request` | 잘못된 요청 (400) |
| | `not_found` | 리소스 없음 (404) |
| | `internal_error` | 서버 내부 오류 (500) |
| **시스템** | `system_error` | 시스템 오류 |
| | `unexpected_error` | 예상치 못한 오류 |

## 🎯 UI 지시사항 필드 설명

### `ui_instructions` 공통 필드

#### 기본 UI 지시사항
- **`screen`**: 이동할 화면 (`"calendar"`, `"schedule_list"` 등)
- **`refresh_data`**: 데이터 새로고침 여부 (`true`/`false`)
- **`highlight_date`**: 하이라이트할 날짜 (`"2024-01-15"`)
- **`highlight_important`**: 중요한 일정 강조 표시 (`true`/`false`)
- **`show_confirmation`**: 확인 메시지 표시 (`true`/`false`)
- **`remove_item`**: 삭제할 아이템 ID
- **`show_text_indicator`**: 텍스트 응답 인디케이터 표시 (`true`/`false`)

#### 반복 일정 UI 지시사항 (신규)
- **`highlight_recurring`**: 반복 일정 강조 표시 (`true`/`false`)
- **`show_multiple_times`**: 하루 다중 시간 표시 (`true`/`false`)
- **`show_end_date`**: 종료 날짜 표시 (`true`/`false`)
- **`show_indefinite`**: 무기한 표시 (`true`/`false`)
- **`show_custom_days`**: 특정 요일 표시 (`true`/`false`)

### `notification` 필드

- **`type`**: 알림 타입 (`"success"`, `"error"`, `"info"`, `"warning"`)
- **`title`**: 알림 제목
- **`message`**: 알림 메시지
- **`duration`**: 알림 표시 시간 (밀리초)

## 📱 Flutter 앱에서의 사용 예시

### 응답 파싱

```dart
Map<String, dynamic> response = jsonDecode(responseBody);

bool success = response['success'];
String actionType = response['action']['type'];
bool isImportant = response['action']['is_important'];
Map<String, dynamic> actionData = response['action']['data'];
Map<String, dynamic> uiInstructions = response['action']['ui_instructions'];

if (response['text_response'] != null) {
  String responseText = response['text_response']['text'];
  bool displayAutomatically = response['text_response']['display_automatically'];
}
```

### 에러 처리

```dart
if (!success && actionType == 'error') {
  String errorType = actionData['error_type'];
  String errorMessage = actionData['message'];
  
  switch (errorType) {
    case 'missing_schedule_title':
      _showScheduleValidationError(errorMessage);
      break;
    case 'database_error':
      _showDatabaseError(errorMessage);
      break;
    // ... 기타 에러 타입 처리
  }
}
```

### 반복 일정 처리

```dart
if (success && actionType == 'schedule_add') {
  bool isRecurring = actionData['is_recurring'] ?? false;
  
  if (isRecurring) {
    Map<String, dynamic> recurrence = actionData['recurrence'];
    String recurrenceType = recurrence['type']; // daily, weekdays, weekends, custom_days
    List<dynamic> times = recurrence['times'] ?? [];
    String? endDate = recurrence['end_date'];
    List<dynamic>? daysOfWeek = recurrence['days_of_week'];
    
    // 반복 일정 UI 처리
    if (uiInstructions['highlight_recurring'] == true) {
      _showRecurringIndicator();
    }
    
    if (uiInstructions['show_multiple_times'] == true) {
      _showMultipleTimesIcon(times.length);
    }
    
    if (uiInstructions['show_end_date'] == true) {
      _showEndDateBadge(endDate);
    }
    
    if (uiInstructions['show_indefinite'] == true) {
      _showIndefiniteBadge();
    }
    
    if (uiInstructions['show_custom_days'] == true) {
      _showCustomDaysIndicator(daysOfWeek);
    }
    
    // 반복 설명 텍스트 생성
    String recurrenceDescription = _generateRecurrenceDescription(recurrence);
    _updateScheduleListWithRecurrence(actionData, recurrenceDescription);
  } else {
    // 일반 일정 처리
    _addRegularSchedule(actionData);
  }
}

String _generateRecurrenceDescription(Map<String, dynamic> recurrence) {
  String type = recurrence['type'];
  List<dynamic> times = recurrence['times'] ?? [];
  String? endDate = recurrence['end_date'];
  
  String typeDesc = {
    'daily': '매일',
    'weekdays': '평일마다',
    'weekends': '주말마다',
    'custom_days': '특정 요일마다'
  }[type] ?? '반복';
  
  String timesDesc = times.length > 1 ? ' (하루 ${times.length}회)' : '';
  String endDesc = endDate != null ? ' ($endDate까지)' : ' (무기한)';
  
  return typeDesc + timesDesc + endDesc;
}
```

## 🔧 개발 팁

1. **에러 타입 기반 처리**: `error_type` 필드를 사용해 에러별 맞춤 UI 제공
2. **UI 지시사항 활용**: `ui_instructions`로 화면 전환 및 사용자 경험 향상
3. **중요도 표시**: `is_important` 필드로 알림 우선순위 설정
4. **타임스탬프 활용**: 응답 시간 기록 및 디버깅에 활용
5. **반복 일정 구분**: `is_recurring` 필드로 일반/반복 일정 구분 처리
6. **반복 패턴 활용**: `recurrence.type`으로 다양한 반복 유형 지원
7. **다중 시간 처리**: `recurrence.times` 배열로 하루 내 여러 시간 관리
8. **종료 조건 표시**: `end_date` 유무로 무기한/기한부 반복 구분
9. **요일 매핑**: `days_of_week` 배열 (0=월요일)로 커스텀 요일 지원

---

**버전**: 3.0.0 (Clean Architecture)  
**최종 업데이트**: 2024년 1월  
**아키텍처**: Clean Architecture with Dependency Injection
