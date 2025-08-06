#!/usr/bin/env python3
"""
Response Utilities
고령층 일정 메모 관리 AI 서버 응답 유틸리티
"""

from flask import jsonify
from datetime import datetime
from typing import Dict, Any, Optional

def create_response(data: Dict[str, Any], status_code: int = 200) -> tuple:
    """표준 응답 생성"""
    response = {
        "success": True,
        "data": data,
        "timestamp": datetime.now().isoformat()
    }
    return jsonify(response), status_code

def create_error_response(error_message: str, status_code: int = 400, 
                        error_code: Optional[str] = None) -> tuple:
    """에러 응답 생성"""
    response = {
        "success": False,
        "error": error_message,
        "timestamp": datetime.now().isoformat()
    }
    
    if error_code:
        response["error_code"] = error_code
    
    return jsonify(response), status_code

def create_elderly_response(data: Dict[str, Any], status_code: int = 200) -> tuple:
    """고령자 특화 응답 생성"""
    response = {
        "success": True,
        "data": data,
        "timestamp": datetime.now().isoformat(),
        "elderly_optimized": True,
        "simple_message": _extract_simple_message(data)
    }
    return jsonify(response), status_code

def create_schedule_response(schedule_data: Dict[str, Any], 
                           message: str = "일정이 성공적으로 처리되었습니다") -> tuple:
    """일정 관련 응답 생성"""
    response = {
        "success": True,
        "message": message,
        "schedule": schedule_data,
        "timestamp": datetime.now().isoformat(),
        "reminder_set": schedule_data.get('reminder', True)
    }
    return jsonify(response), 200

def create_voice_response(voice_result: Dict[str, Any]) -> tuple:
    """음성 처리 응답 생성"""
    response = {
        "success": voice_result.get('success', False),
        "user_message": voice_result.get('user_message', ''),
        "ai_response": voice_result.get('ai_response', ''),
        "audio_response": voice_result.get('audio_response', ''),
        "schedule_result": voice_result.get('schedule_result', {}),
        "processing_time": voice_result.get('processing_time', 0),
        "timestamp": datetime.now().isoformat()
    }
    
    # 고령자 특화 처리
    if response.get('success'):
        response['elderly_optimized'] = True
        response['simple_response'] = _extract_simple_message(response)
    
    return jsonify(response), 200

def create_health_response(health_data: Dict[str, Any]) -> tuple:
    """헬스체크 응답 생성"""
    response = {
        "success": True,
        "status": health_data.get('status', 'unknown'),
        "server_info": {
            "device": health_data.get('device', 'unknown'),
            "llm_type": health_data.get('llm_type', 'unknown'),
            "stt_model": health_data.get('stt_model', 'unknown')
        },
        "pipeline_info": health_data.get('pipeline_info', {}),
        "memory_info": health_data.get('memory_info', {}),
        "elderly_settings": health_data.get('elderly_settings', {}),
        "timestamp": datetime.now().isoformat()
    }
    return jsonify(response), 200

def _extract_simple_message(data: Dict[str, Any]) -> str:
    """복잡한 응답에서 간단한 메시지 추출"""
    if isinstance(data, dict):
        # AI 응답이 있으면 사용
        if 'ai_response' in data:
            response = data['ai_response']
            if len(response) > 100:
                # 핵심 내용만 추출
                if '일정이 등록되었습니다' in response:
                    return "일정이 등록되었습니다."
                elif '추가 정보가 필요합니다' in response:
                    return "좀 더 자세히 말씀해 주세요."
                else:
                    return response[:50] + "..."
            return response
        
        # 메시지가 있으면 사용
        if 'message' in data:
            return data['message']
        
        # 제목이 있으면 사용
        if 'title' in data:
            return f"처리 완료: {data['title']}"
    
    return "처리가 완료되었습니다."

def create_validation_error_response(field: str, message: str) -> tuple:
    """검증 에러 응답 생성"""
    return create_error_response(
        f"입력 검증 실패: {field} - {message}",
        400,
        "VALIDATION_ERROR"
    )

def create_not_found_response(resource: str) -> tuple:
    """리소스 없음 응답 생성"""
    return create_error_response(
        f"{resource}을(를) 찾을 수 없습니다",
        404,
        "NOT_FOUND"
    )

def create_unauthorized_response() -> tuple:
    """인증 실패 응답 생성"""
    return create_error_response(
        "인증이 필요합니다",
        401,
        "UNAUTHORIZED"
    )

def create_rate_limit_response() -> tuple:
    """속도 제한 응답 생성"""
    return create_error_response(
        "요청이 너무 많습니다. 잠시 후 다시 시도해주세요",
        429,
        "RATE_LIMIT_EXCEEDED"
    ) 