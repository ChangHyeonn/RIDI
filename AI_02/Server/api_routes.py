#!/usr/bin/env python3
"""
API Routes for AI Server (Text-based)
고령층 일정 메모 관리 AI 서버 API 라우트 (텍스트 기반)
"""

import sys
import os
import logging
import base64

# 프로젝트 루트를 Python 경로에 추가
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from flask import Blueprint, request, jsonify, current_app
from datetime import datetime
from Server.utils.response_utils import create_response, create_error_response
from Server.utils.app_response_utils import (
    create_app_action_response, create_schedule_action_response,
    create_settings_action_response, create_text_response,
    create_error_action_response, create_health_action_response
)
from Server.utils.validation import validate_text_input, validate_schedule_data, validate_accessibility_settings
from Server.utils.auth import require_api_key
from Config.settings import Settings

# Blueprint 생성
api_bp = Blueprint('api', __name__)
logger = logging.getLogger(__name__)

@api_bp.route('/health', methods=['GET'])
def health_check():
    """서버 상태 확인"""
    try:
        health_info = current_app.ai_service.get_health_info()
        return create_health_action_response(health_info)
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return create_error_action_response("서버 상태 확인 중 오류가 발생했습니다", "health_check")

@api_bp.route('/process_text', methods=['POST'])
def process_text():
    """텍스트 명령 처리 API"""
    try:
        # 입력 검증
        data = request.get_json()
        if not data or 'text' not in data:
            return create_error_response("텍스트가 제공되지 않았습니다", 400)
        
        user_text = data['text']
        user_id = data.get('user_id', 'default_user')
        
        # 텍스트 검증
        validation_result = validate_text_input(user_text)
        if not validation_result['valid']:
            return create_error_response(validation_result['error'], 400)
        
        try:
            # AI 처리 (텍스트 기반 통합 파이프라인 사용)
            result = current_app.ai_service.process_text_command(user_text, user_id)
            
            # 액션 기반 응답으로 변환
            if result.get('success'):
                processing_result = result.get('processing_result', {})
                analysis = processing_result.get('analysis', {})
                result_data = processing_result.get('result', {})
                response_text = result.get('response_text', '')
                
                category = analysis.get('category', 'other')
                action = result_data.get('action', '')

                # 추가 정보 필요 시 명확화 요청 응답
                if result_data.get('requires_clarification'):
                    msg = result_data.get('message', '추가 정보가 필요합니다.')
                    candidates = result_data.get('candidates', [])
                    payload = {"message": msg}
                    if candidates:
                        payload["candidates"] = candidates
                    return create_app_action_response(
                        action_type="clarification_request",
                        data=payload,
                        text_response={
                            "text": msg,
                            "display_automatically": True
                        },
                        ui_instructions={
                            "screen": "conversation",
                            "show_candidates": bool(candidates)
                        }
                    )
                
                if category == "schedule_add" or action == "schedule_added":
                    schedule_data = result_data.get('schedule', {})
                    schedule_id = result_data.get('schedule_id')
                    # 최소 페이로드만 앱으로 전달 (id, title, datetime)
                    minimal_payload = {
                        "id": schedule_id,
                        "title": schedule_data.get("title"),
                        "datetime": schedule_data.get("datetime")
                    }
                    return create_schedule_action_response(
                        action_type="schedule_add",
                        schedule_data=minimal_payload,
                        text_response=result_data.get('message', '일정이 추가되었습니다.'),
                        highlight_date=schedule_data.get('datetime', '').split(' ')[0] if schedule_data.get('datetime') else ''
                    )
                elif category == "schedule_delete" or action == "schedule_delete":
                    delete_info = result_data.get('delete_info', {})
                    return create_schedule_action_response(
                        action_type="schedule_delete",
                        schedule_data=delete_info,
                        text_response=result_data.get('message', '일정이 삭제되었습니다.')
                    )
                elif category == "schedule_read" or action == "schedule_read":
                    schedules = result_data.get('schedules', [])
                    return create_app_action_response(
                        action_type="schedule_list",
                        data={"schedules": schedules},
                        text_response={
                            "text": result_data.get('message', '일정을 조회했습니다.'),
                            "display_automatically": True
                        },
                        ui_instructions={
                            "screen": "schedule_list",
                            "refresh_data": True
                        }
                    )
                elif category == "accessibility" or action == "accessibility_change":
                    accessibility_info = result.get('accessibility_info', {})
                    return create_settings_action_response(
                        setting_type="accessibility",
                        changes=accessibility_info,
                        text_response=result.get('ai_response', '설정이 변경되었습니다.')
                    )
                else:
                    # 일반 텍스트 응답
                    return create_text_response(
                        text=result.get('ai_response', ''),
                        response_text=response_text
                    )
            else:
                # 텍스트 처리 실패 시
                return create_error_action_response(
                    result.get('error', '텍스트 처리 중 오류가 발생했습니다'),
                    "text_processing"
                )
                
        except Exception as e:
            logger.error(f"Text processing failed: {e}")
            return create_error_response("텍스트 처리 중 오류가 발생했습니다", 500)
                
    except Exception as e:
        logger.error(f"Text processing failed: {e}")
        return create_error_response("텍스트 처리 중 오류가 발생했습니다", 500)

