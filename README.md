# AI Text Processing Server (Clean Architecture)

> **고령층 일정 관리 AI 서버 - Clean Architecture 기반**

## 🎯 **프로젝트 개요**

Flutter 애플리케이션을 위한 텍스트 기반 AI 서버입니다. Clean Architecture 원칙을 적용하여 유지보수성, 확장성, 테스트 가능성을 극대화했습니다.

### **주요 특징**

- ✅ **텍스트 전용**: STT/TTS는 클라이언트에서 처리
- ✅ **Clean Architecture**: 계층 분리, 의존성 역전
- ✅ **LLM 통합**: OpenAI GPT-4o-mini 활용
- ✅ **유연한 저장소**: MongoDB/Memory 지원
- ✅ **의존성 주입**: 모듈화된 컴포넌트 관리

## 🏗️ **Architecture Overview**

```
┌─────────────────────────────────────────────────────────┐
│                 Presentation Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │   API       │  │     DTO     │  │ Validators  │     │
│  │ Controllers │  │  Requests   │  │             │     │
│  │             │  │ Responses   │  │             │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└─────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────┐
│                   Core Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │  Entities   │  │  Use Cases  │  │ Interfaces  │     │
│  │ (Domain)    │  │ (Business)  │  │   (Ports)   │     │
│  │             │  │             │  │             │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└─────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────┐
│               Infrastructure Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │ Repositories│  │ External    │  │   Shared    │     │
│  │ (Adapters)  │  │ Services    │  │ Components  │     │
│  │             │  │             │  │             │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└─────────────────────────────────────────────────────────┘
```

## 📁 **디렉토리 구조**

```
AI_03/
├── main.py                     # 애플리케이션 진입점
├── requirements.txt            # Python 의존성
├── README.md                   # 프로젝트 문서
│
├── core/                       # 핵심 비즈니스 로직
│   ├── entities/               # 도메인 모델
│   │   ├── schedule.py         # 일정 엔티티
│   │   └── text_request.py     # 텍스트 요청/응답 엔티티
│   ├── usecases/               # 비즈니스 유스케이스
│   │   ├── text_processing/    # 텍스트 처리 유스케이스
│   │   └── schedule/           # 일정 관리 유스케이스
│   └── interfaces/             # 포트 (인터페이스)
│       ├── repositories/       # 저장소 인터페이스
│       └── services/           # 서비스 인터페이스
│
├── infrastructure/             # 외부 시스템 어댑터
│   ├── repositories/           # 데이터 저장소 구현
│   │   ├── mongodb_schedule_repository.py
│   │   └── memory_schedule_repository.py
│   └── external/               # 외부 서비스 구현
│       └── llm/                # LLM 서비스 구현
│           └── openai_llm_service.py
│
├── presentation/               # 프레젠테이션 계층
│   ├── api/v1/                 # REST API 엔드포인트
│   │   └── text_controller.py  # 텍스트 처리 컨트롤러
│   ├── dto/                    # 데이터 전송 객체
│   │   ├── requests.py         # 요청 DTO
│   │   └── responses.py        # 응답 DTO
│   └── app_factory.py          # Flask 앱 팩토리
│
└── shared/                     # 공통 모듈
    ├── config/                 # 설정 관리
    │   └── settings.py         # 앱 설정
    ├── logging/                # 로깅 시스템
    │   └── logger.py           # 통합 로거
    └── container.py            # 의존성 주입 컨테이너
```

## 🚀 **Quick Start**

### **1. 환경 설정**

```bash
# 1. 프로젝트 디렉토리 이동
cd AI_03

# 2. 가상환경 활성화 (권장)
conda activate RIDI

# 3. 의존성 설치
pip install -r requirements.txt

# 4. 환경변수 설정
export OPENAI_API_KEY="your-openai-api-key"
```

### **2. 서버 실행**

```bash
# 기본 실행 (Memory DB)
python3 main.py

# MongoDB 사용
python3 main.py --db-engine mongodb

# 디버그 모드
python3 main.py --debug

# 포트 변경
python3 main.py --port 9000
```

