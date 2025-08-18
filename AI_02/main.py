import os
import sys
import argparse
from pathlib import Path

# 프로젝트 루트를 Python 경로에 추가
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

from Config.settings import Settings
from Server.app import create_app

def main():
    """메인 실행 함수"""
    parser = argparse.ArgumentParser(description='AI Server for Text-based Processing')
    parser.add_argument('--host', default=Settings.HOST, help='Server host (default: 0.0.0.0)')
    parser.add_argument('--port', type=int, default=Settings.PORT, help='Server port (default: 8080)')
    parser.add_argument('--debug', action='store_true', help='Enable debug mode')
    parser.add_argument('--device', default=Settings.DEVICE, help='Device for AI models (auto/cpu/cuda)')
    parser.add_argument('--llm-type', default=Settings.LLM_TYPE, help='LLM type (openai)')
    
    args = parser.parse_args()
    
    # 환경 변수 설정
    os.environ['AI_SERVER_HOST'] = args.host
    os.environ['AI_SERVER_PORT'] = str(args.port)
    os.environ['AI_SERVER_DEBUG'] = str(args.debug).lower()
    os.environ['DEVICE'] = args.device
    os.environ['LLM_TYPE'] = args.llm_type
    
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
        print(f"💻 디바이스: {args.device}")
        print(f"📝 텍스트 기반 처리 모드")
        
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
        sys.exit(1)

if __name__ == "__main__":
    main()