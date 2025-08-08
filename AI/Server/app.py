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
    app = Flask(__name__)
    
    app.config.from_object(Settings)
    
    CORS(app, origins=Settings.ALLOWED_ORIGINS)
    
    setup_middleware(app)
    
    ai_service = AIService()
    app.ai_service = ai_service
    
    setup_routes(app)
    
    return app

def main():
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