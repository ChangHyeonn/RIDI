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
from core.usecases.schedule.delete_schedule_usecase import DeleteScheduleUseCase
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
        grouped_schedules = result.action_data.get("grouped_schedules", {})
        search_keyword = result.action_data.get("search_keyword")
        total_count = result.action_data.get("total_count", 0)
        date_range = result.action_data.get("date_range", {})
        
        ui_instructions = {
            "screen": "schedule_list",
            "refresh_data": True,
            "highlight_important": True,
            "show_visual_list": True,  # 시각적 목록 표시
            "group_by_date": True,     # 날짜별 그룹핑
            "total_count": total_count
        }
        
        # 키워드 검색인 경우 UI 지시사항 추가
        if search_keyword:
            ui_instructions["search_keyword"] = search_keyword
        
        # 날짜 범위 정보 추가
        if date_range:
            ui_instructions["date_range"] = date_range
        
        return _create_app_action_response(
            action_type="schedule_list",
            data={
                "schedules": schedules, 
                "grouped_schedules": grouped_schedules,
                "search_keyword": search_keyword,
                "total_count": total_count,
                "date_range": date_range
            },
            text_response={
                "text": result.response_text,
                "display_automatically": True
            },
            ui_instructions=ui_instructions
        )
    elif result.action_type == "schedule_selection":
        # 일정 선택 UI 제공
        return _create_schedule_selection_response(result)
    elif result.action_type == "schedule_delete_multiple":
        # 다중 일정 삭제 완료
        return _create_schedule_delete_multiple_response(result)
    elif result.action_type == "schedule_delete_visual":
        # 시각적 삭제 인터페이스
        search_criteria = result.action_data.get("search_criteria", {})
        found_schedules = result.action_data.get("found_schedules", [])
        total_count = result.action_data.get("total_count", 0)
        
        ui_instructions = {
            "show_delete_interface": True,
            "screen": "delete_schedule",
            "search_criteria": search_criteria,
            "total_count": total_count
        }
        
        return _create_app_action_response(
            action_type="schedule_delete_visual",
            data={
                "search_criteria": search_criteria,
                "found_schedules": found_schedules,
                "total_count": total_count,
                "show_delete_interface": True
            },
            text_response={
                "text": result.response_text,
                "display_automatically": True
            },
            ui_instructions=ui_instructions
        )
    elif result.action_type == "schedule_read_visual":
        # 시각적 조회 인터페이스
        search_criteria = result.action_data.get("search_criteria", {})
        found_schedules = result.action_data.get("found_schedules", [])
        total_count = result.action_data.get("total_count", 0)
        
        ui_instructions = {
            "show_read_interface": True,
            "screen": "schedule_list",
            "search_criteria": search_criteria,
            "total_count": total_count
        }
        
        return _create_app_action_response(
            action_type="schedule_read_visual",
            data={
                "search_criteria": search_criteria,
                "found_schedules": found_schedules,
                "total_count": total_count,
                "show_read_interface": True
            },
            text_response={
                "text": result.response_text,
                "display_automatically": True
            },
            ui_instructions=ui_instructions
        )
    elif result.action_type == "schedule_delete_cancelled":
        # 일정 삭제 취소
        return _create_text_response(result.response_text)
    else:
        # 일반 텍스트 응답
        return _create_text_response(result.response_text)


def _create_ai02_error_response(result):
    """AI_02 호환 에러 응답 생성 (200 상태 코드로 변경)"""
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
    
    return jsonify(response), 200


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
        
        # 반복 일정 UI 지시사항 추가
        is_recurring = schedule_data.get('is_recurring', False)
        if is_recurring:
            ui_instructions["highlight_recurring"] = True
            recurrence = schedule_data.get('recurrence', {})
            
            # recurrence가 None인 경우 빈 딕셔너리로 처리
            if recurrence is None:
                recurrence = {}
            
            if recurrence.get('times') and len(recurrence['times']) > 1:
                ui_instructions["show_multiple_times"] = True
            if recurrence.get('end_date'):
                ui_instructions["show_end_date"] = True
            else:
                ui_instructions["show_indefinite"] = True
            if recurrence.get('type') == 'custom_days':
                ui_instructions["show_custom_days"] = True
            
            # 반복 일정 전용 알림
            recurrence_desc = _get_recurrence_description(recurrence)
            ui_instructions["notification"] = {
                "type": "success",
                "title": "반복 일정 추가됨",
                "message": f"{schedule_data.get('title', '일정')} {recurrence_desc}이 추가되었습니다"
            }
        else:
            # 일반 일정 알림
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


def _get_recurrence_description(recurrence: Dict[str, Any]) -> str:
    """반복 패턴 설명 생성"""
    try:
        recurrence_type = recurrence.get('type', 'daily')
        times = recurrence.get('times', [])
        days_of_week = recurrence.get('days_of_week', [])
        
        # 반복 주기 설명
        type_desc = {
            'daily': '매일',
            'weekdays': '평일마다',
            'weekends': '주말마다',
            'custom_days': _get_custom_days_description(days_of_week)
        }.get(recurrence_type, '반복')
        
        # 시간 설명 (간단히)
        if len(times) > 1:
            return f"{type_desc} {len(times)}회"
        else:
            return type_desc
            
    except:
        return "반복"


def _get_custom_days_description(days_of_week: list) -> str:
    """요일 목록을 한국어로 변환"""
    if not days_of_week:
        return "특정 요일마다"
    
    day_names = ['월', '화', '수', '목', '금', '토', '일']
    try:
        selected_days = [day_names[day] for day in days_of_week if 0 <= day <= 6]
        if len(selected_days) <= 2:
            return ", ".join(selected_days) + "요일마다"
        else:
            return f"{len(selected_days)}개 요일마다"
    except:
        return "특정 요일마다"