@api_bp.route('/schedule/add', methods=['POST'])
def add_schedule():
    """일정 추가 API"""
    try:
        data = request.get_json()
        if not data:
            return create_error_action_response("일정 데이터가 제공되지 않았습니다", "validation_error")
        
        user_id = request.headers.get('X-User-ID', 'default_user')
        
        # 데이터 검증
        validation_result = validate_schedule_data(data)
        if not validation_result['valid']:
            return create_error_action_response(validation_result['error'], "validation_error")
        
        result = current_app.ai_service.add_schedule(data, user_id)
        
        if result.get('success'):
            schedule_data = result.get('data', {})
            return create_schedule_action_response(
                action_type="schedule_add",
                schedule_data=schedule_data,
                text_response=result.get('message', '일정이 추가되었습니다.'),
                highlight_date=schedule_data.get('datetime', '').split('T')[0] if schedule_data.get('datetime') else None
            )
        else:
            return create_error_action_response(
                result.get('error', '일정 추가 중 오류가 발생했습니다'),
                "schedule_add_error"
            )
        
    except Exception as e:
        logger.error(f"Schedule addition failed: {e}")
        return create_error_action_response("일정 추가 중 오류가 발생했습니다", "schedule_add_error")

@api_bp.route('/schedule/list', methods=['GET'])
def list_schedules():
    """일정 목록 조회 API"""
    try:
        user_id = request.args.get('user_id', 'default_user')
        result = current_app.ai_service.get_schedules(user_id)
        
        if result.get('success'):
            schedules = result.get('data', {}).get('schedules', [])
            return create_app_action_response(
                action_type="schedule_list",
                data={"schedules": schedules},
                text_response={
                    "text": f"총 {len(schedules)}개의 일정이 있습니다.",
                    "display_automatically": True
                },
                ui_instructions={
                    "screen": "schedule_list",
                    "refresh_data": True,
                    "highlight_important": True
                }
            )
        else:
            return create_error_action_response(
                result.get('error', '일정 목록 조회 중 오류가 발생했습니다'),
                "schedule_list_error"
            )
        
    except Exception as e:
        logger.error(f"Schedule list retrieval failed: {e}")
        return create_error_action_response("일정 목록 조회 중 오류가 발생했습니다", "schedule_list_error")

@api_bp.route('/schedule/remind', methods=['GET'])
def get_reminders():
    """일정 알림 조회 API"""
    try:
        user_id = request.args.get('user_id', 'default_user')
        reminders = current_app.ai_service.memory_manager.remind_schedule(user_id)
        
        return create_response({
            "reminders": reminders,
            "count": len(reminders)
        })
        
    except Exception as e:
        logger.error(f"Reminder retrieval failed: {e}")
        return create_error_response("알림 조회 중 오류가 발생했습니다", 500)

