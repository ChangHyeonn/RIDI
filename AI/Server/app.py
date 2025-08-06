#!/usr/bin/env python3
"""
AI Server Main Application
고령층 일정 메모 관리 애플리케이션을 위한 AI 서버
"""

import os
import sys
from flask import Flask
from flask_cors import CORS

# 프로젝트 루트를 Python 경로에 추가
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from config.settings import Settings
from server.middleware import setup_middleware
from server.api_routes import setup_routes
from server.services.ai_service import AIService

def create_app():
    """Flask 애플리케이션 팩토리"""
    app = Flask(__name__)
    
    # 설정 적용
    app.config.from_object(Settings)
    
    # CORS 설정
    CORS(app, origins=Settings.ALLOWED_ORIGINS)
    
    # 미들웨어 설정
    setup_middleware(app)
    
    # AI 서비스 초기화
    ai_service = AIService()
    app.ai_service = ai_service
    
    # 라우트 설정
    setup_routes(app)
    
    return app

def main():
    """메인 실행 함수"""
    print("🚀 AI Server 초기화 중...")
    
    app = create_app()
    
    print(f"🌐 서버 시작: {Settings.HOST}:{Settings.PORT}")
    print(f"🔧 디버그 모드: {Settings.DEBUG}")
    print(f"🤖 AI 모델: {Settings.LLM_TYPE}")
    print(f"💻 디바이스: {Settings.DEVICE}")
    
    app.run(
        host=Settings.HOST,
        port=Settings.PORT,
        debug=Settings.DEBUG
    )

if __name__ == "__main__":
    main() 