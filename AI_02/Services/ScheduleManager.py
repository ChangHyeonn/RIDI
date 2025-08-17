#!/usr/bin/env python3
"""
Schedule Manager
일정 관리 전담 클래스
"""

import logging
from datetime import datetime, date
from typing import Dict, List, Any, Optional
from collections import defaultdict

class ScheduleManager:
    """일정 관리 전담 클래스"""
    
    def __init__(self):
        from Config.settings import Settings
        from Repositories.schedule_repository import (
            InMemoryScheduleRepository,
            MongoDBScheduleRepository,
            BaseScheduleRepository,
        )

        self.schedules = defaultdict(list)  # legacy in-memory cache
        self.user_settings = defaultdict(dict)  # user_id -> settings
        self._setup_logging()
        
        # Repository 선택
        db_engine = getattr(Settings, 'DB_ENGINE', 'inmemory')
        
        if db_engine == 'mongodb':
            self.repo: BaseScheduleRepository = MongoDBScheduleRepository(
                connection_string=Settings.MONGO_URI,
                db_name=Settings.MONGO_DB,
            )
        else:
            self.repo = InMemoryScheduleRepository()
    
    def _setup_logging(self):
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
    
    def add_schedule(self, user_id: str, schedule_data: Dict[str, Any]) -> Dict[str, Any]:
        """일정 추가 (Repository 위임)"""
        try:
            result = self.repo.add_schedule(user_id, schedule_data)
            return result
        except Exception as e:
            self.logger.error(f"Failed to add schedule: {e}")
            return {"success": False, "error": f"일정 추가 중 오류가 발생했습니다: {str(e)}"}
    
    def delete_schedule(self, user_id: str, schedule_id: str) -> Dict[str, Any]:
        """일정 삭제 (Repository 위임)"""
        try:
            return self.repo.delete_schedule(user_id, schedule_id)
        except Exception as e:
            self.logger.error(f"Failed to delete schedule: {e}")
            return {"success": False, "error": f"일정 삭제 중 오류가 발생했습니다: {str(e)}"}
    
    def get_schedules(self, user_id: str) -> List[Dict[str, Any]]:
        """전체 일정 조회"""
        try:
            # Repository에 전체 목록 API가 없으므로 기존 캐시 반환 (선택사항)
            schedules = self.schedules[user_id]
            schedules.sort(key=lambda x: x.get('created_at', ''), reverse=True)
            return schedules
        except Exception as e:
            self.logger.error(f"Failed to get schedules: {e}")
            return []
    
    def get_schedules_by_date(self, user_id: str, target_date: str) -> List[Dict[str, Any]]:
        """특정 날짜 일정 조회 (Repository 위임)"""
        try:
            return self.repo.get_schedules_by_date(user_id, target_date)
        except Exception as e:
            self.logger.error(f"Failed to get schedules by date: {e}")
            return []

    def find_schedules(self, user_id: str, title: Optional[str] = None,
                       date: Optional[str] = None, time: Optional[str] = None) -> List[Dict[str, Any]]:
        """제목/날짜/시간으로 후보 일정 검색 (Repository 위임)"""
        try:
            return self.repo.find_schedules(user_id, title=title, date_str=date, time_str=time)
        except Exception as e:
            self.logger.error(f"Failed to find schedules: {e}")
            return []
    
    def get_important_schedules(self, user_id: str) -> List[Dict[str, Any]]:
        """중요 일정 조회"""
        try:
            user_schedules = self.schedules[user_id]
            important_schedules = []
            
            for schedule in user_schedules:
                schedule_data = schedule.get('data', {})
                is_important = schedule_data.get('is_important', False)
                
                if is_important:
                    important_schedules.append(schedule)
            
            # 최신순으로 정렬
            important_schedules.sort(key=lambda x: x.get('created_at', ''), reverse=True)
            return important_schedules
            
        except Exception as e:
            self.logger.error(f"Failed to get important schedules: {e}")
            return []
    
    def get_today_schedules(self, user_id: str) -> List[Dict[str, Any]]:
        """오늘 일정 조회"""
        today = date.today().strftime("%Y-%m-%d")
        return self.get_schedules_by_date(user_id, today)
    
    def update_user_settings(self, user_id: str, settings: Dict[str, Any]) -> Dict[str, Any]:
        """사용자 설정 업데이트"""
        try:
            self.user_settings[user_id].update(settings)
            
            self.logger.info(f"User settings updated for {user_id}")
            
            return {
                "success": True,
                "message": "설정이 업데이트되었습니다.",
                "settings": self.user_settings[user_id]
            }
            
        except Exception as e:
            self.logger.error(f"Failed to update user settings: {e}")
            return {
                "success": False,
                "error": f"설정 업데이트 중 오류가 발생했습니다: {str(e)}"
            }
    
    def get_user_settings(self, user_id: str) -> Dict[str, Any]:
        """사용자 설정 조회"""
        return self.user_settings[user_id]
    
    def get_schedule_info(self) -> Dict[str, Any]:
        """일정 관리 정보"""
        total_users = len(self.schedules)
        total_schedules = sum(len(schedules) for schedules in self.schedules.values())
        
        return {
            "total_users": total_users,
            "total_schedules": total_schedules,
            "memory_usage": len(self.schedules) + len(self.user_settings)
        }