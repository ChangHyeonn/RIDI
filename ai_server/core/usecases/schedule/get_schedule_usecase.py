#!/usr/bin/env python3
"""
Get Schedule Use Case
일정 조회 Use Case
"""

from dataclasses import dataclass
from datetime import datetime, date
from typing import Dict, Any, List

from shared.logging.logger import LoggerFactory
from core.entities.schedule import Schedule
from core.interfaces.repositories.schedule_repository import IScheduleRepository


@dataclass
class GetScheduleResult:
    """일정 조회 결과"""
    success: bool
    schedules: List[Schedule]
    total_count: int
    error_message: str = None


class GetScheduleUseCase:
    """일정 조회 Use Case"""
    
    def __init__(self, schedule_repository: IScheduleRepository):
        self.schedule_repository = schedule_repository
        self.logger = LoggerFactory.get_logger(__name__)
    
    def execute(self, user_id: str, query_info: Dict[str, Any]) -> GetScheduleResult:
        """일정 조회 실행"""
        try:
            query_type = query_info.get('type', 'all')
            
            if query_type == 'keyword' and query_info.get('keyword'):
                # 키워드 기반 검색
                keyword = query_info['keyword']
                schedules = self.schedule_repository.find_by_user_and_keyword(user_id, keyword)
                self.logger.info(f"Keyword search for '{keyword}': found {len(schedules)} schedules")
            elif query_type == 'important':
                schedules = self.schedule_repository.find_important_by_user(user_id)
            elif query_type == 'date' and query_info.get('date'):
                target_date = datetime.fromisoformat(query_info['date']).date()
                schedules = self.schedule_repository.find_by_user_and_date(user_id, target_date)
            else:
                schedules = self.schedule_repository.find_by_user_id(user_id)
            
            # 활성 일정만 필터링
            active_schedules = [s for s in schedules if s.is_active()]
            
            self.logger.info(f"Found {len(active_schedules)} schedules for user {user_id}")
            return GetScheduleResult(True, active_schedules, len(active_schedules))
            
        except Exception as e:
            self.logger.error(f"Get schedule failed: {e}")
            return GetScheduleResult(False, [], 0, str(e))