def _create_schedule_selection_response(result):
    """일정 선택 응답 생성 (guide.md v3.2.0 호환)"""
    from datetime import datetime
    
    response = {
        "success": False,  # guide.md에 따라 False로 설정
        "action": {
            "type": "schedule_selection",
            "is_important": True,
            "data": {
                "search_title": result.action_data.get("search_title", ""),
                "similar_schedules": result.action_data.get("similar_schedules", []),
                "total_found": result.action_data.get("total_found", 0)
            },
            "ui_instructions": {
                "screen": "schedule_selection",
                "show_selection_ui": True,
                "allow_multiple_selection": True,
                "selection_type": "delete",
                "notification": {
                    "type": "info",
                    "title": "일정 선택",
                    "message": "삭제할 일정을 선택해주세요"
                }
            }
        },
        "text_response": {
            "text": result.response_text,
            "display_automatically": True
        },
        "timestamp": datetime.now().isoformat()
    }
    
    return jsonify(response), 200


def _create_schedule_delete_multiple_response(result):
    """다중 일정 삭제 완료 응답 생성 (guide.md v3.2.0 호환)"""
    from datetime import datetime
    
    response = {
        "success": True,
        "action": {
            "type": "schedule_delete_multiple",
            "is_important": True,
            "data": {
                "deleted_schedules": result.action_data.get("deleted_schedules", []),
                "deleted_count": result.action_data.get("deleted_count", 0)
            },
            "ui_instructions": {
                "screen": "calendar",
                "refresh_data": True,
                "remove_items": result.action_data.get("deleted_schedules", []),
                "notification": {
                    "type": "success",
                    "title": "일정 삭제 완료",
                    "message": f"{result.action_data.get('deleted_count', 0)}개 일정이 삭제되었습니다"
                }
            }
        },
        "text_response": {
            "text": result.response_text,
            "display_automatically": True
        },
        "timestamp": datetime.now().isoformat()
    }
    
    return jsonify(response), 200


def _create_schedule_delete_cancelled_response(result):
    """일정 삭제 취소 응답 생성 (guide.md v3.2.0 호환)"""
    from datetime import datetime
    
    response = {
        "success": True,
        "action": {
            "type": "schedule_delete_cancelled",
            "is_important": False,
            "data": {
                "cancelled": True,
                "message": "일정 삭제가 취소되었습니다"
            },
            "ui_instructions": {
                "screen": "calendar",
                "notification": {
                    "type": "info",
                    "title": "삭제 취소",
                    "message": "일정 삭제가 취소되었습니다"
                }
            }
        },
        "text_response": {
            "text": result.response_text,
            "display_automatically": True
        },
        "timestamp": datetime.now().isoformat()
    }
    
    return jsonify(response), 200


def _create_clarification_request_response(result):
    """명확화 요청 응답 생성"""
    from datetime import datetime
    
    action_data = result.action_data
    clarification_text = action_data.get("clarification_text", "추가 정보가 필요합니다.")
    missing_fields = action_data.get("missing_fields", [])
    
    response = {
        "success": False,  # 명확화 요청은 성공이 아님
        "action": {
            "type": "clarification_request",
            "is_important": True,
            "data": {
                "clarification_text": clarification_text,
                "original_request": action_data.get("original_request", ""),
                "missing_fields": missing_fields,
                "schedule_info": action_data.get("schedule_info", {})
            },
            "ui_instructions": {
                "notification": {
                    "type": "warning",
                    "title": "추가 정보 필요",
                    "message": clarification_text,
                    "duration": 5000
                },
                "show_clarification_ui": True,
                "wait_for_user_input": True
            }
        },
        "timestamp": datetime.now().isoformat()
    }
    
    # 텍스트 응답 추가
    response["text_response"] = {
        "text": clarification_text,
        "display_automatically": True
    }
    
    return jsonify(response), 200


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
        if result.success or result.action_type == "schedule_selection":
            response = _create_ai02_response(result)
            logger.info(f"Response sent: {result.action_type} action with text: '{result.response_text[:30]}...'")
            return response
        elif result.action_type == "clarification_request":
            response = _create_clarification_request_response(result)
            logger.info(f"Clarification request sent: {result.response_text[:30]}...")
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
    """에러 액션 응답 생성 (200 상태 코드로 변경)"""
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
    
    return jsonify(response), 200


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


@text_bp.route('/delete_schedule/<schedule_id>', methods=['DELETE'])
def delete_schedule_by_id(schedule_id: str):
    """특정 일정 삭제 API"""
    try:
        user_id = request.args.get('user_id', 'user123')  # 기본값 설정
        
        # DeleteScheduleUseCase 가져오기
        delete_usecase = container.get(DeleteScheduleUseCase)
        
        # 삭제 실행
        result = delete_usecase.execute_delete_by_id(user_id, schedule_id)
        
        if result.success:
            return jsonify({
                'success': True,
                'message': f'{result.deleted_title} 일정을 삭제했습니다.',
                'deleted_title': result.deleted_title
            }), 200
        else:
            return jsonify({
                'success': False,
                'error': result.error_message
            }), 400
            
    except Exception as e:
        logger.error(f"Delete schedule by ID failed: {e}")
        return jsonify({
            'success': False,
            'error': '일정 삭제 중 오류가 발생했습니다.'
        }), 500