@api_bp.route('/memory/context', methods=['GET'])
def get_user_context():
    """사용자 컨텍스트 조회 API"""
    try:
        user_id = request.args.get('user_id', 'default_user')
        result = current_app.ai_service.get_user_context(user_id)
        return create_response(result)
        
    except Exception as e:
        logger.error(f"Context retrieval failed: {e}")
        return create_error_response("사용자 정보 조회 중 오류가 발생했습니다", 500)

@api_bp.route('/settings/update', methods=['POST'])
def update_settings():
    """설정 업데이트 API"""
    try:
        data = request.get_json()
        if not data:
            return create_error_response("설정 데이터가 제공되지 않았습니다", 400)
        
        # 설정 업데이트 로직 (실제로는 설정 파일이나 DB에 저장)
        # 현재는 메모리에만 저장
        current_app.user_settings = getattr(current_app, 'user_settings', {})
        current_app.user_settings.update(data)
        
        return create_response({
            "message": "설정이 업데이트되었습니다",
            "settings": current_app.user_settings
        })
        
    except Exception as e:
        logger.error(f"Settings update failed: {e}")
        return create_error_response("설정 업데이트 중 오류가 발생했습니다", 500)

@api_bp.route('/test', methods=['GET'])
def test_endpoint():
    """테스트용 엔드포인트"""
    return create_response({
        "message": "AI Server is running!",
        "timestamp": datetime.now().isoformat(),
        "version": "2.0.0"
    })

@api_bp.route('/schedule/delete', methods=['DELETE'])
def delete_schedule():
    """일정 삭제 API"""
    try:
        data = request.get_json()
        if not data:
            return create_error_action_response("삭제할 일정 정보가 제공되지 않았습니다", "validation_error")
        
        user_id = request.headers.get('X-User-ID', 'default_user')
        schedule_id = data.get('schedule_id')
        
        if not schedule_id:
            return create_error_action_response("일정 ID가 필요합니다", "validation_error")
        
        result = current_app.ai_service.delete_schedule(user_id, schedule_id)
        
        if result.get('success'):
            schedule_data = {
                "id": schedule_id,
                "title": data.get('title', '일정'),
                "date": data.get('date', '')
            }
            return create_schedule_action_response(
                action_type="schedule_delete",
                schedule_data=schedule_data,
                text_response=result.get('message', '일정이 삭제되었습니다.')
            )
        else:
            return create_error_action_response(
                result.get('error', '일정 삭제 중 오류가 발생했습니다'),
                "schedule_delete_error"
            )
        
    except Exception as e:
        logger.error(f"Schedule deletion failed: {e}")
        return create_error_action_response("일정 삭제 중 오류가 발생했습니다", "schedule_delete_error")

@api_bp.route('/schedule/read', methods=['GET'])
def read_schedules_by_date():
    """특정 날짜 일정 조회 API"""
    try:
        user_id = request.args.get('user_id', 'default_user')
        target_date = request.args.get('date', 'today')
        
        result = current_app.ai_service.get_schedules_by_date(user_id, target_date)
        
        if result.get('success'):
            schedules = result.get('data', {}).get('schedules', [])
            return create_app_action_response(
                action_type="schedule_list",
                data={
                    "schedules": schedules,
                    "date": target_date
                },
                text_response={
                    "text": f"{target_date}에 {len(schedules)}개의 일정이 있습니다.",
                    "display_automatically": True
                },
                ui_instructions={
                    "screen": "schedule_list",
                    "refresh_data": True,
                    "highlight_date": target_date,
                    "highlight_important": True
                }
            )
        else:
            return create_error_action_response(
                result.get('error', '일정 조회 중 오류가 발생했습니다'),
                "schedule_read_error"
            )
        
    except Exception as e:
        logger.error(f"Schedule reading failed: {e}")
        return create_error_action_response("일정 조회 중 오류가 발생했습니다", "schedule_read_error")

