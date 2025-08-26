# AI Server - 고령층 일정 메모 관리 시스템

Clean Architecture 패턴을 기반으로 한 고령층 친화적 일정 관리 AI 서버입니다. 자연어 처리를 통해 일정 추가, 조회, 삭제 기능을 제공하며, 반복 일정과 명확화 요청 처리 기능을 포함합니다.

## 🏗️ 아키텍처

### Clean Architecture 패턴
```
ai_server/
├── Config/                 # 설정 및 프롬프트
├── core/                   # 핵심 비즈니스 로직
│   ├── entities/          # 도메인 엔티티
│   ├── interfaces/        # 인터페이스 정의
│   └── usecases/          # 유스케이스 구현
├── infrastructure/        # 외부 시스템 연동
├── presentation/          # API 및 컨트롤러
├── shared/               # 공통 유틸리티
└── tests/                # 테스트 코드
```

## 🚀 주요 기능

### 1. 일정 관리
- **일정 추가**: 자연어로 일정 생성 (반복 일정 지원)
- **일정 조회**: 키워드 검색, 날짜별 조회
- **일정 삭제**: 스펙트럼 검색을 통한 정확한 삭제

### 2. 반복 일정 검증
- **요일 정보 검증**: `days_of_week` 필드 누락 시 명확화 요청
- **명확화 요청**: 사용자에게 추가 정보 요청
- **세션 관리**: 명확화 요청 정보 임시 저장

### 3. 스마트 검색
- **유사도 기반 삭제**: Jaccard 유사도 + 키워드 매칭
- **키워드 검색**: 일정 내용 기반 검색
- **날짜 기반 검색**: 상대적/절대적 날짜 표현 지원

## 📁 프로젝트 구조

```
ai_server/
├── Config/
│   ├── prompts.py         # LLM 프롬프트 관리
│   └── settings.py        # 서버 설정
├── core/
│   ├── entities/
│   │   ├── schedule.py    # 일정 엔티티
│   │   └── text_request.py # 텍스트 요청 엔티티
│   ├── interfaces/
│   │   ├── repositories/  # 저장소 인터페이스
│   │   └── services/      # 서비스 인터페이스
│   └── usecases/
│       ├── schedule/      # 일정 관련 유스케이스
│       └── text_processing/ # 텍스트 처리 유스케이스
├── infrastructure/
│   ├── external/          # 외부 서비스 연동
│   └── repositories/      # 저장소 구현체
├── presentation/
│   ├── api/              # API 엔드포인트
│   ├── dto/              # 데이터 전송 객체
│   └── middleware/       # 미들웨어
├── shared/
│   ├── config/           # 공통 설정
│   ├── constants/        # 상수 정의
│   ├── container.py      # 의존성 주입 컨테이너
│   └── logging/          # 로깅 시스템
└── main.py               # 서버 진입점
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
export OPENAI_API_KEY="your_openai_api_key"
export LLM_TYPE="openai"
export AI_SERVER_HOST="0.0.0.0"
export AI_SERVER_PORT="8080"
export AI_SERVER_DEBUG="True"
```

### 3. 서버 실행

```bash
# 기본 실행 (메모리 저장소)
python3 main.py

# MongoDB 사용
python3 main.py --db-engine mongodb
```

## 📡 API 엔드포인트

### 메인 처리
- `POST /api/v1/process_text` - 텍스트 명령 처리 (모든 기능 통합)

### 기타
- `GET /api/v1/health` - 서버 상태 확인

## 📝 API 사용 예시

### 1. 일정 추가

```bash
curl -X POST http://localhost:8080/api/v1/process_text \
  -H "Content-Type: application/json" \
  -d '{
    "text": "내일 오후 3시에 병원 예약이 있어",
    "user_id": "user123"
  }'
```

### 2. 반복 일정 추가 (요일 정보 누락)

```bash
curl -X POST http://localhost:8080/api/v1/process_text \
  -H "Content-Type: application/json" \
  -d '{
    "text": "8월 25일부터 매주 오전 9시에 회의 일정 추가해줘",
    "user_id": "user123"
  }'
```

