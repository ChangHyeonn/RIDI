#!/usr/bin/env python3
"""
Request Logging Middleware
외부 연결 로깅 미들웨어
"""

import time
from datetime import datetime
from flask import request, g

from shared.logging.logger import LoggerFactory


class RequestLoggingMiddleware:
    """외부 연결 로깅 미들웨어"""
    
    def __init__(self, app=None):
        self.logger = LoggerFactory.get_logger(__name__)
        if app is not None:
            self.init_app(app)
    
    def init_app(self, app):
        """Flask 앱에 미들웨어 등록"""
        app.before_request(self.before_request)
        app.after_request(self.after_request)
    
    def before_request(self):
        """요청 시작 시 로깅"""
        g.start_time = time.time()
        
        # 클라이언트 정보 수집
        client_ip = self.get_client_ip()
        user_agent = request.headers.get('User-Agent', 'Unknown')
        
        # 요청 정보 로깅
        self.logger.info(
            f"🌐 외부 연결: {client_ip} → {request.method} {request.path}"
        )
        
        # 상세 정보 로깅 (디버그 모드에서만)
        if self.logger.isEnabledFor(10):  # DEBUG 레벨
            self.logger.debug(
                f"📱 클라이언트 정보: {client_ip} | {user_agent[:50]}..."
            )
    
    def after_request(self, response):
        """요청 완료 시 로깅"""
        if hasattr(g, 'start_time'):
            processing_time = time.time() - g.start_time
            client_ip = self.get_client_ip()
            
            # 응답 상태에 따른 로그 레벨 결정
            if response.status_code >= 500:
                log_level = "error"
                emoji = "💥"
            elif response.status_code >= 400:
                log_level = "warning"
                emoji = "⚠️"
            else:
                log_level = "info"
                emoji = "✅"
            
            # 응답 로깅
            log_message = (
                f"{emoji} 응답 완료: {client_ip} ← "
                f"{response.status_code} ({processing_time:.3f}s)"
            )
            
            getattr(self.logger, log_level)(log_message)
            
            # 느린 요청 경고
            if processing_time > 5.0:
                self.logger.warning(
                    f"🐌 느린 요청 감지: {request.path} took {processing_time:.3f}s"
                )
        
        return response
    
    def get_client_ip(self):
        """클라이언트 IP 주소 가져오기"""
        # 프록시 뒤에 있는 경우를 고려
        if request.headers.getlist("X-Forwarded-For"):
            return request.headers.getlist("X-Forwarded-For")[0]
        elif request.headers.get("X-Real-IP"):
            return request.headers.get("X-Real-IP")
        else:
            return request.remote_addr or "Unknown"
