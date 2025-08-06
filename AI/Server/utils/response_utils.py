#!/usr/bin/env python3
"""
Response Utilities
고령층 일정 메모 관리 AI 서버 응답 유틸리티
"""

import base64
from flask import jsonify
from datetime import datetime
from typing import Dict, Any, Optional, List

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

def create_voice_response_with_audio(voice_result: Dict[str, Any]) -> tuple:
    """음성 데이터가 base64로 인코딩된 응답 생성"""
    response = {
        "success": voice_result.get('success', False),
        "user_message": voice_result.get('user_message', ''),
        "ai_response": voice_result.get('ai_response', ''),
        "schedule_result": voice_result.get('schedule_result', {}),
        "command_type": voice_result.get('command_type', 'unknown'),
        "processing_time": voice_result.get('processing_time', 0),
        "timestamp": datetime.now().isoformat()
    }
    
    # 음성 데이터를 base64로 인코딩
    audio_data = voice_result.get('audio_response')
    if audio_data and isinstance(audio_data, bytes):
        try:
            audio_base64 = base64.b64encode(audio_data).decode('utf-8')
            response['audio_response'] = audio_base64
            response['audio_format'] = 'mp3'
            response['audio_encoding'] = 'base64'
        except Exception as e:
            response['audio_error'] = f"음성 인코딩 실패: {str(e)}"
    
    # 고령자 특화 처리
    if response.get('success'):
        response['elderly_optimized'] = True
        response['simple_response'] = _extract_simple_message(response)
    
    return jsonify(response), 200

def create_schedule_response_with_audio(success: bool, data: Dict[str, Any], 
                                      audio_data: bytes = None, message: str = "") -> tuple:
    """일정 응답에 음성 포함"""
    response = {
        "success": success,
        "timestamp": datetime.now().isoformat(),
        "type": "schedule",
        "message": message or "일정 처리가 완료되었습니다"
    }
    
    if success:
        response.update({
            "data": data
        })
    else:
        response.update({
            "error": data.get("error", "일정 처리 중 오류가 발생했습니다"),
            "details": data
        })
    
    # 음성 데이터 추가
    if audio_data and isinstance(audio_data, bytes):
        try:
            audio_base64 = base64.b64encode(audio_data).decode('utf-8')
            response['audio_response'] = audio_base64
            response['audio_format'] = 'mp3'
            response['audio_encoding'] = 'base64'
        except Exception as e:
            response['audio_error'] = f"음성 인코딩 실패: {str(e)}"
    
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