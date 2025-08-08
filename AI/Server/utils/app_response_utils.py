#!/usr/bin/env python3
"""
App Response Utilities
애플리케이션 연동을 위한 응답 유틸리티
"""

import base64
from flask import jsonify
from datetime import datetime
from typing import Dict, Any, Optional, List

def create_app_action_response(
    action_type: str,
    data: Dict[str, Any],
    voice_response: Optional[Dict[str, Any]] = None,
    ui_instructions: Optional[Dict[str, Any]] = None,
    priority: str = "medium"
) -> tuple:
    """애플리케이션 액션 응답 생성"""
    
    response = {
        "success": True,
        "action": {
            "type": action_type,
            "priority": priority,
            "data": data,
            "ui_instructions": ui_instructions or {}
        },
        "timestamp": datetime.now().isoformat()
    }
    
    if voice_response:
        response["voice_response"] = voice_response
    
    return jsonify(response), 200

def create_schedule_action_response(
    action_type: str,
    schedule_data: Dict[str, Any],
    voice_text: str,
    ui_screen: str = "calendar",
    highlight_date: Optional[str] = None
) -> tuple:
    """일정 관련 액션 응답 생성"""
    
    ui_instructions = {
        "screen": ui_screen,
        "refresh_data": True
    }
    
    if highlight_date:
        ui_instructions["highlight_date"] = highlight_date
    
    if action_type == "schedule_add":
        ui_instructions["show_confirmation"] = True
        ui_instructions["notification"] = {
            "type": "success",
            "title": "일정 추가됨",
            "message": f"{schedule_data.get('title', '일정')}이 추가되었습니다"
        }
    elif action_type == "schedule_delete":
        ui_instructions["remove_item"] = schedule_data.get("id")
        ui_instructions["notification"] = {
            "type": "info",
            "title": "일정 삭제됨",
            "message": "일정이 삭제되었습니다"
        }
    
    voice_response = {
        "text": voice_text,
        "play_automatically": True,
        "elderly_optimized": {
            "slow_speech": True,
            "high_volume": True
        }
    }
    
    return create_app_action_response(
        action_type=action_type,
        data=schedule_data,
        voice_response=voice_response,
        ui_instructions=ui_instructions,
        priority="high"
    )

def create_settings_action_response(
    setting_type: str,
    changes: Dict[str, Any],
    voice_text: str
) -> tuple:
    """설정 변경 액션 응답 생성"""
    
    ui_instructions = {
        "screen": "settings",
        "refresh_settings": True,
        "show_preview": True,
        "notification": {
            "type": "success",
            "title": "설정 변경됨",
            "message": "설정이 변경되었습니다"
        }
    }
    
    voice_response = {
        "text": voice_text,
        "play_automatically": True,
        "elderly_optimized": {
            "slow_speech": False,
            "high_volume": True
        }
    }
    
    return create_app_action_response(
        action_type="settings_update",
        data={
            "setting_type": setting_type,
            "changes": changes
        },
        voice_response=voice_response,
        ui_instructions=ui_instructions,
        priority="medium"
    )

def create_voice_only_response(
    text: str,
    audio_data: Optional[bytes] = None,
    simple_text: Optional[str] = None
) -> tuple:
    """음성 전용 응답 생성"""
    
    voice_response = {
        "text": text,
        "play_automatically": True,
        "elderly_optimized": {
            "slow_speech": True,
            "high_volume": True
        }
    }
    
    if simple_text:
        voice_response["simple_text"] = simple_text
    
    if audio_data:
        voice_response["audio_url"] = f"data:audio/mp3;base64,{base64.b64encode(audio_data).decode()}"
    
    response = {
        "success": True,
        "action": {
            "type": "voice_response",
            "priority": "low",
            "data": {},
            "ui_instructions": {
                "show_voice_indicator": True
            }
        },
        "voice_response": voice_response,
        "timestamp": datetime.now().isoformat()
    }
    
    return jsonify(response), 200

def create_error_action_response(
    error_message: str,
    error_type: str = "general",
    fallback_action: Optional[Dict[str, Any]] = None
) -> tuple:
    """에러 액션 응답 생성"""
    
    ui_instructions = {
        "notification": {
            "type": "error",
            "title": "오류 발생",
            "message": error_message,
            "duration": 5000
        }
    }
    
    if fallback_action:
        ui_instructions["fallback_action"] = fallback_action
    
    response = {
        "success": False,
        "action": {
            "type": "error",
            "priority": "high",
            "data": {
                "error_type": error_type,
                "message": error_message
            },
            "ui_instructions": ui_instructions
        },
        "timestamp": datetime.now().isoformat()
    }
    
    return jsonify(response), 400

def create_health_action_response(health_data: Dict[str, Any]) -> tuple:
    """상태 확인 액션 응답 생성"""
    
    response = {
        "success": True,
        "action": {
            "type": "health_check",
            "priority": "low",
            "data": health_data,
            "ui_instructions": {
                "show_status_indicator": True
            }
        },
        "timestamp": datetime.now().isoformat()
    }
    
    return jsonify(response), 200
