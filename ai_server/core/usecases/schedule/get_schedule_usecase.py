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
        """일정 조회 실행 (description + 시간대 + 주제+날짜 결합 검색 지원)"""
        try:
            query_type = query_info.get('type', 'all')
            
            if query_type == 'keyword' and query_info.get('keyword'):
                # 키워드 기반 검색 (title + description + category에서 검색)
                keyword = query_info['keyword']
                schedules = self.schedule_repository.find_by_user_and_keyword(user_id, keyword)
                self.logger.info(f"Keyword search for '{keyword}' (including description): found {len(schedules)} schedules")
                
                # 주제+날짜/시간대 결합 검색인 경우 추가 필터링
                if query_info.get('date') or query_info.get('time_period') or query_info.get('time'):
                    schedules = self._filter_schedules_by_time(schedules, query_info)
                    self.logger.info(f"After time filtering: found {len(schedules)} schedules")
                    
            elif query_type == 'important':
                schedules = self.schedule_repository.find_important_by_user(user_id)
            elif query_type == 'date' and query_info.get('date'):
                target_date = datetime.fromisoformat(query_info['date']).date()
                schedules = self.schedule_repository.find_by_user_and_date(user_id, target_date)
            elif query_type == 'time':
                # 시간대 기반 검색
                schedules = self._find_schedules_by_time(user_id, query_info)
            else:
                schedules = self.schedule_repository.find_by_user_id(user_id)
            
            # 활성 일정만 필터링
            active_schedules = [s for s in schedules if s.is_active()]
            
            self.logger.info(f"Found {len(active_schedules)} schedules for user {user_id}")
            return GetScheduleResult(True, active_schedules, len(active_schedules))
            
        except Exception as e:
            self.logger.error(f"Get schedule failed: {e}")
            return GetScheduleResult(False, [], 0, str(e))
    
    def _filter_schedules_by_time(self, schedules: List[Schedule], query_info: Dict[str, Any]) -> List[Schedule]:
        """기존 일정 목록에서 시간대 필터링"""
        try:
            filtered_schedules = []
            
            time_period = query_info.get('time_period')
            specific_time = query_info.get('time')
            target_date = None
            
            # 날짜 정보가 있는 경우
            if query_info.get('date'):
                target_date = datetime.fromisoformat(query_info['date']).date()
            
            for schedule in schedules:
                if not schedule.start_datetime:
                    continue
                
                # 날짜 필터링
                if target_date and schedule.start_datetime.date() != target_date:
                    continue
                
                # 시간대 필터링
                hour = schedule.start_datetime.hour
                
                if time_period:
                    if time_period == 'morning' and 6 <= hour < 12:
                        filtered_schedules.append(schedule)
                    elif time_period == 'afternoon' and 12 <= hour < 18:
                        filtered_schedules.append(schedule)
                    elif time_period == 'evening' and 18 <= hour < 22:
                        filtered_schedules.append(schedule)
                    elif time_period == 'night' and (hour >= 22 or hour < 6):
                        filtered_schedules.append(schedule)
                
                elif specific_time:
                    # 구체적 시간 검색 (30분 범위)
                    target_hour, target_minute = map(int, specific_time.split(':'))
                    target_datetime = schedule.start_datetime.replace(hour=target_hour, minute=target_minute)
                    
                    # 30분 범위 내 일정 찾기
                    time_diff = abs((schedule.start_datetime - target_datetime).total_seconds() / 60)
                    if time_diff <= 30:
                        filtered_schedules.append(schedule)
                
                else:
                    # 시간 필터가 없는 경우 모든 일정 포함
                    filtered_schedules.append(schedule)
            
            return filtered_schedules
            
        except Exception as e:
            self.logger.error(f"Filter schedules by time failed: {e}")
            return schedules
    
    def _find_schedules_by_time(self, user_id: str, query_info: Dict[str, Any]) -> List[Schedule]:
        """시간대 기반 일정 검색"""
        try:
            # 모든 일정 조회
            all_schedules = self.schedule_repository.find_by_user_id(user_id)
            filtered_schedules = []
            
            time_period = query_info.get('time_period')
            specific_time = query_info.get('time')
            target_date = None
            
            # 날짜 정보가 있는 경우
            if query_info.get('date'):
                target_date = datetime.fromisoformat(query_info['date']).date()
            
            for schedule in all_schedules:
                if not schedule.start_datetime:
                    continue
                
                # 날짜 필터링
                if target_date and schedule.start_datetime.date() != target_date:
                    continue
                
                # 시간대 필터링
                hour = schedule.start_datetime.hour
                
                if time_period:
                    if time_period == 'morning' and 6 <= hour < 12:
                        filtered_schedules.append(schedule)
                    elif time_period == 'afternoon' and 12 <= hour < 18:
                        filtered_schedules.append(schedule)
                    elif time_period == 'evening' and 18 <= hour < 22:
                        filtered_schedules.append(schedule)
                    elif time_period == 'night' and (hour >= 22 or hour < 6):
                        filtered_schedules.append(schedule)
                
                elif specific_time:
                    # 구체적 시간 검색 (30분 범위)
                    target_hour, target_minute = map(int, specific_time.split(':'))
                    target_datetime = schedule.start_datetime.replace(hour=target_hour, minute=target_minute)
                    
                    # 30분 범위 내 일정 찾기
                    time_diff = abs((schedule.start_datetime - target_datetime).total_seconds() / 60)
                    if time_diff <= 30:
                        filtered_schedules.append(schedule)
            
            self.logger.info(f"Time-based search: found {len(filtered_schedules)} schedules")
            return filtered_schedules
            
        except Exception as e:
            self.logger.error(f"Time-based search failed: {e}")
            return []
