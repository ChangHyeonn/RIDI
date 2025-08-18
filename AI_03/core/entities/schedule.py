#!/usr/bin/env python3
"""
Schedule Entity - Domain Model
일정 도메인 모델 (비즈니스 핵심 로직)
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class Schedule:
    """일정 엔티티"""
    
    id: Optional[str]
    user_id: str
    title: str
    start_datetime: datetime
    category: str = "일반"
    is_important: bool = False
    location: Optional[str] = None
    description: Optional[str] = None
    status: str = "active"
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    def __post_init__(self):
        if self.created_at is None:
            self.created_at = datetime.now()
        if self.updated_at is None:
            self.updated_at = datetime.now()
    
    def mark_completed(self):
        """일정 완료 처리"""
        self.status = "completed"
        self.updated_at = datetime.now()
    
    def mark_cancelled(self):
        """일정 취소 처리"""
        self.status = "cancelled"
        self.updated_at = datetime.now()
    
    def update_title(self, new_title: str):
        """제목 변경"""
        self.title = new_title
        self.updated_at = datetime.now()
    
    def update_datetime(self, new_datetime: datetime):
        """날짜/시간 변경"""
        self.start_datetime = new_datetime
        self.updated_at = datetime.now()
    
    def is_active(self) -> bool:
        """활성 상태 확인"""
        return self.status == "active"
    
    def to_dict(self) -> dict:
        """딕셔너리 변환"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'title': self.title,
            'start_datetime': self.start_datetime.isoformat() if self.start_datetime else None,
            'category': self.category,
            'is_important': self.is_important,
            'location': self.location,
            'description': self.description,
            'status': self.status,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
