#!/usr/bin/env python3
"""
In-Memory Schedule Repository Implementation
메모리 일정 저장소 구현 (어댑터)
"""

from typing import List, Optional, Dict
from datetime import date, datetime
import uuid
from collections import defaultdict

from shared.logging.logger import LoggerFactory
from core.entities.schedule import Schedule
from core.interfaces.repositories.schedule_repository import IScheduleRepository


class MemoryScheduleRepository(IScheduleRepository):
    """메모리 기반 일정 저장소 구현 (개발/테스트용)"""
    
    def __init__(self):
        self.logger = LoggerFactory.get_logger(__name__)
        self._schedules: Dict[str, Schedule] = {}  # schedule_id -> Schedule
        self._user_schedules: Dict[str, List[str]] = defaultdict(list)  # user_id -> [schedule_ids]
    
    def save(self, schedule: Schedule) -> Schedule:
        """일정 저장"""
        try:
            # 새 일정인 경우 ID 생성
            if schedule.id is None:
                schedule.id = str(uuid.uuid4())
            
            # 저장
            self._schedules[schedule.id] = schedule
            
            # 사용자별 인덱스 업데이트
            if schedule.id not in self._user_schedules[schedule.user_id]:
                self._user_schedules[schedule.user_id].append(schedule.id)
            
            self.logger.info(f"Schedule saved in memory: {schedule.title}")
            return schedule
            
        except Exception as e:
            self.logger.error(f"Failed to save schedule: {e}")
            raise
    
    def find_by_id(self, schedule_id: str) -> Optional[Schedule]:
        """ID로 일정 조회"""
        return self._schedules.get(schedule_id)
    
    def find_by_user_id(self, user_id: str) -> List[Schedule]:
        """사용자별 일정 조회"""
        try:
            schedule_ids = self._user_schedules.get(user_id, [])
            schedules = []
            
            for schedule_id in schedule_ids:
                schedule = self._schedules.get(schedule_id)
                if schedule and schedule.is_active():
                    schedules.append(schedule)
            
            # 날짜순 정렬
            schedules.sort(key=lambda s: s.start_datetime)
            return schedules
            
        except Exception as e:
            self.logger.error(f"Failed to find schedules by user: {e}")
            return []
    
    def find_by_user_and_date(self, user_id: str, target_date: date) -> List[Schedule]:
        """사용자별 특정 날짜 일정 조회"""
        try:
            user_schedules = self.find_by_user_id(user_id)
            date_schedules = []
            
            for schedule in user_schedules:
                if schedule.start_datetime.date() == target_date:
                    date_schedules.append(schedule)
            
            # 시간순 정렬
            date_schedules.sort(key=lambda s: s.start_datetime)
            return date_schedules
            
        except Exception as e:
            self.logger.error(f"Failed to find schedules by date: {e}")
            return []
    
    def find_important_by_user(self, user_id: str) -> List[Schedule]:
        """사용자별 중요 일정 조회"""
        try:
            user_schedules = self.find_by_user_id(user_id)
            important_schedules = []
            
            for schedule in user_schedules:
                if schedule.is_important:
                    important_schedules.append(schedule)
            
            # 날짜순 정렬
            important_schedules.sort(key=lambda s: s.start_datetime)
            return important_schedules
            
        except Exception as e:
            self.logger.error(f"Failed to find important schedules: {e}")
            return []
    
    def find_by_user_and_keyword(self, user_id: str, keyword: str) -> List[Schedule]:
        """사용자별 키워드로 일정 검색"""
        try:
            user_schedules = self.find_by_user_id(user_id)
            keyword_schedules = []
            
            # 키워드 정규화 (소문자 변환)
            normalized_keyword = keyword.lower().strip()
            
            for schedule in user_schedules:
                # 제목에서 키워드 검색
                if normalized_keyword in schedule.title.lower():
                    keyword_schedules.append(schedule)
                    continue
                
                # 설명에서 키워드 검색
                if schedule.description and normalized_keyword in schedule.description.lower():
                    keyword_schedules.append(schedule)
                    continue
                
                # 카테고리에서 키워드 검색
                if schedule.category and normalized_keyword in schedule.category.lower():
                    keyword_schedules.append(schedule)
                    continue
            
            # 날짜순 정렬
            keyword_schedules.sort(key=lambda s: s.start_datetime)
            
            self.logger.info(f"Found {len(keyword_schedules)} schedules for keyword '{keyword}'")
            return keyword_schedules
            
        except Exception as e:
            self.logger.error(f"Failed to find schedules by keyword: {e}")
            return []
    
    def update(self, schedule: Schedule) -> Schedule:
        """일정 수정"""
        schedule.updated_at = datetime.now()
        return self.save(schedule)
    
    def delete(self, schedule_id: str) -> bool:
        """일정 삭제"""
        try:
            schedule = self._schedules.get(schedule_id)
            if not schedule:
                return False
            
            # 일정 삭제
            del self._schedules[schedule_id]
            
            # 사용자별 인덱스에서 제거
            user_schedule_ids = self._user_schedules.get(schedule.user_id, [])
            if schedule_id in user_schedule_ids:
                user_schedule_ids.remove(schedule_id)
            
            self.logger.info(f"Schedule deleted from memory: {schedule_id}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to delete schedule: {e}")
            return False
    
    def delete_by_user_and_title(self, user_id: str, title: str) -> bool:
        """사용자별 제목으로 일정 삭제"""
        try:
            user_schedules = self.find_by_user_id(user_id)
            
            for schedule in user_schedules:
                if title.lower() in schedule.title.lower():
                    return self.delete(schedule.id)
            
            return False
            
        except Exception as e:
            self.logger.error(f"Failed to delete schedule by title: {e}")
            return False
    
    def clear_all(self):
        """모든 데이터 삭제 (테스트용)"""
        self._schedules.clear()
        self._user_schedules.clear()
        self.logger.info("All schedules cleared from memory")
    
    def get_stats(self) -> Dict[str, int]:
        """저장소 통계 (개발용)"""
        return {
            'total_schedules': len(self._schedules),
            'total_users': len(self._user_schedules),
            'active_schedules': len([s for s in self._schedules.values() if s.is_active()])
        }
