#!/usr/bin/env python3
"""
Main Application Entry Point (Clean Architecture)
Clean Architecture 기반 메인 애플리케이션 진입점
"""

import sys
import argparse
import socket
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
    
    # 외부 접근용 IP 주소 가져오기
    def get_local_ip():
        """로컬 네트워크 IP 주소 가져오기"""
        try:
            # 임시 소켓을 만들어서 로컬 IP 확인
            with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
                s.connect(("8.8.8.8", 80))
                local_ip = s.getsockname()[0]
            return local_ip
        except Exception:
            return "localhost"
    
    def analyze_network_type(ip):
        """네트워크 타입 분석"""
        if ip.startswith('172.20.'):
            return "📱 개인용 핫스팟/모바일 테더링", "⚠️ 모바일 데이터 사용 시 IP가 자주 변경됩니다"
        elif ip.startswith('192.168.'):
            return "🏠 가정용 WiFi 라우터", "💡 라우터 설정에서 고정 IP 할당 가능"
        elif ip.startswith('10.'):
            return "🏢 기업/대형 네트워크", "🔧 네트워크 관리자에게 고정 IP 요청"
        elif ip.startswith('172.'):
            return "🏢 기업용 네트워크", "🔧 네트워크 관리자에게 고정 IP 요청"
        else:
            return "🌐 기타 네트워크", "📞 네트워크 관리자에게 문의"
    
    local_ip = get_local_ip()
    network_type, ip_tip = analyze_network_type(local_ip)
    
    # 시작 메시지
    print("🚀 AI Text Processing Server (Clean Architecture)")
    print("=" * 60)
    print(f"📍 Host: {settings.server.host}")
    print(f"📍 Port: {settings.server.port}")
    print(f"🔧 Debug: {settings.server.debug}")
    print(f"🗄️ Database: {settings.database.engine}")
    print(f"🤖 LLM Provider: {settings.llm.provider}")
    print("=" * 60)
    print("🌐 서버 접속 주소:")
    print(f"   📡 현재 IP: {local_ip} ({network_type})")
    print(f"   {ip_tip}")
    print()
    
    # 다양한 접속 주소 표시
    if settings.server.host == "0.0.0.0":
        print(f"   📱 로컬 접속:     http://localhost:{settings.server.port}")
        print(f"   🌍 외부 접속:     http://{local_ip}:{settings.server.port}")
        print(f"   📡 API 엔드포인트:")
        print(f"      - 헬스체크:    http://{local_ip}:{settings.server.port}/api/v1/health")
        print(f"      - 텍스트 처리:  http://{local_ip}:{settings.server.port}/api/v1/process_text")
    else:
        print(f"   🌐 서버 주소:     http://{settings.server.host}:{settings.server.port}")
        print(f"   📡 API 엔드포인트:")
        print(f"      - 헬스체크:    http://{settings.server.host}:{settings.server.port}/api/v1/health")
        print(f"      - 텍스트 처리:  http://{settings.server.host}:{settings.server.port}/api/v1/process_text")
    
    # IP 변경 방지 팁
    print()
    print("🔧 IP 주소 고정 방법:")
    if local_ip.startswith('172.20.'):
        print("   1️⃣ WiFi 네트워크 사용 (더 안정적)")
        print("   2️⃣ 라우터 설정에서 DHCP 예약")
        print("   3️⃣ 서버 실행 시 --host 옵션으로 특정 IP 지정")
    elif local_ip.startswith('192.168.'):
        print("   1️⃣ 라우터 관리 페이지 → DHCP 설정 → IP 예약")
        print("   2️⃣ MAC 주소 기반 고정 IP 할당")
        print("   3️⃣ 정적 IP 설정 (시스템 네트워크 설정)")
    
    print("=" * 60)
    
    logger.info("Starting AI Text Processing Server")
    logger.info(f"Configuration: {settings.to_dict()}")
    
    try:
        # Flask 앱 생성
        app = create_app(settings)
        
        # 서버 실행
        print("🚀 서버를 시작합니다...")
        if settings.server.host == "0.0.0.0":
            print(f"📶 Flutter 앱에서 사용할 주소: http://{local_ip}:{settings.server.port}")
        
        logger.info(f"Server starting on {settings.server.host}:{settings.server.port}")
        logger.info(f"External access available at: http://{local_ip}:{settings.server.port}")
        
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
