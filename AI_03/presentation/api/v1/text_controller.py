#!/usr/bin/env python3
"""
Text Processing API Controller
텍스트 처리 API 컨트롤러
"""

from flask import Blueprint, request, jsonify
from typing import Dict, Any

from shared.logging.logger import LoggerFactory
from shared.constants.error_types import ErrorTypes
from shared.container import container
from core.entities.text_request import TextRequest
from core.usecases.text_processing.process_text_usecase import ProcessTextUseCase
from presentation.dto.requests import ProcessTextRequestDTO
from presentation.dto.responses import ProcessTextResponseDTO, APIResponseDTO


text_bp = Blueprint('text', __name__)
logger = LoggerFactory.get_logger(__name__)


def _create_ai02_response(result):
    """AI_02 호환 성공 응답 생성"""
    from datetime import datetime
    
    if result.action_type == "schedule_add":
        schedule_data = result.action_data.get("schedule_data", {})
        # AI_02 스타일 highlight_date 처리
        highlight_date = None
        if schedule_data.get('datetime'):
            datetime_str = str(schedule_data['datetime'])
            if ' ' in datetime_str:
                highlight_date = datetime_str.split(' ')[0]
            elif 'T' in datetime_str:
                highlight_date = datetime_str.split('T')[0]
        
        return _create_schedule_action_response(
            action_type="schedule_add",
            schedule_data=schedule_data,
            text_response=result.response_text,
            highlight_date=highlight_date
        )
    elif result.action_type == "schedule_delete":
        return _create_schedule_action_response(
            action_type="schedule_delete",
            schedule_data=result.action_data.get("schedule_data", {}),
            text_response=result.response_text
        )
    elif result.action_type == "schedule_read":
        schedules = result.action_data.get("schedules", [])
        return _create_app_action_response(
            action_type="schedule_list",
            data={"schedules": schedules},
            text_response={
                "text": result.response_text,
                "display_automatically": True
            },
            ui_instructions={
                "screen": "schedule_list",
                "refresh_data": True,
                "highlight_important": True  # AI_02 스타일 추가
            }
        )
    else:
        # 일반 텍스트 응답
        return _create_text_response(result.response_text)


def _create_ai02_error_response(result):
    """AI_02 호환 에러 응답 생성"""
    from datetime import datetime
    
    error_type = result.action_data.get("error_type", ErrorTypes.SYSTEM_ERROR)
    response = {
        "success": False,
        "action": {
            "type": "error",
            "is_important": True,
            "data": {
                "error_type": error_type,
                "message": result.error_message or result.response_text
            },
            "ui_instructions": {
                "notification": {
                    "type": "error",
                    "title": "오류 발생",
                    "message": result.error_message or result.response_text,
                    "duration": 5000
                }
            }
        },
        "timestamp": result.timestamp.isoformat()
    }
    
    return jsonify(response), 400


def _create_app_action_response(action_type: str, data: Dict[str, Any], text_response: Dict[str, Any] = None, ui_instructions: Dict[str, Any] = None, is_important: bool = False):
    """AI_02 스타일 액션 응답 생성"""
    from datetime import datetime
    
    response = {
        "success": True,
        "action": {
            "type": action_type,
            "is_important": is_important,
            "data": data,
            "ui_instructions": ui_instructions or {}
        },
        "timestamp": datetime.now().isoformat()
    }
    
    if text_response:
        response["text_response"] = text_response
    
    return jsonify(response), 200


def _create_schedule_action_response(action_type: str, schedule_data: Dict[str, Any], text_response: str, ui_screen: str = "calendar", highlight_date: str = None):
    """AI_02 완전 동일 일정 액션 응답 생성"""
    
    ui_instructions = {
        "screen": ui_screen,
        "refresh_data": True
    }
    
    # highlight_date 처리 (AI_02 방식)
    if highlight_date:
        ui_instructions["highlight_date"] = highlight_date
    elif schedule_data.get('datetime'):
        # datetime에서 날짜 부분 추출
        datetime_str = str(schedule_data['datetime'])
        if 'T' in datetime_str:
            ui_instructions["highlight_date"] = datetime_str.split('T')[0]
        elif ' ' in datetime_str:
            ui_instructions["highlight_date"] = datetime_str.split(' ')[0]
    
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
    
    text_response_data = {
        "text": text_response,
        "display_automatically": True
    }
    
    return _create_app_action_response(
        action_type=action_type,
        data=schedule_data,
        text_response=text_response_data,
        ui_instructions=ui_instructions,
        is_important=True
    )


def _create_text_response(text: str, response_text: str = None, simple_text: str = None):
    """AI_02 완전 동일 텍스트 전용 응답 생성"""
    from datetime import datetime
    
    text_response_data = {
        "text": text,
        "display_automatically": True
    }
    
    # AI_02 스타일 추가 필드
    if simple_text:
        text_response_data["simple_text"] = simple_text
    
    if response_text:
        text_response_data["response_text"] = response_text
    
    response = {
        "success": True,
        "action": {
            "type": "text_response",
            "is_important": False,
            "data": {},
            "ui_instructions": {
                "show_text_indicator": True
            }
        },
        "text_response": text_response_data,
        "timestamp": datetime.now().isoformat()
    }
    
    return jsonify(response), 200


