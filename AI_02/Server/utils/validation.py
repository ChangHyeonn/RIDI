#!/usr/bin/env python3
"""
Validation Utilities (Text-based)
검증 유틸리티 (텍스트 기반)
"""

import re
from typing import Dict, Any, List
from datetime import datetime

def validate_text_input(text: str) -> Dict[str, Any]:
    """텍스트 입력 검증"""
    if not text:
        return {"valid": False, "error": "텍스트가 비어있습니다."}
    
    if not isinstance(text, str):
        return {"valid": False, "error": "텍스트는 문자열이어야 합니다."}
    
    # 텍스트 길이 검증 (너무 짧거나 긴 경우)
    if len(text.strip()) < 1:
        return {"valid": False, "error": "텍스트가 너무 짧습니다."}
    
    if len(text) > 1000:
        return {"valid": False, "error": "텍스트가 너무 깁니다. (최대 1000자)"}
    
    # 특수 문자나 위험한 패턴 검증
    dangerous_patterns = [
        r'<script.*?>.*?</script>',  # XSS 방지
        r'javascript:',  # JavaScript 인젝션 방지
        r'data:text/html',  # HTML 인젝션 방지
    ]
    
    for pattern in dangerous_patterns:
        if re.search(pattern, text, re.IGNORECASE):
            return {"valid": False, "error": "허용되지 않는 텍스트 패턴이 포함되어 있습니다."}
    
    return {"valid": True}

def validate_schedule_data(data: Dict[str, Any]) -> Dict[str, Any]:
    """일정 데이터 검증"""
    if not data:
        return {"valid": False, "error": "일정 데이터가 없습니다."}
    
    # 필수 필드 검증
    required_fields = ['title', 'datetime']
    for field in required_fields:
        if field not in data or not data[field]:
            return {"valid": False, "error": f"필수 필드가 누락되었습니다: {field}"}
    
    # 제목 길이 검증
    title = data['title']
    if len(title.strip()) < 1:
        return {"valid": False, "error": "일정 제목이 비어있습니다."}
    
    if len(title) > 100:
        return {"valid": False, "error": "일정 제목이 너무 깁니다. (최대 100자)"}
    
    # 날짜/시간 형식 검증
    datetime_str = data['datetime']
    try:
        # ISO 형식 또는 일반적인 날짜 형식 검증
        datetime.fromisoformat(datetime_str.replace('Z', '+00:00'))
    except ValueError:
        try:
            # 다른 일반적인 형식들 시도
            datetime.strptime(datetime_str, '%Y-%m-%d %H:%M:%S')
        except ValueError:
            try:
                datetime.strptime(datetime_str, '%Y-%m-%d')
            except ValueError:
                return {"valid": False, "error": "올바르지 않은 날짜/시간 형식입니다."}
    
    # 설명 필드 검증 (선택사항)
    if 'description' in data and data['description']:
        description = data['description']
        if len(description) > 500:
            return {"valid": False, "error": "일정 설명이 너무 깁니다. (최대 500자)"}
    
    return {"valid": True}

def validate_accessibility_settings(settings: Dict[str, Any]) -> Dict[str, Any]:
    """접근성 설정 검증"""
    if not settings:
        return {"valid": False, "error": "접근성 설정 데이터가 없습니다."}
    
    # 허용된 설정 키들
    allowed_keys = [
        'font_size', 'contrast_ratio', 'speech_rate', 
        'volume_level', 'high_contrast', 'large_text',
        'screen_reader', 'keyboard_navigation'
    ]
    
    # 알 수 없는 키 검증
    for key in settings.keys():
        if key not in allowed_keys:
            return {"valid": False, "error": f"알 수 없는 설정 키입니다: {key}"}
    
    # font_size 검증
    if 'font_size' in settings:
        font_size = settings['font_size']
        if not isinstance(font_size, (int, float)) or font_size < 8 or font_size > 72:
            return {"valid": False, "error": "폰트 크기는 8-72 사이의 숫자여야 합니다."}
    
    # contrast_ratio 검증
    if 'contrast_ratio' in settings:
        contrast_ratio = settings['contrast_ratio']
        if not isinstance(contrast_ratio, (int, float)) or contrast_ratio < 1 or contrast_ratio > 21:
            return {"valid": False, "error": "대비 비율은 1-21 사이의 숫자여야 합니다."}
    
    # speech_rate 검증
    if 'speech_rate' in settings:
        speech_rate = settings['speech_rate']
        if not isinstance(speech_rate, (int, float)) or speech_rate < 0.1 or speech_rate > 2.0:
            return {"valid": False, "error": "음성 속도는 0.1-2.0 사이의 숫자여야 합니다."}
    
    # volume_level 검증
    if 'volume_level' in settings:
        volume_level = settings['volume_level']
        if not isinstance(volume_level, (int, float)) or volume_level < 0 or volume_level > 1:
            return {"valid": False, "error": "볼륨 레벨은 0-1 사이의 숫자여야 합니다."}
    
    # boolean 값 검증
    boolean_keys = ['high_contrast', 'large_text', 'screen_reader', 'keyboard_navigation']
    for key in boolean_keys:
        if key in settings:
            if not isinstance(settings[key], bool):
                return {"valid": False, "error": f"{key}는 boolean 값이어야 합니다."}
    
    return {"valid": True}

def validate_user_id(user_id: str) -> Dict[str, Any]:
    """사용자 ID 검증"""
    if not user_id:
        return {"valid": False, "error": "사용자 ID가 없습니다."}
    
    if not isinstance(user_id, str):
        return {"valid": False, "error": "사용자 ID는 문자열이어야 합니다."}
    
    if len(user_id.strip()) < 1:
        return {"valid": False, "error": "사용자 ID가 비어있습니다."}
    
    if len(user_id) > 50:
        return {"valid": False, "error": "사용자 ID가 너무 깁니다. (최대 50자)"}
    
    # 특수 문자 검증
    if re.search(r'[<>"\']', user_id):
        return {"valid": False, "error": "사용자 ID에 허용되지 않는 문자가 포함되어 있습니다."}
    
    return {"valid": True}

def validate_date_range(start_date: str, end_date: str) -> Dict[str, Any]:
    """날짜 범위 검증"""
    try:
        start = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
        end = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
        
        if start > end:
            return {"valid": False, "error": "시작 날짜가 종료 날짜보다 늦습니다."}
        
        # 날짜 범위가 너무 긴 경우 (예: 1년 이상)
        if (end - start).days > 365:
            return {"valid": False, "error": "날짜 범위가 너무 깁니다. (최대 1년)"}
        
        return {"valid": True}
        
    except ValueError:
        return {"valid": False, "error": "올바르지 않은 날짜 형식입니다."} 