@api_bp.route('/schedule/important', methods=['GET'])
def get_important_schedules():
    """중요 일정 조회 API"""
    try:
        user_id = request.args.get('user_id', 'default_user')
        result = current_app.ai_service.get_important_schedules(user_id)
        
        if result.get('success'):
            schedules = result.get('data', {}).get('schedules', [])
            return create_app_action_response(
                action_type="schedule_list",
                data={
                    "schedules": schedules,
                    "filter": "important"
                },
                text_response={
                    "text": f"중요한 일정 {len(schedules)}개가 있습니다.",
                    "display_automatically": True
                },
                ui_instructions={
                    "screen": "schedule_list",
                    "refresh_data": True,
                    "highlight_important": True,
                    "filter_important": True
                }
            )
        else:
            return create_error_action_response(
                result.get('error', '중요 일정 조회 중 오류가 발생했습니다'),
                "important_schedule_error"
            )
        
    except Exception as e:
        logger.error(f"Important schedule retrieval failed: {e}")
        return create_error_action_response("중요 일정 조회 중 오류가 발생했습니다", "important_schedule_error")

@api_bp.route('/settings/accessibility', methods=['PUT'])
def update_accessibility_settings():
    """접근성 설정 업데이트 API"""
    try:
        data = request.get_json()
        if not data:
            return create_error_action_response("접근성 설정 데이터가 제공되지 않았습니다", "validation_error")
        
        user_id = request.headers.get('X-User-ID', 'default_user')
        
        # 설정 검증
        validation_result = validate_accessibility_settings(data)
        if not validation_result['valid']:
            return create_error_action_response(validation_result['error'], "validation_error")
        
        result = current_app.ai_service.update_accessibility_settings(user_id, data)
        
        if result.get('success'):
            return create_settings_action_response(
                setting_type="accessibility",
                changes=data,
                text_response=result.get('message', '접근성 설정이 변경되었습니다.')
            )
        else:
            return create_error_action_response(
                result.get('error', '접근성 설정 업데이트 중 오류가 발생했습니다'),
                "accessibility_update_error"
            )
        
    except Exception as e:
        logger.error(f"Accessibility settings update failed: {e}")
        return create_error_action_response("접근성 설정 업데이트 중 오류가 발생했습니다", "accessibility_update_error")

@api_bp.route('/settings/accessibility', methods=['GET'])
def get_accessibility_settings():
    """접근성 설정 조회 API"""
    try:
        user_id = request.args.get('user_id', 'default_user')
        result = current_app.ai_service.get_accessibility_settings(user_id)
        
        if result.get('success'):
            settings = result.get('data', {}).get('settings', {})
            return create_app_action_response(
                action_type="settings_view",
                data={
                    "setting_type": "accessibility",
                    "settings": settings
                },
                text_response={
                    "text": "접근성 설정을 조회했습니다.",
                    "display_automatically": True
                },
                ui_instructions={
                    "screen": "settings",
                    "show_settings": True,
                    "highlight_accessibility": True
                }
            )
        else:
            return create_error_action_response(
                result.get('error', '접근성 설정 조회 중 오류가 발생했습니다'),
                "accessibility_retrieval_error"
            )
        
    except Exception as e:
        logger.error(f"Accessibility settings retrieval failed: {e}")
        return create_error_action_response("접근성 설정 조회 중 오류가 발생했습니다", "accessibility_retrieval_error")

def setup_routes(app):
    """라우트 설정"""
    app.register_blueprint(api_bp, url_prefix='/api/v1')
    
    # 에러 핸들러 등록
    @app.errorhandler(404)
    def not_found(error):
        return create_error_response("요청한 엔드포인트를 찾을 수 없습니다", 404)
    
    @app.errorhandler(405)
    def method_not_allowed(error):
        return create_error_response("허용되지 않는 HTTP 메서드입니다", 405)
    
    @app.errorhandler(500)
    def internal_error(error):
        return create_error_response("서버 내부 오류가 발생했습니다", 500) 