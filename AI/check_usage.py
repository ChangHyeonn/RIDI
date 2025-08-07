#!/usr/bin/env python3
"""
Google API 사용량 확인 스크립트
"""

import os
import requests
from dotenv import load_dotenv

load_dotenv()

def check_gemini_usage():
    """Gemini API 사용량 확인"""
    api_key = os.getenv('GOOGLE_API_KEY')
    if not api_key:
        print("❌ Google API 키가 설정되지 않았습니다.")
        return
    
    print("🔍 Gemini API 사용량 확인")
    print("=" * 40)
    
    # Google AI Studio API 사용량 확인
    url = "https://generativelanguage.googleapis.com/v1beta/models"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            print("✅ Gemini API 연결 성공")
            print("📊 사용 가능한 모델:")
            models = response.json().get('models', [])
            for model in models[:5]:  # 처음 5개만 표시
                print(f"  - {model.get('name', 'Unknown')}")
        else:
            print(f"❌ API 연결 실패: {response.status_code}")
            print(f"응답: {response.text}")
    except Exception as e:
        print(f"❌ 오류 발생: {e}")

def check_quota_info():
    """할당량 정보 확인"""
    print("\n📋 무료 할당량 정보")
    print("=" * 40)
    print("Gemini API (Generative AI):")
    print("  - 월 15회 요청 (무료)")
    print("  - 분당 60회 요청 (무료)")
    print("  - 입력 토큰: 분당 32,000개 (무료)")
    print("  - 출력 토큰: 분당 32,000개 (무료)")
    print("\nSpeech-to-Text API:")
    print("  - 월 60분 (무료)")
    print("  - 초과 시: $0.006/분")
    print("\nText-to-Speech API:")
    print("  - 월 4백만 자 (무료)")
    print("  - 초과 시: $4.00/백만 자")

def check_billing():
    """결제 정보 확인"""
    print("\n💰 결제 정보")
    print("=" * 40)
    print("프로젝트 ID: sacred-pipe-468303-p1")
    print("결제 계정 확인: https://console.cloud.google.com/billing")
    print("사용량 대시보드: https://console.cloud.google.com/apis/dashboard")

if __name__ == "__main__":
    check_gemini_usage()
    check_quota_info()
    check_billing()
    
    print("\n🌐 웹에서 확인하기:")
    print("1. Google Cloud Console: https://console.cloud.google.com/apis/dashboard")
    print("2. Google AI Studio: https://makersuite.google.com/app/apikey")
    print("3. 결제 대시보드: https://console.cloud.google.com/billing")