### **3. API 테스트**

```bash
# 헬스체크
curl http://localhost:8080/api/v1/health

# 텍스트 처리
curl -X POST http://localhost:8080/api/v1/process_text \
  -H "Content-Type: application/json" \
  -d '{"text": "내일 오후 3시에 병원 예약", "user_id": "user123"}'
```

## 📡 **API 엔드포인트**

### **POST /api/v1/process_text**
텍스트 요청 처리

**요청:**
```json
{
  "text": "내일 오후 3시에 병원 예약",
  "user_id": "user123"
}
```

**응답:**
```json
{
  "success": true,
  "processing_result": {
    "action": "schedule_add",
    "result": {
      "schedule_data": {
        "title": "병원 예약",
        "datetime": "2024-01-15T15:00:00",
        "is_important": false
      }
    }
  },
  "response_text": "1월 15일 15시에 병원 예약 일정을 추가하였습니다.",
  "processing_time": 1.23,
  "timestamp": "2024-01-14T10:30:00.123456"
}
```

### **GET /api/v1/health**
서버 상태 확인

**응답:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-14T10:30:00.123456",
  "service": "AI Text Processing Server",
  "version": "2.0.0"
}
```

## ⚙️ **설정**

### **환경변수**

| 변수명 | 설명 | 기본값 |
|--------|------|--------|
| `OPENAI_API_KEY` | OpenAI API 키 | 필수 |
| `AI_SERVER_HOST` | 서버 호스트 | `0.0.0.0` |
| `AI_SERVER_PORT` | 서버 포트 | `8080` |
| `DB_ENGINE` | 데이터베이스 엔진 | `inmemory` |
| `MONGO_URI` | MongoDB 연결 URI | `mongodb://localhost:27017/` |

## 🧪 **테스트**

### **기본 테스트**
```bash
# 설정 유효성 검사
python3 -c "
from shared.config.settings import AppSettings
settings = AppSettings()
errors = settings.validate()
print('✅ Settings valid' if not errors else f'❌ Errors: {errors}')
"

# 컴포넌트 로딩 테스트
python3 -c "
from presentation.app_factory import create_app
app = create_app()
print('✅ App created successfully')
"
```

## 🔧 **개발**

### **새로운 기능 추가**

1. **새 엔티티**: `core/entities/`에 도메인 모델 추가
2. **새 유스케이스**: `core/usecases/`에 비즈니스 로직 추가
3. **새 저장소**: `infrastructure/repositories/`에 어댑터 추가
4. **새 API**: `presentation/api/v1/`에 컨트롤러 추가

### **Clean Architecture 원칙**

- **의존성 방향**: Infrastructure → Core ← Presentation
- **계층 간 통신**: Interface(Port)를 통한 통신만 허용
- **비즈니스 로직**: Core 계층에만 존재
- **외부 의존성**: Infrastructure 계층에서만 참조

## 🚨 **트러블슈팅**

### **자주 발생하는 문제**

1. **OpenAI API 키 오류**
   ```bash
   export OPENAI_API_KEY="sk-..."
   ```

2. **MongoDB 연결 실패**
   ```bash
   # MongoDB 실행 확인
   brew services start mongodb-community
   ```

3. **포트 충돌**
   ```bash
   python3 main.py --port 9000
   ```

## 📈 **성능 특징**

- **응답 시간**: 평균 1-3초 (LLM 응답 시간 포함)
- **동시 접속**: Flask의 threaded=True로 멀티스레드 지원
- **메모리 사용**: 경량화된 구조로 최소 메모리 사용
- **확장성**: Clean Architecture로 수평 확장 가능

## 🔄 **버전 히스토리**

- **v2.0.0**: Clean Architecture 적용, 텍스트 전용 처리
- **v1.x**: 기존 통합 아키텍처 (AI_02)

---

**Made with ❤️ for 고령층 일정 관리**