**응답**: 명확화 요청
```json
{
  "success": false,
  "action": {
    "type": "clarification_request",
    "data": {
      "clarification_text": "반복 일정의 요일 정보가 필요합니다. 언제 반복할지 요일을 말씀해주세요.",
      "missing_fields": ["days_of_week"]
    }
  }
}
```

### 3. 명확화 요청 응답

```bash
curl -X POST http://localhost:8080/api/v1/process_text \
  -H "Content-Type: application/json" \
  -d '{
    "text": "월요일이요",
    "user_id": "user123"
  }'
```

**응답**: 일정 추가 성공
```json
{
  "success": true,
  "action": {
    "type": "schedule_add",
    "data": {
      "title": "회의",
      "datetime": "2025-08-25T09:00:00",
      "is_recurring": true,
      "recurrence": {
        "type": "weekly",
        "days_of_week": [0]
      }
    }
  }
}
```

### 4. 일정 조회

```bash
curl -X POST http://localhost:8080/api/v1/process_text \
  -H "Content-Type: application/json" \
  -d '{
    "text": "이번 주 일정 보여줘",
    "user_id": "user123"
  }'
```

### 5. 일정 삭제

```bash
curl -X POST http://localhost:8080/api/v1/process_text \
  -H "Content-Type: application/json" \
  -d '{
    "text": "병원 예약 삭제해줘",
    "user_id": "user123"
  }'
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

### 3. 응답 처리
```dart
final responseData = jsonDecode(response.body);
final actionType = responseData['action']['type'];

switch (actionType) {
  case 'schedule_add':
    // 일정 추가 처리
    break;
  case 'clarification_request':
    // 명확화 요청 처리
    break;
  case 'schedule_selection':
    // 일정 선택 UI 표시
    break;
}
```

### 4. TTS 처리 (Flutter에서)
```dart
// 서버 응답 텍스트를 음성으로 변환
String responseText = responseData['text_response']['text'];
await textToSpeech.speak(responseText);
```

## ⚙️ 설정 옵션

### 서버 설정
- `AI_SERVER_HOST`: 서버 호스트 (기본값: 0.0.0.0)
- `AI_SERVER_PORT`: 서버 포트 (기본값: 8080)
- `AI_SERVER_DEBUG`: 디버그 모드 (기본값: False)

### LLM 설정
- `OPENAI_API_KEY`: OpenAI API 키
- `LLM_TYPE`: LLM 타입 (기본값: openai)
- `LLM_MODEL`: 모델명 (기본값: gpt-4o-mini)

### 데이터베이스 설정
- `DB_ENGINE`: 데이터베이스 엔진 (memory/mongodb)
- `MONGODB_URI`: MongoDB 연결 문자열

## 🛠️ 개발 가이드

### 새로운 유스케이스 추가

1. `core/usecases/` 폴더에 유스케이스 클래스 생성
2. `core/interfaces/` 폴더에 인터페이스 정의
3. `infrastructure/` 폴더에 구현체 생성
4. `shared/container.py`에 의존성 주입 설정

### 새로운 API 엔드포인트 추가

1. `presentation/api/v1/` 폴더에 컨트롤러 추가
2. `presentation/dto/` 폴더에 DTO 클래스 생성
3. `presentation/app_factory.py`에 라우트 등록

### 새로운 엔티티 추가

1. `core/entities/` 폴더에 엔티티 클래스 생성
2. `core/interfaces/repositories/` 폴더에 저장소 인터페이스 정의
3. `infrastructure/repositories/` 폴더에 저장소 구현체 생성

## 🔍 디버깅

### 로그 확인
```bash
tail -f logs/ai_server.log
```

### 서버 상태 확인
```bash
curl http://localhost:8080/api/v1/health
```

### 세션 정보 확인
```python
# ProcessTextUseCase에서 세션 정보 로깅
self.logger.info(f"User session: {self._user_sessions}")
```

## 📋 요구사항

- Python 3.8+
- Flask
- OpenAI API (GPT-4o-mini)
- MongoDB (선택사항)

## 🤝 기여하기

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.
