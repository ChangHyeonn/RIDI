#!/usr/bin/env python3
"""
API Response DTOs
API 응답 데이터 전송 객체
"""

from dataclasses import dataclass
from typing import Dict, Any, Optional
from datetime import datetime


@dataclass
class APIResponseDTO:
    """기본 API 응답 DTO"""
    success: bool
    data: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    timestamp: Optional[str] = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now().isoformat()
    
    def to_dict(self) -> Dict[str, Any]:
        """딕셔너리 변환"""
        result = {
            'success': self.success,
            'timestamp': self.timestamp
        }
        
        if self.data is not None:
            result.update(self.data)
        
        if self.error is not None:
            result['error'] = self.error
            
        return result


@dataclass
class ProcessTextResponseDTO:
    """텍스트 처리 응답 DTO"""
    success: bool
    processing_result: Dict[str, Any]
    response_text: str
    processing_time: float
    timestamp: str
    error_message: Optional[str] = None
    
    @classmethod
    def from_processing_result(cls, result) -> 'ProcessTextResponseDTO':
        """TextProcessingResult에서 DTO 생성"""
        return cls(
            success=result.success,
            processing_result={
                'action': result.action_type,
                'result': result.action_data
            },
            response_text=result.response_text,
            processing_time=result.processing_time,
            timestamp=result.timestamp.isoformat(),
            error_message=result.error_message
        )
    
    def to_dict(self) -> Dict[str, Any]:
        """딕셔너리 변환"""
        result = {
            'success': self.success,
            'processing_result': self.processing_result,
            'response_text': self.response_text,
            'processing_time': self.processing_time,
            'timestamp': self.timestamp
        }
        
        if self.error_message:
            result['error'] = self.error_message
            
        return result


@dataclass
class HealthCheckResponseDTO:
    """헬스체크 응답 DTO"""
    status: str
    uptime: float
    version: str
    details: Optional[Dict[str, Any]] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """딕셔너리 변환"""
        result = {
            'status': self.status,
            'uptime': self.uptime,
            'version': self.version,
            'timestamp': datetime.now().isoformat()
        }
        
        if self.details:
            result['details'] = self.details
            
        return result
