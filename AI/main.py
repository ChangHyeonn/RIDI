#!/usr/bin/env python3
"""
AI Server Main Entry Point
고령층 일정 메모 관리 AI 서버 메인 실행 파일
"""

import os
import sys
import argparse
from pathlib import Path

# 프로젝트 루트를 Python 경로에 추가
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

from Config.logging_config import setup_logging
from Config.settings import Settings
from Server.app import create_app

def main():
    """메인 실행 함수"""
    parser = argparse.ArgumentParser(description='AI Server for Elderly Schedule Management')
    parser.add_argument('--host', default=Settings.HOST, help='Server host (default: 0.0.0.0)')
    parser.add_argument('--port', type=int, default=Settings.PORT, help='Server port (default: 5000)')
    parser.add_argument('--debug', action='store_true', help='Enable debug mode')
    parser.add_argument('--device', default=Settings.DEVICE, help='Device for AI models (auto/cpu/cuda)')
    parser.add_argument('--llm-type', default=Settings.LLM_TYPE, help='LLM type (gemini)')
    parser.add_argument('--stt-model', default=Settings.STT_MODEL, help='STT model Gemini/Google')
    
    args = parser.parse_args()
    
    # 환경 변수 설정
    os.environ['HOST'] = args.host
    os.environ['PORT'] = str(args.port)
    os.environ['DEBUG'] = str(args.debug).lower()
    os.environ['DEVICE'] = args.device
    os.environ['LLM_TYPE'] = args.llm_type
    os.environ['STT_MODEL'] = args.stt_model
    
    # 로깅 설정
    logger = setup_logging()
    
    try:
        # 설정 유효성 검사
        errors = Settings.validate_settings()
        if errors:
            print("❌ 설정 오류:")
            for error in errors:
                print(f"  - {error}")
            sys.exit(1)
        
        # 서버 시작
        print("🚀 AI Server 초기화 중...")
        print(f"📍 서버 주소: {args.host}:{args.port}")
        print(f"🔧 디버그 모드: {args.debug}")
        print(f"🤖 AI 모델: {args.llm_type}")
        print(f"🎤 STT 모델: {args.stt_model}")
        print(f"💻 디바이스: {args.device}")
        print(f"👴 고령자 설정: 음성속도={Settings.SPEECH_RATE}, 볼륨={Settings.VOLUME_LEVEL}")
        
        # Flask 앱 생성
        app = create_app()
        
        # 서버 실행
        app.run(
            host=args.host,
            port=args.port,
            debug=args.debug
        )
        
    except KeyboardInterrupt:
        print("\n🛑 서버가 중단되었습니다.")
        sys.exit(0)
    except Exception as e:
        print(f"❌ 서버 시작 실패: {e}")
        logger.error(f"Server startup failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()