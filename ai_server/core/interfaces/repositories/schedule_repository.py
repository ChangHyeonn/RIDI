#!/usr/bin/env python3
"""
Schedule Repository Interface
일정 저장소 인터페이스 (포트)
"""

from abc import ABC, abstractmethod
from typing import List, Optional
from datetime import date

from core.entities.schedule import Schedule


class IScheduleRepository(ABC):
    """일정 저장소 인터페이스"""
    
    @abstractmethod
    def save(self, schedule: Schedule) -> Schedule:
        """일정 저장"""
        pass
    
    @abstractmethod
    def find_by_id(self, schedule_id: str) -> Optional[Schedule]:
        """ID로 일정 조회"""
        pass
    
    @abstractmethod
    def find_by_user_id(self, user_id: str) -> List[Schedule]:
        """사용자별 일정 조회"""
        pass
    
    @abstractmethod
    def find_by_user_and_date(self, user_id: str, target_date: date) -> List[Schedule]:
        """사용자별 특정 날짜 일정 조회"""
        pass
    
    @abstractmethod
    def find_important_by_user(self, user_id: str) -> List[Schedule]:
        """사용자별 중요 일정 조회"""
        pass
    
    @abstractmethod
    def update(self, schedule: Schedule) -> Schedule:
        """일정 수정"""
        pass
    
    @abstractmethod
    def delete(self, schedule_id: str) -> bool:
        """일정 삭제"""
        pass
    
    @abstractmethod
    def delete_by_user_and_title(self, user_id: str, title: str) -> bool:
        """사용자별 제목으로 일정 삭제"""
        pass
