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
        self.schedules = defaultdict(list)  # user_id -> schedules
        self.user_settings = defaultdict(dict)  # user_id -> settings
        self._setup_logging()
    
    def _setup_logging(self):
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
    
    def add_schedule(self, user_id: str, schedule_data: Dict[str, Any]) -> Dict[str, Any]:
        """일정 추가"""
        try:
            schedule_id = f"schedule_{datetime.now().timestamp()}"
            schedule = {
                'id': schedule_id,
                'user_id': user_id,
                'data': schedule_data,
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat()
            }
            
            self.schedules[user_id].append(schedule)
            
            # 최대 일정 수 제한
            if len(self.schedules[user_id]) > 100:
                self.schedules[user_id] = self.schedules[user_id][-100:]
            
            self.logger.info(f"Schedule added for user {user_id}: {schedule_id}")
            
            return {
                "success": True,
                "schedule_id": schedule_id,
                "message": "일정이 성공적으로 추가되었습니다.",
                "schedule": schedule_data
            }
            
        except Exception as e:
            self.logger.error(f"Failed to add schedule: {e}")
            return {
                "success": False,
                "error": f"일정 추가 중 오류가 발생했습니다: {str(e)}"
            }
    
    def delete_schedule(self, user_id: str, schedule_id: str) -> Dict[str, Any]:
        """일정 삭제"""
        try:
            user_schedules = self.schedules[user_id]
            
            # 일정 찾기
            schedule_to_delete = None
            for schedule in user_schedules:
                if schedule['id'] == schedule_id:
                    schedule_to_delete = schedule
                    break
            
            if not schedule_to_delete:
                return {
                    "success": False,
                    "error": "해당 일정을 찾을 수 없습니다."
                }
            
            # 일정 삭제
            user_schedules.remove(schedule_to_delete)
            
            self.logger.info(f"Schedule deleted for user {user_id}: {schedule_id}")
            
            return {
                "success": True,
                "message": "일정이 성공적으로 삭제되었습니다.",
                "deleted_schedule": schedule_to_delete['data']
            }
            
        except Exception as e:
            self.logger.error(f"Failed to delete schedule: {e}")
            return {
                "success": False,
                "error": f"일정 삭제 중 오류가 발생했습니다: {str(e)}"
            }
    
    def get_schedules(self, user_id: str) -> List[Dict[str, Any]]:
        """전체 일정 조회"""
        try:
            schedules = self.schedules[user_id]
            # 최신순으로 정렬
            schedules.sort(key=lambda x: x.get('created_at', ''), reverse=True)
            return schedules
        except Exception as e:
            self.logger.error(f"Failed to get schedules: {e}")
            return []
    
    def get_schedules_by_date(self, user_id: str, target_date: str) -> List[Dict[str, Any]]:
        """특정 날짜 일정 조회"""
        try:
            target_date_obj = datetime.strptime(target_date, "%Y-%m-%d").date()
            user_schedules = self.schedules[user_id]
            
            date_schedules = []
            for schedule in user_schedules:
                schedule_data = schedule.get('data', {})
                schedule_datetime = schedule_data.get('datetime')
                
                if schedule_datetime:
                    try:
                        schedule_date = datetime.strptime(schedule_datetime, "%Y-%m-%d %H:%M").date()
                        if schedule_date == target_date_obj:
                            date_schedules.append(schedule)
                    except ValueError:
                        continue
            
            return date_schedules
            
        except Exception as e:
            self.logger.error(f"Failed to get schedules by date: {e}")
            return []
    
    def get_important_schedules(self, user_id: str) -> List[Dict[str, Any]]:
        """중요 일정 조회"""
        try:
            user_schedules = self.schedules[user_id]
            important_schedules = []
            
            for schedule in user_schedules:
                schedule_data = schedule.get('data', {})
                priority = schedule_data.get('priority', 'not_important')
                
                if priority == 'important':
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