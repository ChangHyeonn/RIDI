#!/usr/bin/env python3
"""
.env 파일을 사용한 API 키 설정 예시
"""

import os
from dotenv import load_dotenv

# .env 파일 로드
load_dotenv()

# API 키 가져오기
google_api_key = os.getenv('GOOGLE_API_KEY')
openai_api_key = os.getenv('OPENAI_API_KEY')

print("🔑 API 키 설정 확인:")
print(f"Google API Key: {'설정됨' if google_api_key else '설정되지 않음'}")
print(f"OpenAI API Key: {'설정됨' if openai_api_key else '설정되지 않음'}")

# LLM 모델 선택
llm_model = os.getenv('LLM_MODEL', 'gemini')
print(f"선택된 LLM 모델: {llm_model}")

if google_api_key:
    print("✅ Gemini API 키가 설정되어 있습니다!")
else:
    print("❌ Gemini API 키를 설정해주세요.")
    print("AI/.env 파일에서 GOOGLE_API_KEY=your-actual-api-key로 수정하세요.") 