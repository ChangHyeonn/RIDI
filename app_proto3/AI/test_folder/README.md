# 🎤 Voice Chat Pipeline Test

STT + LLM + TTS를 통합한 음성 대화 시스템 테스트

## 📁 파일 구조

```
test_folder/
├── voice_chat_pipeline.py    # 통합 음성 대화 파이프라인
├── voice_test.py             # 음성 녹음/재생 테스트
├── requirements.txt          # 필요한 패키지 목록
└── README.md                # 사용법 설명
```

## 🚀 설치 및 실행

### 1. 패키지 설치
```bash
pip install -r requirements.txt
```

### 2. 환경 변수 설정
```bash
# OpenAI API 키 (GPT 사용시)
export OPENAI_API_KEY="your-openai-api-key"

# Google API 키 (Gemini 사용시)
export GOOGLE_API_KEY="your-google-api-key"
```

### 3. 테스트 실행
```bash
# 기본 테스트 (파이프라인 정보만 출력)
python voice_chat_pipeline.py

# 음성 대화 테스트 (실제 녹음/재생)
python voice_test.py
```

## 🎯 기능

### **VoiceChatPipeline 클래스**
- **STT**: Whisper 모델로 음성 → 텍스트 변환
- **LLM**: GPT/Gemini로 자연어 응답 생성
- **TTS**: Google TTS로 텍스트 → 음성 변환

### **VoiceChatTest 클래스**
- **음성 녹음**: 5초간 음성 녹음
- **AI 대화**: 녹음된 음성으로 AI와 대화
- **음성 재생**: AI 응답을 음성으로 재생

## 📊 파이프라인 흐름

```
🎤 음성 입력 → 🔤 STT → 🤖 LLM → 🔊 TTS → 🎵 음성 출력
```

1. **음성 녹음** (5초)
2. **STT 처리** (Whisper)
3. **LLM 응답** (GPT/Gemini)
4. **TTS 변환** (Google TTS)
5. **음성 재생**

## ⚙️ 설정 옵션

### **LLM 모델 선택**
```python
# Gemini 사용 (무료)
pipeline = VoiceChatPipeline(llm_type="gemini")

# GPT 사용 (유료)
pipeline = VoiceChatPipeline(llm_type="gpt")
```

### **STT 모델 선택**
```python
# 작은 모델 (빠름, 정확도 낮음)
pipeline = VoiceChatPipeline(stt_model="tiny")

# 중간 모델 (균형)
pipeline = VoiceChatPipeline(stt_model="small")

# 큰 모델 (느림, 정확도 높음)
pipeline = VoiceChatPipeline(stt_model="base")
```

## 🎮 사용법

### **1. 기본 테스트**
```bash
python voice_chat_pipeline.py
```
- 파이프라인 정보 출력
- 모델 초기화 확인

### **2. 음성 대화 테스트**
```bash
python voice_test.py
```
1. LLM 모델 선택 (gpt/gemini)
2. 5초간 음성 녹음
3. AI 응답 텍스트 출력
4. AI 응답 음성 재생
5. 반복 (종료하려면 "종료" 말하기)

## 📈 성능 정보

### **처리 시간 (예상)**
- **STT**: 1-3초
- **LLM**: 2-5초
- **TTS**: 1-2초
- **총 시간**: 4-10초

### **모델 크기**
- **Whisper tiny**: 39MB
- **Whisper small**: 244MB
- **Whisper base**: 461MB

## 🔧 문제 해결

### **음성 녹음 오류**
```bash
# macOS
brew install portaudio

# Ubuntu
sudo apt-get install portaudio19-dev
```

### **API 키 오류**
```bash
# 환경 변수 확인
echo $OPENAI_API_KEY
echo $GOOGLE_API_KEY
```

### **메모리 부족**
```python
# 더 작은 STT 모델 사용
pipeline = VoiceChatPipeline(stt_model="tiny")
```

## 🎯 예시 대화

```
👤 사용자: "안녕하세요"
🤖 AI: "안녕하세요! 무엇을 도와드릴까요?"

👤 사용자: "오늘 날씨는 어때?"
🤖 AI: "죄송하지만 실시간 날씨 정보는 제공할 수 없습니다. 인터넷에서 확인해보시는 것을 추천드려요."

👤 사용자: "종료"
🤖 AI: "대화를 종료합니다. 좋은 하루 되세요!"
```

## 📝 주의사항

1. **API 키 필요**: GPT 또는 Gemini API 키가 필요합니다
2. **인터넷 연결**: TTS와 LLM에 인터넷 연결이 필요합니다
3. **마이크 권한**: 음성 녹음에 마이크 권한이 필요합니다
4. **음성 품질**: 조용한 환경에서 녹음하면 인식률이 높아집니다

## 🚀 다음 단계

1. **실시간 스트리밍**: 실시간 음성 처리
2. **음성 품질 개선**: 더 자연스러운 TTS
3. **다국어 지원**: 영어, 일본어 등 추가
4. **대화 기록**: 대화 히스토리 저장 