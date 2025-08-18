#!/usr/bin/env python3
"""
Main Application Entry Point (Clean Architecture)
Clean Architecture 기반 메인 애플리케이션 진입점
"""

import sys
import argparse
from pathlib import Path

# 프로젝트 루트를 Python 경로에 추가
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

from shared.config.settings import AppSettings
from shared.logging.logger import LoggerFactory
from presentation.app_factory import create_app


def main():
    """메인 함수"""
    # 명령행 인자 파싱
    parser = argparse.ArgumentParser(description='AI Text Processing Server (Clean Architecture)')
    parser.add_argument('--host', default=None, help='Server host')
    parser.add_argument('--port', type=int, default=None, help='Server port')
    parser.add_argument('--debug', action='store_true', help='Enable debug mode')
    parser.add_argument('--db-engine', choices=['memory', 'mongodb'], help='Database engine')
    
    args = parser.parse_args()
    
    # 설정 로드
    settings = AppSettings()
    
    # 명령행 인자로 설정 오버라이드
    if args.host:
        settings.server.host = args.host
    if args.port:
        settings.server.port = args.port
    if args.debug:
        settings.server.debug = True
    if args.db_engine:
        settings.database.engine = args.db_engine
    
    # 설정 유효성 검증
    validation_errors = settings.validate()
    if validation_errors:
        print("❌ 설정 오류:")
        for error in validation_errors:
            print(f"  - {error}")
        sys.exit(1)
    
    # 로깅 초기화
    LoggerFactory.setup_logging(
        level=10 if settings.server.debug else 20,  # DEBUG : INFO
        log_to_file=True
    )
    
    logger = LoggerFactory.get_logger(__name__)
    
    # 시작 메시지
    print("🚀 AI Text Processing Server (Clean Architecture)")
    print("=" * 50)
    print(f"📍 Host: {settings.server.host}")
    print(f"📍 Port: {settings.server.port}")
    print(f"🔧 Debug: {settings.server.debug}")
    print(f"🗄️ Database: {settings.database.engine}")
    print(f"🤖 LLM Provider: {settings.llm.provider}")
    print("=" * 50)
    
    logger.info("Starting AI Text Processing Server")
    logger.info(f"Configuration: {settings.to_dict()}")
    
    try:
        # Flask 앱 생성
        app = create_app(settings)
        
        # 서버 실행
        logger.info(f"Server starting on {settings.server.host}:{settings.server.port}")
        app.run(
            host=settings.server.host,
            port=settings.server.port,
            debug=settings.server.debug,
            threaded=True
        )
        
    except KeyboardInterrupt:
        logger.info("Server stopped by user")
        print("\n👋 서버가 종료되었습니다.")
    except Exception as e:
        logger.error(f"Server startup failed: {e}")
        print(f"❌ 서버 시작 실패: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
