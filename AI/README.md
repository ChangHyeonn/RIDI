# AI Server for Elderly Schedule Management

고령층 일정 메모 관리 애플리케이션을 위한 AI 서버입니다.

## 🚀 기능

- **음성 인식 (STT)**: 고령자를 위한 최적화된 음성-텍스트 변환
- **자연어 처리 (LLM)**: 일정 관리에 특화된 AI 대화
- **음성 합성 (TTS)**: 고령자 친화적인 음성 응답
- **일정 분류**: 음성 명령을 구조화된 일정으로 변환
- **메모리 관리**: 사용자별 상호작용 및 일정 히스토리 관리
- **고령자 특화**: 느린 음성, 큰 볼륨, 간단한 응답

## 📁 프로젝트 구조

```
AI/
├── Config/                 # 설정 관리
│   ├── settings.py        # 애플리케이션 설정
│   └── logging_config.py  # 로깅 설정
├── Models/                 # AI 모델들
│   ├── STT.py            # 음성-텍스트 변환
│   ├── TTS.py            # 텍스트-음성 변환
│   ├── LLM.py            # 대화형 AI
│   ├── Classifier.py     # 일정 분류
│   └── Memory.py         # 메모리 관리
├── Processor/             # 처리 파이프라인
│   ├── voice_pipeline.py
│   └── integrated_pipeline.py
├── Server/                # 서버 관련
│   ├── app.py            # 메인 애플리케이션
│   ├── api_routes.py     # API 라우트
│   ├── middleware.py     # 미들웨어
│   ├── services/         # 서비스 레이어
│   │   └── ai_service.py
│   └── utils/            # 유틸리티
│       ├── response_utils.py
│       ├── validation.py
│       └── auth.py
├── main.py               # 메인 실행 파일
├── config.yaml           # 설정 파일
└── requirements.txt      # 의존성
```

## 🛠️ 설치 및 실행

### 1. 의존성 설치
```bash
cd AI
pip install -r requirements.txt
```

### 2. 환경 변수 설정 (선택사항)
```bash
export HOST=0.0.0.0
export PORT=8080
export LLM_TYPE=gemini
export DEVICE=auto
export DEBUG=false
```

### 3. 서버 실행
```bash
# 기본 설정으로 실행
python main.py

# 커스텀 설정으로 실행
python main.py --host 127.0.0.1 --port 8080 --debug --llm-type gemini
```

## 📡 API 엔드포인트

### 기본 엔드포인트
- `GET /api/v1/health` - 서버 상태 확인
- `GET /api/v1/test` - 테스트 엔드포인트

### 음성 처리
- `POST /api/v1/process_voice` - 음성 명령 처리

### 일정 관리
- `POST /api/v1/schedule/add` - 일정 추가
- `GET /api/v1/schedule/list` - 일정 목록 조회
- `GET /api/v1/schedule/remind` - 일정 알림 조회

### 사용자 관리
- `GET /api/v1/memory/context` - 사용자 컨텍스트 조회
- `POST /api/v1/settings/update` - 설정 업데이트

### 고령자 특화
- `POST /api/v1/elderly/simple_response` - 간단 응답 생성
- `POST /api/v1/elderly/repeat_important` - 중요 메시지 반복

## 🔧 설정

### 환경 변수
- `HOST`: 서버 호스트 (기본값: 0.0.0.0)
- `PORT`: 서버 포트 (기본값: 8080)
- `DEBUG`: 디버그 모드 (기본값: false)
- `LLM_TYPE`: LLM 모델 타입 (기본값: gemini)
- `DEVICE`: AI 모델 디바이스 (기본값: auto)
- `STT_MODEL`: STT 모델 크기 (기본값: small)

### 고령자 특화 설정
- `SPEECH_RATE`: 음성 속도 (기본값: 0.8)
- `VOLUME_LEVEL`: 볼륨 레벨 (기본값: 1.2)
- `SIMPLE_RESPONSES`: 간단 응답 사용 (기본값: true)
- `REPEAT_IMPORTANT`: 중요 메시지 반복 (기본값: true)

## 📝 사용 예시

### 음성 명령 처리
```bash
curl -X POST http://localhost:8080/api/v1/process_voice \
  -F "audio=@voice_command.wav" \
  -F "user_id=user123"
```

### 일정 추가
```bash
curl -X POST http://localhost:8080/api/v1/schedule/add \
  -H "Content-Type: application/json" \
  -H "X-User-ID: user123" \
  -d '{
    "title": "병원 예약",
    "datetime": "2024-01-15 14:30",
    "category": "건강",
    "priority": "important"
  }'
```

### 서버 상태 확인
```bash
curl http://localhost:8080/api/v1/health
```

## 🔒 보안

- API 키 인증 (선택사항)
- 요청 크기 제한
- 파일 업로드 검증
- 속도 제한
- CORS 설정

## 📊 모니터링

- 상세한 로깅 (파일 + 콘솔)
- 요청/응답 시간 측정
- 에러 추적
- 메모리 사용량 모니터링

## 🐛 문제 해결

### 일반적인 문제들

1. **포트 충돌**
   ```bash
   python main.py --port 8080
   ```

2. **메모리 부족**
   ```bash
   export DEVICE=cpu
   python main.py
   ```

3. **음성 파일 오류**
   - 지원 형식: WAV, MP3, M4A, FLAC, OGG
   - 최대 크기: 10MB

## 🤝 기여

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

## 📞 지원

문제가 있거나 질문이 있으시면 이슈를 생성해주세요. 
## 🔐 Google Cloud 설정

### 1. Google Cloud 서비스 계정 키 설정

1. [Google Cloud Console](https://console.cloud.google.com/)에서 서비스 계정 키 생성
2. 다운로드한 JSON 파일을 `AI/google-credentials.json`으로 저장
3. 환경 변수 설정:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="AI/google-credentials.json"
   ```

### 2. Gemini API 키 설정

1. [Google AI Studio](https://makersuite.google.com/app/apikey)에서 API 키 생성
2. 환경 변수 설정:
   ```bash
   export GOOGLE_API_KEY="your_gemini_api_key"
   ```
