#!/usr/bin/env python3
"""
Middleware for AI Server
고령층 일정 메모 관리 AI 서버 미들웨어
"""

import time
import logging
from flask import request, g, current_app
from functools import wraps
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from Config.settings import Settings

logger = logging.getLogger(__name__)

def setup_middleware(app):
    """미들웨어 설정"""
    
    @app.before_request
    def before_request():
        """요청 전 처리"""
        g.start_time = time.time()
        g.request_id = f"req_{int(time.time() * 1000)}"
        
        # 요청 정보 로깅 (에러만)
        
        # 요청 크기 검증
        content_length = request.content_length
        if content_length and content_length > Settings.MAX_REQUEST_SIZE:
            logger.warning(f"Request too large: {content_length} bytes")
            return {"error": "요청 크기가 너무 큽니다"}, 413
    
    @app.after_request
    def after_request(response):
        """요청 후 처리"""
        if hasattr(g, 'start_time'):
            duration = time.time() - g.start_time
            
            # 응답 시간이 오래 걸린 경우만 경고
            if duration > 5.0:
                logger.warning(f"Slow request: {g.request_id} took {duration:.3f}s")
        
        # CORS 헤더 추가
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-User-ID'
        
        return response
    
    @app.errorhandler(404)
    def not_found(error):
        """404 에러 처리"""
        logger.warning(f"404 error: {request.path}")
        return {"error": "요청한 엔드포인트를 찾을 수 없습니다", "path": request.path}, 404
    
    @app.errorhandler(405)
    def method_not_allowed(error):
        """405 에러 처리"""
        logger.warning(f"405 error: {request.method} {request.path}")
        return {"error": "허용되지 않는 HTTP 메서드입니다", "method": request.method}, 405
    
    @app.errorhandler(413)
    def request_entity_too_large(error):
        """413 에러 처리"""
        logger.warning(f"413 error: Request too large")
        return {"error": "요청 크기가 너무 큽니다"}, 413
    
    @app.errorhandler(500)
    def internal_error(error):
        """500 에러 처리"""
        logger.error(f"500 error: {error}")
        return {"error": "서버 내부 오류가 발생했습니다"}, 500
    
    @app.errorhandler(Exception)
    def handle_exception(error):
        """일반 예외 처리"""
        logger.error(f"Unhandled exception: {error}")
        return {"error": "예상치 못한 오류가 발생했습니다"}, 500

def require_auth(f):
    """인증 미들웨어"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # API 키 검증
        if Settings.API_KEY:
            api_key = request.headers.get('X-API-Key')
            if not api_key or api_key != Settings.API_KEY:
                logger.warning(f"Invalid API key attempt from {request.remote_addr}")
                return {"error": "인증이 필요합니다"}, 401
        
        return f(*args, **kwargs)
    return decorated_function

def rate_limit(max_requests=100, window=60):
    """속도 제한 미들웨어"""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            # 간단한 속도 제한 구현
            # 실제로는 Redis 등을 사용해야 함
            client_ip = request.remote_addr
            current_time = time.time()
            
            # 요청 카운트 확인 (간단한 구현)
            if not hasattr(current_app, 'request_counts'):
                current_app.request_counts = {}
            
            if client_ip not in current_app.request_counts:
                current_app.request_counts[client_ip] = {'count': 0, 'reset_time': current_time + window}
            
            # 시간 윈도우 확인
            if current_time > current_app.request_counts[client_ip]['reset_time']:
                current_app.request_counts[client_ip] = {'count': 0, 'reset_time': current_time + window}
            
            # 요청 수 증가
            current_app.request_counts[client_ip]['count'] += 1
            
            # 제한 확인
            if current_app.request_counts[client_ip]['count'] > max_requests:
                logger.warning(f"Rate limit exceeded for {client_ip}")
                return {"error": "요청이 너무 많습니다. 잠시 후 다시 시도해주세요"}, 429
            
            return f(*args, **kwargs)
        return decorated_function
    return decorator

def log_request_details(f):
    """요청 상세 정보 로깅 미들웨어"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        logger.info(f"Request details: {request.method} {request.path}")
        logger.info(f"Headers: {dict(request.headers)}")
        logger.info(f"Args: {dict(request.args)}")
        
        if request.is_json:
            logger.info(f"JSON data: {request.get_json()}")
        
        return f(*args, **kwargs)
    return decorated_function

def validate_content_type(content_type):
    """Content-Type 검증 미들웨어"""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if request.content_type and content_type not in request.content_type:
                logger.warning(f"Invalid content type: {request.content_type}")
                return {"error": f"지원하지 않는 Content-Type입니다. {content_type}이 필요합니다"}, 400
            return f(*args, **kwargs)
        return decorated_function
    return decorator 