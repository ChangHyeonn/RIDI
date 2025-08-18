#!/usr/bin/env python3
"""
Text Request/Response Entities
텍스트 요청/응답 도메인 모델
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Optional, Dict, Any


@dataclass
class TextRequest:
    """텍스트 요청 엔티티"""
    
    text: str
    user_id: str
    timestamp: datetime = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now()
    
    def is_valid(self) -> bool:
        """요청 유효성 검사"""
        return bool(self.text and self.text.strip() and self.user_id)


@dataclass
class TextProcessingResult:
    """텍스트 처리 결과 엔티티"""
    
    success: bool
    action_type: str
    action_data: Dict[str, Any]
    response_text: str
    processing_time: float = 0.0
    timestamp: datetime = None
    error_message: Optional[str] = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now()
    
    def to_dict(self) -> Dict[str, Any]:
        """딕셔너리 변환 (API 응답용)"""
        result = {
            'success': self.success,
            'processing_result': {
                'action': self.action_type,
                'result': self.action_data
            },
            'response_text': self.response_text,
            'processing_time': self.processing_time,
            'timestamp': self.timestamp.isoformat()
        }
        
        if self.error_message:
            result['error'] = self.error_message
            
        return result


@dataclass
class IntentAnalysis:
    """의도 분석 결과"""
    
    category: str  # schedule_add, schedule_read, schedule_delete, other
    confidence: float
    extracted_info: Dict[str, Any]
    raw_analysis: Optional[str] = None
