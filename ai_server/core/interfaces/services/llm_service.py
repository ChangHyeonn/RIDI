#!/usr/bin/env python3
"""
LLM Service Interface
LLM 서비스 인터페이스 (포트)
"""

from abc import ABC, abstractmethod
from typing import Dict, Any

from core.entities.text_request import IntentAnalysis


class ILLMService(ABC):
    """LLM 서비스 인터페이스"""
    
    @abstractmethod
    def analyze_intent(self, text: str) -> IntentAnalysis:
        """사용자 텍스트의 의도 분석"""
        pass
    
    @abstractmethod
    def extract_schedule_info(self, text: str) -> Dict[str, Any]:
        """텍스트에서 일정 정보 추출"""
        pass
    
    @abstractmethod
    def generate_response(self, prompt: str, max_tokens: int = 1000) -> str:
        """텍스트 응답 생성"""
        pass
    
    @abstractmethod
    def get_model_info(self) -> Dict[str, Any]:
        """모델 정보 반환"""
        pass
