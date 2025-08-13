#!/usr/bin/env python3
"""
AI Server (Text-based)
고령층 일정 메모 관리 AI 서버 (텍스트 기반)
"""

import os
import sys
from flask import Flask
from flask_cors import CORS

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from Config.settings import Settings
from Server.middleware import setup_middleware
from Server.api_routes import setup_routes
from Server.services.ai_service import AIService

def create_app():
    """Flask 앱 생성"""
    app = Flask(__name__)
    app.config.from_object(Settings)
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
    """메인 함수"""
    print("🚀 AI Server 초기화 중...")
    app = create_app()
    
    print(f"🌐 서버 시작: {Settings.HOST}:{Settings.PORT}")
    print(f"🔧 디버그 모드: {Settings.DEBUG}")
    print(f"🤖 AI 모델: {Settings.LLM_TYPE}")
    print(f"💻 디바이스: {Settings.DEVICE}")
    print(f"📝 텍스트 기반 처리 모드")
    
    app.run(
        host=Settings.HOST,
        port=Settings.PORT,
        debug=Settings.DEBUG
    )

if __name__ == "__main__":
    main() 