#!/usr/bin/env python3
"""
Sync Controller
<<<<<<< HEAD
동기화 API 컨트롤러 (기존 시스템과 분리)
"""

from flask import Blueprint, request, jsonify
from datetime import datetime, timedelta
import time
=======
동기화 컨트롤러
"""

from flask import Blueprint, request, jsonify
from datetime import datetime
from typing import Dict, Any
>>>>>>> app_ai

from shared.logging.logger import LoggerFactory
from core.usecases.schedule.get_schedule_usecase import GetScheduleUseCase
from core.usecases.schedule.add_schedule_usecase import AddScheduleUseCase
from core.usecases.schedule.delete_schedule_usecase import DeleteScheduleUseCase
<<<<<<< HEAD

sync_bp = Blueprint('sync', __name__)
logger = LoggerFactory.get_logger(__name__)

class SyncController:
    """동기화 API 컨트롤러"""
    
    def __init__(self, 
                 get_schedule_usecase: GetScheduleUseCase,
                 add_schedule_usecase: AddScheduleUseCase,
                 delete_schedule_usecase: DeleteScheduleUseCase):
        self.get_schedule_usecase = get_schedule_usecase
        self.add_schedule_usecase = add_schedule_usecase
        self.delete_schedule_usecase = delete_schedule_usecase
    
    def get_user_schedules(self, user_id: str):
        """사용자 일정 조회 (동기화용)"""
        try:
            logger.info(f"Sync get_user_schedules called for user: {user_id}")
            
            # 임시 테스트 응답 (use case 문제 해결 후 실제 구현으로 교체)
            test_schedules = [
                {
                    'id': 'test-1',
                    'title': '테스트 일정 1',
                    'date': '2025-08-24',
                    'time': '09:00',
                    'category': '일반',
                    'is_important': False,
                    'is_recurring': False,
                    'recurrence': None
                },
                {
                    'id': 'test-2', 
                    'title': '테스트 일정 2',
                    'date': '2025-08-25',
                    'time': '14:00',
                    'category': '업무',
                    'is_important': True,
                    'is_recurring': True,
                    'recurrence': {
                        'type': 'daily',
                        'times': [{'time': '14:00', 'label': '오후'}],
                        'end_date': None,
                        'days_of_week': None
                    }
                }
            ]
            
            return jsonify({
                'success': True,
                'schedules': test_schedules,
                'total_count': len(test_schedules),
                'sync_timestamp': datetime.now().isoformat(),
                'message': '테스트 일정 데이터'
            }), 200
                
        except Exception as e:
            logger.error(f"Sync get_user_schedules failed: {e}")
            return jsonify({
                'success': False,
                'error': '일정 조회 중 오류가 발생했습니다.'
            }), 500
    
    def get_schedules_since(self, user_id: str, since_timestamp: str):
        """특정 시간 이후 변경된 일정 조회 (증분 동기화)"""
        try:
            # 기존 get_schedule_usecase 활용
            result = self.get_schedule_usecase.execute(user_id, {})
            
            if result.success:
                # 타임스탬프 필터링 (간단한 구현)
                schedules = [schedule.to_dict() for schedule in result.schedules]
                
                # TODO: 실제 증분 동기화 로직 구현
                # 현재는 전체 일정 반환 (안정성 우선)
                
                return jsonify({
                    'success': True,
                    'schedules': schedules,
                    'total_count': len(schedules),
                    'sync_timestamp': datetime.now().isoformat(),
                    'since_timestamp': since_timestamp
                }), 200
            else:
                return jsonify({
                    'success': False,
                    'error': result.error_message
                }), 400
                
        except Exception as e:
            logger.error(f"Sync get_schedules_since failed: {e}")
            return jsonify({
                'success': False,
                'error': '증분 동기화 중 오류가 발생했습니다.'
            }), 500
    
    def create_schedule_from_app(self):
        """앱에서 일정 생성"""
        try:
            data = request.get_json()
            if not data:
                return jsonify({
                    'success': False,
                    'error': '요청 데이터가 없습니다.'
                }), 400
            
            user_id = data.get('user_id')
            schedule_info = data.get('schedule_info', {})
            
            if not user_id:
                return jsonify({
                    'success': False,
                    'error': '사용자 ID가 필요합니다.'
                }), 400
            
            # 기존 add_schedule_usecase 활용
            result = self.add_schedule_usecase.execute(user_id, schedule_info)
            
            if result.success:
                return jsonify({
                    'success': True,
                    'schedule': result.schedule_data,
                    'message': '일정이 성공적으로 생성되었습니다.'
                }), 201
            else:
                return jsonify({
                    'success': False,
                    'error': result.error_message
                }), 400
                
        except Exception as e:
            logger.error(f"Sync create_schedule_from_app failed: {e}")
            return jsonify({
                'success': False,
                'error': '일정 생성 중 오류가 발생했습니다.'
            }), 500

# 컨트롤러 인스턴스 (의존성 주입 필요)
sync_controller = None

def init_sync_controller(get_schedule_usecase, add_schedule_usecase, delete_schedule_usecase):
    """동기화 컨트롤러 초기화"""
    global sync_controller
    sync_controller = SyncController(get_schedule_usecase, add_schedule_usecase, delete_schedule_usecase)

# API 라우트 정의
@sync_bp.route('/sync/schedules/<user_id>', methods=['GET'])
def get_user_schedules_route(user_id):
    """사용자 일정 조회 API"""
    if sync_controller is None:
        return jsonify({'success': False, 'error': '서버 초기화 중입니다.'}), 503
    return sync_controller.get_user_schedules(user_id)

@sync_bp.route('/sync/schedules/<user_id>/since/<since_timestamp>', methods=['GET'])
def get_schedules_since_route(user_id, since_timestamp):
    """증분 동기화 API"""
    if sync_controller is None:
        return jsonify({'success': False, 'error': '서버 초기화 중입니다.'}), 503
    return sync_controller.get_schedules_since(user_id, since_timestamp)

@sync_bp.route('/sync/schedules', methods=['POST'])
def create_schedule_route():
    """앱에서 일정 생성 API"""
    if sync_controller is None:
        return jsonify({'success': False, 'error': '서버 초기화 중입니다.'}), 503
    return sync_controller.create_schedule_from_app()
=======
from infrastructure.repositories.mongodb_schedule_repository import MongoDBScheduleRepository

# Blueprint 생성
sync_bp = Blueprint('sync', __name__)

# 로거 초기화
logger = LoggerFactory.get_logger(__name__)

# Repository 및 Use Case 초기화 (런타임에 의존성 주입)
schedule_repository = None
get_schedule_usecase = None
add_schedule_usecase = None
delete_schedule_usecase = None

def initialize_usecases():
    """의존성 컨테이너에서 Use Case 초기화"""
    global schedule_repository, get_schedule_usecase, add_schedule_usecase, delete_schedule_usecase
    
    from shared.container import container
    from core.interfaces.repositories.schedule_repository import IScheduleRepository
    
    schedule_repository = container.get(IScheduleRepository)
    get_schedule_usecase = GetScheduleUseCase(schedule_repository)
    add_schedule_usecase = AddScheduleUseCase(schedule_repository)
    delete_schedule_usecase = DeleteScheduleUseCase(schedule_repository)


@sync_bp.route('/schedules/<user_id>', methods=['GET'])
def get_schedules(user_id: str):
    """사용자의 모든 일정 조회"""
    try:
        # Use Case 초기화 확인
        if get_schedule_usecase is None:
            initialize_usecases()
        
        logger.info(f"Get schedules request: user_id={user_id}")
        
        query_info = {'type': 'all'}
        result = get_schedule_usecase.execute(user_id, query_info)
        
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
                'date': schedule.start_datetime.strftime('%Y-%m-%d'),
                'time': schedule.start_datetime.strftime('%H:%M'),
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
    """특정 시간 이후의 일정 조회 (증분 동기화)"""
    try:
        # Use Case 초기화 확인
        if get_schedule_usecase is None:
            initialize_usecases()
        
        logger.info(f"Get schedules since request: user_id={user_id}, since={since_timestamp}")
        
        # since_timestamp 파싱
        try:
            since_dt = datetime.fromisoformat(since_timestamp.replace('Z', '+00:00'))
        except ValueError:
            return jsonify({
                'success': False,
                'error': '잘못된 타임스탬프 형식'
            }), 400
        
        # 현재는 모든 일정을 반환 (실제로는 since_timestamp 이후 변경된 일정만)
        query_info = {'type': 'all'}
        result = get_schedule_usecase.execute(user_id, query_info)
        
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
                'date': schedule.start_datetime.strftime('%Y-%m-%d'),
                'time': schedule.start_datetime.strftime('%H:%M'),
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
>>>>>>> app_ai
