#!/usr/bin/env python3
"""
Schedule Entity - Domain Model
일정 도메인 모델 (비즈니스 핵심 로직)
"""

from dataclasses import dataclass, field
from datetime import datetime, time
from typing import Optional, List, Dict, Any
from enum import Enum


class RecurrenceType(Enum):
    """반복 타입"""
    DAILY = "daily"           # 매일
    WEEKDAYS = "weekdays"     # 평일 (월~금)
    WEEKENDS = "weekends"     # 주말 (토, 일)
    CUSTOM_DAYS = "custom_days"  # 특정 요일들 (월,수,금 등)


@dataclass
class RecurrenceTime:
    """하루 내 반복 시간"""
    time: str              # "07:00", "18:00" 형태
    label: Optional[str] = None  # "아침", "저녁" 등


@dataclass
class RecurrencePattern:
    """반복 패턴"""
    type: str                                    # "daily", "weekdays", "weekends", "custom_days"
    times: List[RecurrenceTime] = field(default_factory=list)  # 하루 내 시간들
    end_date: Optional[str] = None               # "2025-09-30" 또는 None (무기한)
    days_of_week: Optional[List[int]] = None     # [0,2,4] = 월,수,금 (0=월요일)


@dataclass
class Schedule:
    """일정 엔티티 (반복 일정 지원)"""
    
    # 기본 필드
    id: Optional[str]
    user_id: str
    title: str
    start_datetime: datetime
    category: str = "일반"
    is_important: bool = False
    location: Optional[str] = None
    description: Optional[str] = None
    status: str = "active"
    
    # 반복 일정 필드
    is_recurring: bool = False
    recurrence_pattern: Optional[RecurrencePattern] = None
    parent_schedule_id: Optional[str] = None    # 반복 그룹 ID
    
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
    
    def is_recurring_schedule(self) -> bool:
        """반복 일정 여부 확인"""
        return self.is_recurring
    
    def get_recurrence_description(self) -> str:
        """반복 설정 설명 생성"""
        if not self.is_recurring or not self.recurrence_pattern:
            return "일회성 일정"
        
        pattern = self.recurrence_pattern
        type_desc = {
            "daily": "매일",
            "weekdays": "평일마다", 
            "weekends": "주말마다",
            "custom_days": "특정 요일마다"
        }.get(pattern.type, "반복")
        
        times_desc = ""
        if len(pattern.times) > 1:
            times_desc = f" (하루 {len(pattern.times)}회)"
        
        end_desc = ""
        if pattern.end_date:
            end_desc = f" ({pattern.end_date}까지)"
        else:
            end_desc = " (무기한)"
        
        return f"{type_desc}{times_desc}{end_desc}"
    
    def to_dict(self) -> dict:
        """딕셔너리 변환"""
        result = {
            'id': self.id,
            'user_id': self.user_id,
            'title': self.title,
            'start_datetime': self.start_datetime.isoformat() if self.start_datetime else None,
            'category': self.category,
            'is_important': self.is_important,
            'location': self.location,
            'description': self.description,
            'status': self.status,
            'is_recurring': self.is_recurring,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
        
        # 반복 일정 정보 추가
        if self.is_recurring and self.recurrence_pattern:
            result['recurrence'] = {
                'type': self.recurrence_pattern.type,
                'times': [{
                    'time': rt.time,
                    'label': rt.label
                } for rt in self.recurrence_pattern.times],
                'end_date': self.recurrence_pattern.end_date,
                'days_of_week': self.recurrence_pattern.days_of_week
            }
        
        return result