#!/usr/bin/env python3
"""
API Routes for AI Server
고령층 일정 메모 관리 AI 서버 API 라우트
"""

import sys
import os
import tempfile
import logging

# 프로젝트 루트를 Python 경로에 추가
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from flask import Blueprint, request, jsonify, current_app
from datetime import datetime
from Server.utils.response_utils import create_response, create_error_response
from Server.utils.validation import validate_audio_file, validate_schedule_data, validate_accessibility_settings
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
        return create_response(health_info)
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return create_error_response("서버 상태 확인 중 오류가 발생했습니다", 500)

@api_bp.route('/process_voice', methods=['POST'])
def process_voice():
    """음성 명령 처리 API"""
    try:
        # 입력 검증
        if 'audio' not in request.files:
            return create_error_response("오디오 파일이 제공되지 않았습니다", 400)
        
        audio_file = request.files['audio']
        user_id = request.form.get('user_id', 'default_user')
        
        # 파일 검증
        validation_result = validate_audio_file(audio_file)
        if not validation_result['valid']:
            return create_error_response(validation_result['error'], 400)
        
        # 임시 파일 생성
        with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as tmp_file:
            audio_file.save(tmp_file.name)
            audio_path = tmp_file.name
        
        try:
            # AI 처리
            result = current_app.ai_service.process_voice_command(audio_path, user_id)
            return create_response(result)
        finally:
            # 임시 파일 정리
            if os.path.exists(audio_path):
                os.unlink(audio_path)
                
    except Exception as e:
        logger.error(f"Voice processing failed: {e}")
        return create_error_response("음성 처리 중 오류가 발생했습니다", 500)

@api_bp.route('/schedule/add', methods=['POST'])
def add_schedule():
    """일정 추가 API"""
    try:
        data = request.get_json()
        if not data:
            return create_error_response("일정 데이터가 제공되지 않았습니다", 400)
        
        user_id = request.headers.get('X-User-ID', 'default_user')
        
        # 데이터 검증
        validation_result = validate_schedule_data(data)
        if not validation_result['valid']:
            return create_error_response(validation_result['error'], 400)
        
        result = current_app.ai_service.add_schedule(data, user_id)
        return create_response(result)
        
    except Exception as e:
        logger.error(f"Schedule addition failed: {e}")
        return create_error_response("일정 추가 중 오류가 발생했습니다", 500)

@api_bp.route('/schedule/list', methods=['GET'])
def list_schedules():
    """일정 목록 조회 API"""
    try:
        user_id = request.args.get('user_id', 'default_user')
        result = current_app.ai_service.get_schedules(user_id)
        return create_response(result)
        
    except Exception as e:
        logger.error(f"Schedule list retrieval failed: {e}")
        return create_error_response("일정 목록 조회 중 오류가 발생했습니다", 500)

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
        "version": "1.0.0"
    })

@api_bp.route('/elderly/simple_response', methods=['POST'])
def get_simple_response():
    """고령자용 간단 응답 API"""
    try:
        data = request.get_json()
        if not data or 'message' not in data:
            return create_error_response("메시지가 제공되지 않았습니다", 400)
        
        message = data['message']
        
        # 간단한 응답 생성
        simple_response = current_app.ai_service._simplify_response_for_elderly({
            'ai_response': message
        })
        
        return create_response({
            "original_message": message,
            "simple_response": simple_response.get('ai_response', message)
        })
        
    except Exception as e:
        logger.error(f"Simple response generation failed: {e}")
        return create_error_response("간단 응답 생성 중 오류가 발생했습니다", 500)

@api_bp.route('/elderly/repeat_important', methods=['POST'])
def repeat_important_message():
    """중요 메시지 반복 API"""
    try:
        data = request.get_json()
        if not data or 'message' not in data:
            return create_error_response("메시지가 제공되지 않았습니다", 400)
        
        message = data['message']
        repeat_count = data.get('repeat_count', 2)
        
        # 중요 메시지 반복
        repeated_message = f"{message} " * repeat_count
        
        return create_response({
            "original_message": message,
            "repeated_message": repeated_message.strip(),
            "repeat_count": repeat_count
        })
        
    except Exception as e:
        logger.error(f"Message repetition failed: {e}")
        return create_error_response("메시지 반복 중 오류가 발생했습니다", 500)

@api_bp.route('/schedule/delete', methods=['DELETE'])
def delete_schedule():
    """일정 삭제 API"""
    try:
        data = request.get_json()
        if not data:
            return create_error_response("삭제할 일정 정보가 제공되지 않았습니다", 400)
        
        user_id = request.headers.get('X-User-ID', 'default_user')
        schedule_id = data.get('schedule_id')
        
        if not schedule_id:
            return create_error_response("일정 ID가 필요합니다", 400)
        
        result = current_app.ai_service.delete_schedule(user_id, schedule_id)
        return create_response(result)
        
    except Exception as e:
        logger.error(f"Schedule deletion failed: {e}")
        return create_error_response("일정 삭제 중 오류가 발생했습니다", 500)

@api_bp.route('/schedule/read', methods=['GET'])
def read_schedules_by_date():
    """특정 날짜 일정 조회 API"""
    try:
        user_id = request.args.get('user_id', 'default_user')
        target_date = request.args.get('date', 'today')
        
        result = current_app.ai_service.get_schedules_by_date(user_id, target_date)
        return create_response(result)
        
    except Exception as e:
        logger.error(f"Schedule reading failed: {e}")
        return create_error_response("일정 조회 중 오류가 발생했습니다", 500)

@api_bp.route('/schedule/important', methods=['GET'])
def get_important_schedules():
    """중요 일정 조회 API"""
    try:
        user_id = request.args.get('user_id', 'default_user')
        result = current_app.ai_service.get_important_schedules(user_id)
        return create_response(result)
        
    except Exception as e:
        logger.error(f"Important schedule retrieval failed: {e}")
        return create_error_response("중요 일정 조회 중 오류가 발생했습니다", 500)

@api_bp.route('/settings/accessibility', methods=['PUT'])
def update_accessibility_settings():
    """접근성 설정 업데이트 API"""
    try:
        data = request.get_json()
        if not data:
            return create_error_response("접근성 설정 데이터가 제공되지 않았습니다", 400)
        
        user_id = request.headers.get('X-User-ID', 'default_user')
        
        # 설정 검증
        validation_result = validate_accessibility_settings(data)
        if not validation_result['valid']:
            return create_error_response(validation_result['error'], 400)
        
        result = current_app.ai_service.update_accessibility_settings(user_id, data)
        return create_response(result)
        
    except Exception as e:
        logger.error(f"Accessibility settings update failed: {e}")
        return create_error_response("접근성 설정 업데이트 중 오류가 발생했습니다", 500)

@api_bp.route('/settings/accessibility', methods=['GET'])
def get_accessibility_settings():
    """접근성 설정 조회 API"""
    try:
        user_id = request.args.get('user_id', 'default_user')
        result = current_app.ai_service.get_accessibility_settings(user_id)
        return create_response(result)
        
    except Exception as e:
        logger.error(f"Accessibility settings retrieval failed: {e}")
        return create_error_response("접근성 설정 조회 중 오류가 발생했습니다", 500)

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
    def internal_error(error):
        return create_error_response("서버 내부 오류가 발생했습니다", 500) 