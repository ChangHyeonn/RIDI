#!/usr/bin/env python3
"""
Schedule Synchronization Controller
일정 동기화 API 컨트롤러 (Clean Architecture)
"""

from flask import Blueprint, request, jsonify
from datetime import datetime
from shared.logging.logger import LoggerFactory

# Blueprint 생성
sync_bp = Blueprint('sync', __name__)
logger = LoggerFactory.get_logger(__name__)

# Use Case 인스턴스 (런타임에 초기화)
schedule_repository = None
get_schedule_usecase = None
add_schedule_usecase = None
delete_schedule_usecase = None


def initialize_usecases():
    """의존성 컨테이너에서 Use Case 초기화"""
    global schedule_repository, get_schedule_usecase, add_schedule_usecase, delete_schedule_usecase
    from shared.container import container
    from core.interfaces.repositories.schedule_repository import IScheduleRepository
    from core.usecases.schedule.get_schedule_usecase import GetScheduleUseCase
    from core.usecases.schedule.add_schedule_usecase import AddScheduleUseCase
    from core.usecases.schedule.delete_schedule_usecase import DeleteScheduleUseCase
    
    schedule_repository = container.get(IScheduleRepository)
    get_schedule_usecase = GetScheduleUseCase(schedule_repository)
    add_schedule_usecase = AddScheduleUseCase(schedule_repository)
    delete_schedule_usecase = DeleteScheduleUseCase(schedule_repository)


@sync_bp.route('/schedules/<user_id>', methods=['GET'])
def get_schedules(user_id: str):
    """사용자의 모든 일정 조회"""
    try:
        if get_schedule_usecase is None:
            initialize_usecases()
        
        logger.info(f"Get schedules request: user_id={user_id}")
        
        result = get_schedule_usecase.execute(user_id)
        
        if not result.success:
            return jsonify({
                'success': False,
                'error': result.error_message or '일정 조회 실패'
            }), 500
        
        # 일정 데이터 변환
        schedules_data = []
        for schedule in result.schedules:
            schedule_data = {
                'id': schedule.id,
                'title': schedule.title,
                'start_datetime': schedule.start_datetime.isoformat(),
                'category': schedule.category,
                'is_important': schedule.is_important,
                'location': schedule.location,
                'description': schedule.description,
                'is_recurring': schedule.is_recurring
            }
            
            # 반복 일정 정보 추가
            if schedule.is_recurring and schedule.recurrence_pattern:
                schedule_data['recurrence'] = {
                    'type': schedule.recurrence_pattern.type,
                    'times': [{
                        'time': rt.time,
                        'label': rt.label
                    } for rt in schedule.recurrence_pattern.times],
                    'end_date': schedule.recurrence_pattern.end_date,
                    'days_of_week': schedule.recurrence_pattern.days_of_week
                }
            
            schedules_data.append(schedule_data)
        
        return jsonify({
            'success': True,
            'schedules': schedules_data,
            'total_count': result.total_count,
            'sync_timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Get schedules failed: {e}")
        return jsonify({
            'success': False,
            'error': f'일정 조회 실패: {str(e)}'
        }), 500


@sync_bp.route('/schedules/<user_id>/since/<since_timestamp>', methods=['GET'])
def get_schedules_since(user_id: str, since_timestamp: str):
    """특정 시간 이후의 일정 조회 (증분 동기화용)"""
    try:
        if get_schedule_usecase is None:
            initialize_usecases()
        
        logger.info(f"Get schedules since request: user_id={user_id}, since={since_timestamp}")
        
        # 타임스탬프 파싱
        try:
            since_datetime = datetime.fromisoformat(since_timestamp.replace('Z', '+00:00'))
        except ValueError as e:
            logger.error(f"Invalid timestamp format: {since_timestamp}")
            return jsonify({
                'success': False,
                'error': '잘못된 타임스탬프 형식입니다'
            }), 400
        
        result = get_schedule_usecase.execute(user_id, since_datetime)
        
        if not result.success:
            return jsonify({
                'success': False,
                'error': result.error_message or '일정 조회 실패'
            }), 500
        
        # 일정 데이터 변환
        schedules_data = []
        for schedule in result.schedules:
            schedule_data = {
                'id': schedule.id,
                'title': schedule.title,
                'start_datetime': schedule.start_datetime.isoformat(),
                'category': schedule.category,
                'is_important': schedule.is_important,
                'location': schedule.location,
                'description': schedule.description,
                'is_recurring': schedule.is_recurring
            }
            
            # 반복 일정 정보 추가
            if schedule.is_recurring and schedule.recurrence_pattern:
                schedule_data['recurrence'] = {
                    'type': schedule.recurrence_pattern.type,
                    'times': [{
                        'time': rt.time,
                        'label': rt.label
                    } for rt in schedule.recurrence_pattern.times],
                    'end_date': schedule.recurrence_pattern.end_date,
                    'days_of_week': schedule.recurrence_pattern.days_of_week
                }
            
            schedules_data.append(schedule_data)
        
        return jsonify({
            'success': True,
            'schedules': schedules_data,
            'total_count': result.total_count,
            'sync_timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Get schedules since failed: {e}")
        return jsonify({
            'success': False,
            'error': f'일정 조회 실패: {str(e)}'
        }), 500


@sync_bp.route('/schedules', methods=['POST'])
def add_schedule():
    """일정 추가"""
    try:
        # Use Case 초기화 확인
        if add_schedule_usecase is None:
            initialize_usecases()
        
        data = request.get_json()
        if not data:
            return jsonify({
                'success': False,
                'error': '요청 데이터가 없습니다'
            }), 400
        
        user_id = data.get('user_id')
        schedule_info = data.get('schedule_info')
        
        if not user_id or not schedule_info:
            return jsonify({
                'success': False,
                'error': '사용자 ID와 일정 정보가 필요합니다'
            }), 400
        
        logger.info(f"Add schedule request: user_id={user_id}, schedule_info={schedule_info}")
        
        result = add_schedule_usecase.execute(user_id, schedule_info)
        
        if not result.success:
            return jsonify({
                'success': False,
                'error': result.error_message or '일정 추가 실패'
            }), 500
        
        return jsonify({
            'success': True,
            'schedule': result.schedule_data
        }), 201
        
    except Exception as e:
        logger.error(f"Add schedule failed: {e}")
        return jsonify({
            'success': False,
            'error': f'일정 추가 실패: {str(e)}'
        }), 500


@sync_bp.route('/delete_schedule/<schedule_id>', methods=['DELETE'])
def delete_schedule(schedule_id: str):
    """일정 삭제"""
    try:
        # Use Case 초기화 확인
        if delete_schedule_usecase is None:
            initialize_usecases()
        
        user_id = request.args.get('user_id')
        if not user_id:
            return jsonify({
                'success': False,
                'error': '사용자 ID가 필요합니다'
            }), 400
        
        logger.info(f"Delete schedule request: user_id={user_id}, schedule_id={schedule_id}")
        
        result = delete_schedule_usecase.execute(user_id, schedule_id)
        
        if not result.success:
            return jsonify({
                'success': False,
                'error': result.error_message or '일정 삭제 실패'
            }), 500
        
        return jsonify({
            'success': True,
            'deleted_title': result.deleted_title
        })
        
    except Exception as e:
        logger.error(f"Delete schedule failed: {e}")
        return jsonify({
            'success': False,
            'error': f'일정 삭제 실패: {str(e)}'
        }), 500
