#!/usr/bin/env python3
"""
Input Validation Utilities
고령층 일정 메모 관리 AI 서버 입력 검증 유틸리티
"""

import os
import re
from datetime import datetime
from werkzeug.utils import secure_filename

import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from Config.settings import Settings
from typing import Dict, Any, Tuple

def validate_audio_file(file) -> Dict[str, Any]:
    """오디오 파일 검증"""
    if not file:
        return {"valid": False, "error": "파일이 제공되지 않았습니다"}
    
    # 파일명 검증
    filename = secure_filename(file.filename)
    if not filename:
        return {"valid": False, "error": "유효하지 않은 파일명입니다"}
    
    # 파일 크기 검증
    file.seek(0, os.SEEK_END)
    file_size = file.tell()
    file.seek(0)
    
    if file_size > Settings.MAX_AUDIO_SIZE:
        return {
            "valid": False, 
            "error": f"파일 크기가 너무 큽니다. 최대 {Settings.MAX_AUDIO_SIZE // (1024*1024)}MB까지 허용됩니다"
        }
    
    if file_size == 0:
        return {"valid": False, "error": "빈 파일입니다"}
    
    # 파일 확장자 검증
    file_ext = os.path.splitext(filename)[1].lower()
    if file_ext not in Settings.ALLOWED_AUDIO_EXTENSIONS:
        return {
            "valid": False, 
            "error": f"지원하지 않는 파일 형식입니다. 지원 형식: {', '.join(Settings.ALLOWED_AUDIO_EXTENSIONS)}"
        }
    
    return {"valid": True, "filename": filename, "size": file_size}

def validate_schedule_data(data: Dict[str, Any]) -> Dict[str, Any]:
    """일정 데이터 검증"""
    if not isinstance(data, dict):
        return {"valid": False, "error": "일정 데이터가 올바른 형식이 아닙니다"}
    
    # 필수 필드 검증
    required_fields = ['title', 'datetime']
    for field in required_fields:
        if field not in data or not data[field]:
            return {"valid": False, "error": f"필수 필드가 누락되었습니다: {field}"}
    
    # 제목 검증
    title = data['title'].strip()
    if len(title) < 2:
        return {"valid": False, "error": "일정 제목은 2자 이상이어야 합니다"}
    
    if len(title) > 100:
        return {"valid": False, "error": "일정 제목은 100자 이하여야 합니다"}
    
    # 날짜/시간 검증
    datetime_str = data['datetime']
    if not validate_datetime_format(datetime_str):
        return {"valid": False, "error": "날짜/시간 형식이 올바르지 않습니다 (YYYY-MM-DD HH:MM)"}
    
    # 카테고리 검증
    if 'category' in data:
        valid_categories = ['건강', '경조사', '일반']
        if data['category'] not in valid_categories:
            return {"valid": False, "error": f"유효하지 않은 카테고리입니다. 허용: {', '.join(valid_categories)}"}
    
    # 중요도 검증
    if 'priority' in data:
        valid_priorities = ['important', 'not_important']
        if data['priority'] not in valid_priorities:
            return {"valid": False, "error": f"유효하지 않은 중요도입니다. 허용: {', '.join(valid_priorities)}"}
    
    # 설명 검증
    if 'description' in data:
        description = data['description']
        if len(description) > 500:
            return {"valid": False, "error": "설명은 500자 이하여야 합니다"}
    
    return {"valid": True}

def validate_datetime_format(datetime_str: str) -> bool:
    """날짜/시간 형식 검증"""
    try:
        # ISO 형식 검증 (YYYY-MM-DD HH:MM)
        datetime.fromisoformat(datetime_str)
        return True
    except ValueError:
        return False

def validate_user_id(user_id: str) -> Dict[str, Any]:
    """사용자 ID 검증"""
    if not user_id:
        return {"valid": False, "error": "사용자 ID가 제공되지 않았습니다"}
    
    if len(user_id) < 3:
        return {"valid": False, "error": "사용자 ID는 3자 이상이어야 합니다"}
    
    if len(user_id) > 50:
        return {"valid": False, "error": "사용자 ID는 50자 이하여야 합니다"}
    
    # 특수문자 제한
    if not re.match(r'^[a-zA-Z0-9_-]+$', user_id):
        return {"valid": False, "error": "사용자 ID는 영문, 숫자, 언더스코어, 하이픈만 허용됩니다"}
    
    return {"valid": True}

def validate_api_key(api_key: str) -> Dict[str, Any]:
    """API 키 검증"""
    if not api_key:
        return {"valid": False, "error": "API 키가 제공되지 않았습니다"}
    
    if len(api_key) < 10:
        return {"valid": False, "error": "API 키가 너무 짧습니다"}
    
    return {"valid": True}

def validate_request_size(content_length: int) -> Dict[str, Any]:
    """요청 크기 검증"""
    if content_length and content_length > Settings.MAX_REQUEST_SIZE:
        return {
            "valid": False, 
            "error": f"요청 크기가 너무 큽니다. 최대 {Settings.MAX_REQUEST_SIZE // (1024*1024)}MB까지 허용됩니다"
        }
    
    return {"valid": True}

def validate_content_type(content_type: str, expected_type: str) -> Dict[str, Any]:
    """Content-Type 검증"""
    if not content_type:
        return {"valid": False, "error": "Content-Type이 제공되지 않았습니다"}
    
    if expected_type not in content_type:
        return {"valid": False, "error": f"지원하지 않는 Content-Type입니다. {expected_type}이 필요합니다"}
    
    return {"valid": True}

def sanitize_text(text: str, max_length: int = 1000) -> str:
    """텍스트 정리"""
    if not text:
        return ""
    
    # 길이 제한
    if len(text) > max_length:
        text = text[:max_length]
    
    # HTML 태그 제거
    text = re.sub(r'<[^>]+>', '', text)
    
    # 특수문자 정리
    text = text.strip()
    
    return text

def validate_elderly_settings(settings: Dict[str, Any]) -> Dict[str, Any]:
    """고령자 설정 검증"""
    if not isinstance(settings, dict):
        return {"valid": False, "error": "설정이 올바른 형식이 아닙니다"}
    
    # 음성 속도 검증
    if 'speech_rate' in settings:
        speech_rate = settings['speech_rate']
        if not isinstance(speech_rate, (int, float)) or speech_rate < 0.5 or speech_rate > 2.0:
            return {"valid": False, "error": "음성 속도는 0.5에서 2.0 사이여야 합니다"}
    
    # 볼륨 레벨 검증
    if 'volume_level' in settings:
        volume_level = settings['volume_level']
        if not isinstance(volume_level, (int, float)) or volume_level < 0.5 or volume_level > 3.0:
            return {"valid": False, "error": "볼륨 레벨은 0.5에서 3.0 사이여야 합니다"}
    
    # 간단 응답 설정 검증
    if 'simple_responses' in settings:
        if not isinstance(settings['simple_responses'], bool):
            return {"valid": False, "error": "간단 응답 설정은 boolean 값이어야 합니다"}
    
    return {"valid": True} 