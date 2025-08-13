# AI Server (Text-based) - 고령층 일정 메모 관리

Flutter 애플리케이션에서 STT/TTS를 처리하는 새로운 구조의 AI 서버입니다.

## 🚀 주요 변경사항

### 이전 구조 (AI 폴더)
- **STT/TTS**: AI 서버에서 처리
- **음성 파일**: 서버로 전송하여 처리
- **응답**: 음성 파일 포함하여 반환

### 새로운 구조 (AI_02 폴더)
- **STT/TTS**: Flutter 애플리케이션에서 처리
- **텍스트**: 서버로 전송하여 처리
- **응답**: 텍스트 응답만 반환

## 📁 프로젝트 구조

```
AI_02/
├── Config/                 # 설정 파일
│   ├── settings.py        # 텍스트 기반 설정
│   └── prompts.py         # 프롬프트 관리
├── Server/                # 서버 관련
│   ├── app.py            # 메인 서버 앱
│   ├── api_routes.py     # API 라우트 (텍스트 기반)
│   ├── middleware.py     # 미들웨어
│   ├── services/         # 서비스 레이어
│   │   └── ai_service.py # AI 서비스 (텍스트 기반)
│   └── utils/            # 유틸리티
│       ├── app_response_utils.py  # 응답 유틸리티 (텍스트 기반)
│       ├── validation.py         # 검증 유틸리티 (텍스트 기반)
│       └── response_utils.py     # 기본 응답 유틸리티
├── Processor/            # 처리 파이프라인
│   └── unified_voice_pipeline.py  # 통합 텍스트 처리 파이프라인
├── Services/             # 비즈니스 로직
│   ├── Memory.py         # 메모리 관리
│   ├── ScheduleManager.py # 일정 관리
│   └── AccessibilityManager.py # 접근성 관리
├── Models/               # AI 모델
│   └── LLM/             # LLM 모델들
├── requirements.txt      # Python 의존성
└── README.md            # 프로젝트 문서
```

## 🔧 설치 및 실행

### 1. 환경 설정

```bash
# Python 가상환경 생성
python3 -m venv venv
source venv/bin/activate  # macOS/Linux
# 또는
venv\Scripts\activate     # Windows

# 의존성 설치
pip install -r requirements.txt
```

### 2. 환경 변수 설정

```bash
# .env 파일 생성
export GOOGLE_API_KEY="your_google_api_key"
export LLM_TYPE="gemini"
export AI_SERVER_HOST="0.0.0.0"
export AI_SERVER_PORT="8080"
export AI_SERVER_DEBUG="True"
```

### 3. 서버 실행

```bash
cd AI_02/Server
python3 app.py
```

## 📡 API 엔드포인트

### 텍스트 처리
- `POST /api/v1/process_text` - 텍스트 명령 처리

### 일정 관리
- `POST /api/v1/schedule/add` - 일정 추가
- `GET /api/v1/schedule/list` - 일정 목록 조회
- `DELETE /api/v1/schedule/delete` - 일정 삭제
- `GET /api/v1/schedule/read` - 특정 날짜 일정 조회
- `GET /api/v1/schedule/important` - 중요 일정 조회

### 설정 관리
- `PUT /api/v1/settings/accessibility` - 접근성 설정 업데이트
- `GET /api/v1/settings/accessibility` - 접근성 설정 조회

### 기타
- `GET /api/v1/health` - 서버 상태 확인
- `GET /api/v1/test` - 테스트 엔드포인트

## 📝 API 사용 예시

### 텍스트 처리 요청

```bash
curl -X POST http://localhost:8080/api/v1/process_text \
  -H "Content-Type: application/json" \
  -d '{
    "text": "내일 오후 3시에 병원 예약이 있어",
    "user_id": "user123"
  }'
```

### 응답 예시

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

## 🔄 Flutter 애플리케이션 연동

### 1. STT 처리 (Flutter에서)
```dart
// 음성 녹음 후 텍스트 변환
String userText = await speechToText.recognize(audioFile);
```

### 2. AI 서버 요청
```dart
// 텍스트를 서버로 전송
final response = await http.post(
  Uri.parse('http://localhost:8080/api/v1/process_text'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'text': userText,
    'user_id': userId,
  }),
);
```

### 3. TTS 처리 (Flutter에서)
```dart
// 서버 응답 텍스트를 음성으로 변환
String responseText = jsonDecode(response.body)['text_response']['text'];
await textToSpeech.speak(responseText);
```

## ⚙️ 설정 옵션

### 텍스트 처리 설정
- `MAX_TEXT_LENGTH`: 최대 텍스트 길이 (기본값: 1000)
- `MIN_TEXT_LENGTH`: 최소 텍스트 길이 (기본값: 1)
- `DEFAULT_RESPONSE_TIMEOUT`: 응답 타임아웃 (기본값: 30초)

### 고령자 설정
- `SPEECH_RATE`: 음성 속도 (기본값: 1.0)
- `VOLUME_LEVEL`: 볼륨 레벨 (기본값: 1.0)
- `SIMPLE_RESPONSES`: 간단 응답 사용 (기본값: True)
- `REPEAT_IMPORTANT`: 중요 메시지 반복 (기본값: True)

### 접근성 설정
- `DEFAULT_FONT_SIZE`: 기본 폰트 크기 (기본값: 16)
- `DEFAULT_CONTRAST_RATIO`: 기본 대비 비율 (기본값: 4.5)

## 🛠️ 개발 가이드

### 새로운 API 엔드포인트 추가

1. `Server/api_routes.py`에 라우트 추가
2. `Server/utils/validation.py`에 검증 로직 추가
3. `Server/utils/app_response_utils.py`에 응답 유틸리티 추가

### 새로운 처리 로직 추가

1. `Processor/unified_voice_pipeline.py`에 처리 로직 추가
2. `Services/` 폴더에 관련 서비스 추가
3. `Config/prompts.py`에 프롬프트 추가

## 🔍 디버깅

### 로그 확인
```bash
tail -f logs/ai_server.log
```

### 서버 상태 확인
```bash
curl http://localhost:8080/api/v1/health
```

### 설정 검증
```python
from Config.settings import Settings
errors = Settings.validate_settings()
print(errors)
```

## 📋 요구사항

- Python 3.8+
- Flask
- Google Cloud API (Gemini)
- 또는 OpenAI API
- 또는 Anthropic API

## 🤝 기여하기

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.
