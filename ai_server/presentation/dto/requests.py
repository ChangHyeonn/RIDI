#!/usr/bin/env python3
"""
API Request DTOs
API 요청 데이터 전송 객체
"""

from dataclasses import dataclass
from typing import Optional


@dataclass
class ProcessTextRequestDTO:
    """텍스트 처리 요청 DTO"""
    text: str
    user_id: str
    
    @classmethod
    def from_dict(cls, data: dict) -> 'ProcessTextRequestDTO':
        """딕셔너리에서 DTO 생성"""
        return cls(
            text=data.get('text', '').strip(),
            user_id=data.get('user_id', '').strip()
        )
    
    def is_valid(self) -> bool:
        """유효성 검사"""
        return bool(self.text and self.user_id)


@dataclass
class HealthCheckRequestDTO:
    """헬스체크 요청 DTO"""
    include_details: bool = False
    
    @classmethod
    def from_dict(cls, data: dict) -> 'HealthCheckRequestDTO':
        """딕셔너리에서 DTO 생성"""
        return cls(
            include_details=data.get('include_details', False)
        )
