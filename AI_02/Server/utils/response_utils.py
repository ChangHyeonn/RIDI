#!/usr/bin/env python3
"""
Response Utilities (Text-based)
응답 유틸리티 (텍스트 기반)
"""

import json
from flask import jsonify
from datetime import datetime
from typing import Dict, Any, List, Optional

def create_response(data: Dict[str, Any], status_code: int = 200, error_code: Optional[str] = None) -> tuple:
    """기본 응답 생성"""
    response = {
        "success": True,
        "data": data,
        "timestamp": datetime.now().isoformat()
    }
    
    if error_code:
        response["error_code"] = error_code
    
    return jsonify(response), status_code

def create_schedule_response(success: bool, data: Dict[str, Any], message: str = "") -> Dict[str, Any]:
    """일정 관련 응답 생성"""
    response = {
        "success": success,
        "timestamp": datetime.now().isoformat(),
        "type": "schedule"
    }
    
    if success:
        response.update({
            "message": message or "일정 처리가 완료되었습니다",
            "data": data
        })
    else:
        response.update({
            "error": data.get("error", "일정 처리 중 오류가 발생했습니다"),
            "details": data
        })
    
    return response

def create_accessibility_response(success: bool, data: Dict[str, Any], message: str = "") -> Dict[str, Any]:
    """접근성 설정 응답 생성"""
    response = {
        "success": success,
        "timestamp": datetime.now().isoformat(),
        "type": "accessibility"
    }
    
    if success:
        response.update({
            "message": message or "접근성 설정이 업데이트되었습니다",
            "settings": data
        })
    else:
        response.update({
            "error": data.get("error", "접근성 설정 처리 중 오류가 발생했습니다"),
            "details": data
        })
    
    return response

def create_important_schedule_response(schedules: List[Dict[str, Any]], count: int) -> Dict[str, Any]:
    """중요 일정 응답 생성"""
    return {
        "success": True,
        "timestamp": datetime.now().isoformat(),
        "type": "important_schedules",
        "message": f"중요 일정 {count}개를 찾았습니다",
        "schedules": schedules,
        "count": count
    }

def create_schedule_list_response(schedules: List[Dict[str, Any]], date: str, count: int) -> Dict[str, Any]:
    """일정 목록 응답 생성"""
    return {
        "success": True,
        "timestamp": datetime.now().isoformat(),
        "type": "schedule_list",
        "message": f"{date}의 일정 {count}개를 찾았습니다",
        "schedules": schedules,
        "date": date,
        "count": count
    }

def create_command_classification_response(classification: Dict[str, Any], text: str) -> Dict[str, Any]:
    """명령 분류 응답 생성"""
    return {
        "success": True,
        "timestamp": datetime.now().isoformat(),
        "type": "command_classification",
        "original_text": text,
        "classification": classification,
        "confidence": classification.get("confidence", 0.0),
        "command_type": classification.get("type", "unknown")
    }

def create_text_processing_response(text_result: Dict[str, Any]) -> tuple:
    """텍스트 처리 응답 생성"""
    response = {
        "success": True,
        "text_response": {
            "text": text_result.get('text', ''),
            "response_text": text_result.get('response_text', ''),
            "display_automatically": True
        },
        "timestamp": datetime.now().isoformat()
    }
    
    return jsonify(response), 200

def create_error_response(error_message: str, status_code: int = 400, error_type: str = "general") -> tuple:
    """에러 응답 생성"""
    response = {
        "success": False,
        "error": {
            "message": error_message,
            "type": error_type
        },
        "timestamp": datetime.now().isoformat()
    }
    
    return jsonify(response), status_code

def create_validation_error_response(validation_errors: List[str]) -> tuple:
    """검증 오류 응답 생성"""
    response = {
        "success": False,
        "error": {
            "type": "validation_error",
            "message": "입력 데이터 검증에 실패했습니다",
            "details": validation_errors
        },
        "timestamp": datetime.now().isoformat()
    }
    
    return jsonify(response), 400

def create_health_response(health_data: Dict[str, Any]) -> tuple:
    """상태 확인 응답 생성"""
    response = {
        "success": True,
        "status": "healthy",
        "health_data": {
            "server_status": health_data.get('status', 'unknown'),
            "device": health_data.get('device', 'unknown'),
            "llm_type": health_data.get('llm_type', 'unknown'),
            "text_processing_config": health_data.get('text_processing_config', {}),
            "timestamp": health_data.get('timestamp', datetime.now().isoformat())
        },
        "timestamp": datetime.now().isoformat()
    }
    
    return jsonify(response), 200

def create_test_response() -> tuple:
    """테스트 응답 생성"""
    response = {
        "success": True,
        "message": "AI Server is running!",
        "version": "2.0.0",
        "mode": "text-based",
        "timestamp": datetime.now().isoformat()
    }
    
    return jsonify(response), 200 