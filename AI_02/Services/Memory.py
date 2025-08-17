#!/usr/bin/env python3
"""
Memory Management Model
고령층 일정 메모 관리 시스템
"""

import json
import logging
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
from collections import defaultdict
import os

from Config.settings import Settings

class MemoryManager:
    """고령자 메모리 관리 시스템"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self._initialize_memory()
        self.logger.info("Memory Manager initialized successfully")
    
    def _initialize_memory(self):
        """메모리 초기화"""
        # 사용자별 메모리 저장소
        self.user_memories = defaultdict(dict)
        
        # 사용자별 일정 저장소
        self.user_schedules = defaultdict(list)
        
        # 사용자별 상호작용 히스토리
        self.user_interactions = defaultdict(list)
        
        # 메모리 정리 작업 설정
        self.last_cleanup = datetime.now()
    
    def store_interaction(self, user_id: str, interaction: Dict[str, Any]):
        """사용자 상호작용 저장"""
        try:
            interaction['id'] = f"interaction_{datetime.now().timestamp()}"
            interaction['timestamp'] = datetime.now().isoformat()
            
            self.user_interactions[user_id].append(interaction)
            
            # 최대 개수 제한
            if len(self.user_interactions[user_id]) > Settings.MAX_MEMORY_ITEMS:
                self.user_interactions[user_id] = self.user_interactions[user_id][-Settings.MAX_MEMORY_ITEMS:]
            

            
        except Exception as e:
            self.logger.error(f"Failed to store interaction: {e}")
    
    def store_schedule(self, user_id: str, schedule: Dict[str, Any]):
        """일정 저장"""
        try:
            schedule['id'] = f"schedule_{datetime.now().timestamp()}"
            schedule['created_at'] = datetime.now().isoformat()
            
            self.user_schedules[user_id].append(schedule)
            
            # 최대 일정 개수 제한
            if len(self.user_schedules[user_id]) > Settings.MAX_SCHEDULES_PER_USER:
                self.user_schedules[user_id] = self.user_schedules[user_id][-Settings.MAX_SCHEDULES_PER_USER:]
            

            
        except Exception as e:
            self.logger.error(f"Failed to store schedule: {e}")
    
    def get_context(self, user_id: str) -> Dict[str, Any]:
        """사용자 컨텍스트 조회"""
        try:
            # 최근 상호작용 가져오기
            recent_interactions = self.user_interactions[user_id][-10:]  # 최근 10개
            
            # 오늘의 일정 가져오기
            today_schedules = self._get_today_schedules(user_id)
            
            # 사용자 패턴 분석
            user_patterns = self._analyze_user_patterns(user_id)
            
            return {
                "recent_interactions": recent_interactions,
                "today_schedules": today_schedules,
                "user_patterns": user_patterns,
                "total_interactions": len(self.user_interactions[user_id]),
                "total_schedules": len(self.user_schedules[user_id])
            }
            
        except Exception as e:
            self.logger.error(f"Failed to get context: {e}")
            return {}
    
    def get_schedules(self, user_id: str) -> List[Dict[str, Any]]:
        """사용자 일정 목록 조회"""
        try:
            schedules = self.user_schedules[user_id]
            
            # 날짜순으로 정렬
            schedules.sort(key=lambda x: x.get('created_at', ''), reverse=True)
            
            return schedules
            
        except Exception as e:
            self.logger.error(f"Failed to get schedules: {e}")
            return []
    
    def remind_schedule(self, user_id: str) -> List[Dict[str, Any]]:
        """일정 알림 생성"""
        try:
            today = datetime.now().date()
            reminders = []
            
            for schedule in self.user_schedules[user_id]:
                schedule_data = schedule.get('data', {})
                schedule_datetime = schedule_data.get('datetime')
                
                if schedule_datetime:
                    try:
                        schedule_date = datetime.fromisoformat(schedule_datetime).date()
                        
                        # 오늘 일정이면 알림 생성
                        if schedule_date == today:
                            reminders.append({
                                'schedule_id': schedule['id'],
                                'title': schedule_data.get('title', ''),
                                'datetime': schedule_datetime,
                                'category': schedule_data.get('category', ''),
                                'is_important': schedule_data.get('is_important', False),
                                'reminder_message': self._generate_reminder_message(schedule_data)
                            })
                    except ValueError:
                        continue
            
            return reminders
            
        except Exception as e:
            self.logger.error(f"Failed to generate reminders: {e}")
            return []
    
    def _get_today_schedules(self, user_id: str) -> List[Dict[str, Any]]:
        """오늘의 일정 조회"""
        try:
            today = datetime.now().date()
            today_schedules = []
            
            for schedule in self.user_schedules[user_id]:
                schedule_data = schedule.get('data', {})
                schedule_datetime = schedule_data.get('datetime')
                
                if schedule_datetime:
                    try:
                        schedule_date = datetime.fromisoformat(schedule_datetime).date()
                        if schedule_date == today:
                            today_schedules.append(schedule)
                    except ValueError:
                        continue
            
            return today_schedules
            
        except Exception as e:
            self.logger.error(f"Failed to get today schedules: {e}")
            return []
    
    def _analyze_user_patterns(self, user_id: str) -> Dict[str, Any]:
        """사용자 패턴 분석"""
        try:
            interactions = self.user_interactions[user_id]
            
            if not interactions:
                return {}
            
            # 시간대별 사용 패턴
            time_patterns = defaultdict(int)
            category_patterns = defaultdict(int)
            
            for interaction in interactions[-50:]:  # 최근 50개 상호작용
                timestamp = interaction.get('timestamp')
                if timestamp:
                    try:
                        hour = datetime.fromisoformat(timestamp).hour
                        time_patterns[hour] += 1
                    except ValueError:
                        continue
                
                # 일정 카테고리 패턴
                schedule_result = interaction.get('schedule_result', {})
                if schedule_result.get('is_schedule'):
                    schedule_info = schedule_result.get('schedule_info', {})
                    category = schedule_info.get('category', '')
                    if category:
                        category_patterns[category] += 1
            
            return {
                "time_patterns": dict(time_patterns),
                "category_patterns": dict(category_patterns),
                "total_interactions": len(interactions)
            }
            
        except Exception as e:
            self.logger.error(f"Failed to analyze patterns: {e}")
            return {}
    
    def _generate_reminder_message(self, schedule_data: Dict[str, Any]) -> str:
        """알림 메시지 생성"""
        try:
            title = schedule_data.get('title', '')
            category = schedule_data.get('category', '')
            is_important = schedule_data.get('is_important', False)
            
            if is_important:
                return f"중요한 일정입니다: {title}"
            elif category == '건강':
                return f"건강 관련 일정입니다: {title}"
            else:
                return f"일정 알림: {title}"
                
        except Exception as e:
            self.logger.error(f"Failed to generate reminder message: {e}")
            return "일정 알림"
    
    def cleanup_old_data(self):
        """오래된 데이터 정리"""
        try:
            current_time = datetime.now()
            expiry_time = current_time - timedelta(hours=Settings.MEMORY_EXPIRY_HOURS)
            
            for user_id in list(self.user_interactions.keys()):
                # 오래된 상호작용 제거
                self.user_interactions[user_id] = [
                    interaction for interaction in self.user_interactions[user_id]
                    if datetime.fromisoformat(interaction.get('timestamp', '')) > expiry_time
                ]
            
            self.last_cleanup = current_time
            self.logger.info("Memory cleanup completed")
            
        except Exception as e:
            self.logger.error(f"Failed to cleanup old data: {e}")
    
    def get_memory_info(self) -> Dict[str, Any]:
        """메모리 정보 조회"""
        try:
            total_users = len(self.user_interactions)
            total_interactions = sum(len(interactions) for interactions in self.user_interactions.values())
            total_schedules = sum(len(schedules) for schedules in self.user_schedules.values())
            
            return {
                "total_users": total_users,
                "total_interactions": total_interactions,
                "total_schedules": total_schedules,
                "last_cleanup": self.last_cleanup.isoformat(),
                "memory_size": len(self.user_interactions) + len(self.user_schedules)
            }
            
        except Exception as e:
            self.logger.error(f"Failed to get memory info: {e}")
            return {} 