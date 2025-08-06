#!/usr/bin/env python3
"""
Authentication Utilities
고령층 일정 메모 관리 AI 서버 인증 유틸리티
"""

import os
import time
import hashlib
import secrets
from functools import wraps
from flask import request, jsonify, current_app
from typing import Dict, Any, Optional
import logging

# 프로젝트 루트를 Python 경로에 추가
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../..'))

from Config.settings import Settings

logger = logging.getLogger(__name__)

class AuthManager:
    """인증 관리자"""
    
    def __init__(self):
        self.api_keys = {}  # 실제로는 데이터베이스에 저장
        self.sessions = {}  # 세션 관리
        self.rate_limits = {}  # 속도 제한
    
    def generate_api_key(self, user_id: str) -> str:
        """API 키 생성"""
        timestamp = str(int(time.time()))
        random_part = secrets.token_hex(16)
        user_part = hashlib.sha256(user_id.encode()).hexdigest()[:8]
        
        api_key = f"ridi_{user_part}_{random_part}_{timestamp}"
        self.api_keys[api_key] = {
            'user_id': user_id,
            'created_at': timestamp,
            'last_used': timestamp
        }
        

        return api_key
    
    def validate_api_key(self, api_key: str) -> Dict[str, Any]:
        """API 키 검증"""
        if not api_key:
            return {"valid": False, "error": "API 키가 제공되지 않았습니다"}
        
        if api_key not in self.api_keys:
            return {"valid": False, "error": "유효하지 않은 API 키입니다"}
        
        # 사용 시간 업데이트
        self.api_keys[api_key]['last_used'] = str(int(time.time()))
        
        return {
            "valid": True,
            "user_id": self.api_keys[api_key]['user_id']
        }
    
    def revoke_api_key(self, api_key: str) -> bool:
        """API 키 폐기"""
        if api_key in self.api_keys:
            del self.api_keys[api_key]
    
            return True
        return False
    
    def get_user_api_keys(self, user_id: str) -> list:
        """사용자의 API 키 목록"""
        user_keys = []
        for key, info in self.api_keys.items():
            if info['user_id'] == user_id:
                user_keys.append({
                    'key': key[:10] + "...",
                    'created_at': info['created_at'],
                    'last_used': info['last_used']
                })
        return user_keys

def require_auth(f):
    """인증 미들웨어 데코레이터"""
    def decorated_function(*args, **kwargs):
        from flask import request
        
        # API 키 검증
        if Settings.API_KEY:
            api_key = request.headers.get('X-API-Key')
            if not api_key or api_key != Settings.API_KEY:
                logger.warning(f"Invalid API key attempt from {request.remote_addr}")
                return {"error": "인증이 필요합니다"}, 401
        
        return f(*args, **kwargs)
    return decorated_function

def require_user_auth(f):
    """사용자 인증 미들웨어 데코레이터"""
    def decorated_function(*args, **kwargs):
        from flask import request
        
        # 사용자 ID 검증
        user_id = request.headers.get('X-User-ID')
        if not user_id:
            return {"error": "사용자 ID가 필요합니다"}, 401
        
        # 사용자 ID 형식 검증
        if len(user_id) < 3 or len(user_id) > 50:
            return {"error": "유효하지 않은 사용자 ID입니다"}, 400
        
        return f(*args, **kwargs)
    return decorated_function

def require_api_key(f):
    """API 키 인증 데코레이터"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        api_key = request.headers.get('X-API-Key')
        
        if not api_key:
            return jsonify({"error": "API 키가 필요합니다"}), 401
        
        # API 키 검증
        auth_manager = AuthManager()
        validation_result = auth_manager.validate_api_key(api_key)
        
        if not validation_result['valid']:
            return jsonify({"error": validation_result['error']}), 401
        
        return f(*args, **kwargs)
    return decorated_function

def check_rate_limit(user_id: str, max_requests: int = 100, window: int = 60) -> Dict[str, Any]:
    """속도 제한 확인"""
    current_time = time.time()
    
    if user_id not in auth_manager.rate_limits:
        auth_manager.rate_limits[user_id] = {
            'count': 0,
            'reset_time': current_time + window
        }
    
    # 시간 윈도우 확인
    if current_time > auth_manager.rate_limits[user_id]['reset_time']:
        auth_manager.rate_limits[user_id] = {
            'count': 0,
            'reset_time': current_time + window
        }
    
    # 요청 수 증가
    auth_manager.rate_limits[user_id]['count'] += 1
    
    # 제한 확인
    if auth_manager.rate_limits[user_id]['count'] > max_requests:
        return {
            "allowed": False,
            "error": "요청이 너무 많습니다. 잠시 후 다시 시도해주세요",
            "reset_time": auth_manager.rate_limits[user_id]['reset_time']
        }
    
    return {
        "allowed": True,
        "remaining": max_requests - auth_manager.rate_limits[user_id]['count']
    }

def create_session(user_id: str) -> str:
    """세션 생성"""
    session_id = secrets.token_hex(32)
    auth_manager.sessions[session_id] = {
        'user_id': user_id,
        'created_at': time.time(),
        'last_activity': time.time()
    }
    
    
    return session_id

def validate_session(session_id: str) -> Dict[str, Any]:
    """세션 검증"""
    if session_id not in auth_manager.sessions:
        return {"valid": False, "error": "유효하지 않은 세션입니다"}
    
    session = auth_manager.sessions[session_id]
    current_time = time.time()
    
    # 세션 만료 확인 (24시간)
    if current_time - session['created_at'] > 86400:
        del auth_manager.sessions[session_id]
        return {"valid": False, "error": "세션이 만료되었습니다"}
    
    # 마지막 활동 시간 업데이트
    session['last_activity'] = current_time
    
    return {
        "valid": True,
        "user_id": session['user_id']
    }

def revoke_session(session_id: str) -> bool:
    """세션 폐기"""
    if session_id in auth_manager.sessions:
        del auth_manager.sessions[session_id]

        return True
    return False

# 전역 인증 관리자 인스턴스
auth_manager = AuthManager() 