@text_bp.route('/process_text', methods=['POST'])
def process_text():
    """텍스트 처리 엔드포인트"""
    try:
        # 1. 요청 데이터 검증
        if not request.is_json:
            return _create_error_action_response(
                "Content-Type must be application/json",
                ErrorTypes.MISSING_CONTENT_TYPE
            )
        
        data = request.get_json() or {}
        request_dto = ProcessTextRequestDTO.from_dict(data)
        
        if not request_dto.is_valid():
            return _create_error_action_response(
                "텍스트와 사용자 ID가 필요합니다.",
                ErrorTypes.MISSING_REQUIRED_DATA
            )
        
        # AI_02 스타일 로그: 요청 수신
        logger.info(f"Text processing request received: '{request_dto.text}' from user: {request_dto.user_id}")
        
        # 2. Use Case 실행
        use_case = container.get(ProcessTextUseCase)
        text_request = TextRequest(
            text=request_dto.text,
            user_id=request_dto.user_id
        )
        
        result = use_case.execute(text_request)
        
        # AI_02 스타일 로그: 처리 완료
        if result.success:
            logger.info(f"Text processing completed: {result.action_type} -> {result.response_text[:50]}...")
        else:
            logger.error(f"Text processing failed: {result.error_message}")
        
        # 3. AI_02 호환 응답 생성
        if result.success:
            response = _create_ai02_response(result)
            logger.info(f"Response sent: {result.action_type} action with text: '{result.response_text[:30]}...'")
            return response
        else:
            response = _create_ai02_error_response(result)
            logger.error(f"Error response sent: {result.error_message}")
            return response
            
    except Exception as e:
        logger.error(f"Text processing API error: {e}")
        return _create_error_action_response(
            "서버 내부 오류가 발생했습니다.",
            ErrorTypes.INTERNAL_ERROR
        )


@text_bp.route('/health', methods=['GET'])
def health_check():
    """서버 상태 확인 (AI_02 호환)"""
    try:
        # AI_02 스타일 health_info 생성
        health_info = _get_health_info()
        return _create_health_action_response(health_info)
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return _create_error_action_response("서버 상태 확인 중 오류가 발생했습니다", ErrorTypes.HEALTH_CHECK_ERROR)


def _get_health_info():
    """서버 상태 정보 수집"""
    from datetime import datetime
    
    health_info = {
        'service': 'AI Text Processing Server',
        'version': '2.0.0',
        'timestamp': datetime.now().isoformat(),
        'status': 'healthy'
    }
    
    # LLM 서비스 상태 확인
    try:
        from core.interfaces.services.llm_service import ILLMService
        llm_service = container.get(ILLMService)
        model_info = llm_service.get_model_info()
        health_info['llm'] = {
            'status': 'available',
            'provider': model_info.get('provider'),
            'model': model_info.get('model')
        }
    except Exception as e:
        health_info['llm'] = {
            'status': 'error',
            'error': str(e)
        }
    
    return health_info


def _create_health_action_response(health_data: Dict[str, Any]):
    """상태 확인 액션 응답 생성 (AI_02 동일)"""
    from datetime import datetime
    
    response = {
        "success": True,
        "action": {
            "type": "health_check",
            "is_important": False,
            "data": health_data,
            "ui_instructions": {
                "show_status_indicator": True
            }
        },
        "timestamp": datetime.now().isoformat()
    }
    
    return jsonify(response), 200


def _create_error_action_response(error_message: str, error_type: str = ErrorTypes.SYSTEM_ERROR, fallback_action: Dict[str, Any] = None):
    """에러 액션 응답 생성 (AI_02 동일)"""
    from datetime import datetime
    
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
            "is_important": True,
            "data": {
                "error_type": error_type,
                "message": error_message
            },
            "ui_instructions": ui_instructions
        },
        "timestamp": datetime.now().isoformat()
    }
    
    return jsonify(response), 400


# 에러 핸들러
@text_bp.errorhandler(400)
def bad_request(error):
    """잘못된 요청 에러 핸들러"""
    return _create_error_action_response(
        "잘못된 요청입니다.",
        ErrorTypes.BAD_REQUEST
    )


@text_bp.errorhandler(404)
def not_found(error):
    """찾을 수 없음 에러 핸들러"""
    return _create_error_action_response(
        "요청한 리소스를 찾을 수 없습니다.",
        ErrorTypes.NOT_FOUND
    )


@text_bp.errorhandler(500)
def internal_error(error):
    """내부 서버 에러 핸들러"""
    logger.error(f"Internal server error: {error}")
    return _create_error_action_response(
        "서버 내부 오류가 발생했습니다.",
        ErrorTypes.INTERNAL_ERROR
    )
