#!/usr/bin/env python3
"""
AI Service Layer
고령층 일정 메모 관리 AI 서비스
"""

import logging
import tempfile
import os
from datetime import datetime
from typing import Dict, Any, Optional
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from Config.settings import Settings
from Config.logging_config import get_logger

# AI 모델들 import
from Processor.integrated_pipeline import IntegratedPipeline
from Models.Memory import MemoryManager

class AIService:
    """AI 서비스 클래스"""
    
    def __init__(self):
        self.logger = get_logger(__name__)
        self._setup_logging()
        self._initialize_components()
        self.logger.info("AI Service initialized successfully")
    
    def _setup_logging(self):
        """로깅 설정"""
        self.logger.info(f"Initializing AI Service with device: {Settings.get_device()}")
    
    def _initialize_components(self):
        """컴포넌트 초기화"""
        try:
            # 통합 파이프라인 초기화
            self.pipeline = IntegratedPipeline(
                stt_model=Settings.STT_MODEL,
                llm_type=Settings.LLM_TYPE,
                device=Settings.get_device()
            )
            
            # 메모리 관리자 초기화
            self.memory_manager = MemoryManager()
            
    
            
        except Exception as e:
            self.logger.error(f"Failed to initialize AI components: {e}")
            raise
    
    def process_voice_command(self, audio_path: str, user_id: Optional[str] = None) -> Dict[str, Any]:
        """음성 명령 처리"""
        try:
            # 음성 처리
            result = self.pipeline.process_voice_command(audio_path)
            
            # 사용자 ID가 있으면 메모리에 저장
            if user_id and result.get('success'):
                self.memory_manager.store_interaction(user_id, {
                    'timestamp': datetime.now().isoformat(),
                    'user_message': result.get('user_message', ''),
                    'ai_response': result.get('ai_response', ''),
                    'schedule_result': result.get('schedule_result', {})
                })
            
            # 고령자 특화 응답 처리
            if result.get('success') and Settings.SIMPLE_RESPONSES:
                result = self._simplify_response_for_elderly(result)
            
            return result
            
        except Exception as e:
            self.logger.error(f"Voice processing failed: {e}")
            return self._create_error_response(f"음성 처리 중 오류가 발생했습니다: {str(e)}")
    
    def _simplify_response_for_elderly(self, result: Dict[str, Any]) -> Dict[str, Any]:
        """고령자를 위한 응답 단순화"""
        if 'ai_response' in result:
            # 복잡한 설명을 간단하게
            response = result['ai_response']
            if len(response) > 100:
                # 핵심 내용만 추출
                if '일정이 등록되었습니다' in response:
                    result['ai_response'] = "일정이 등록되었습니다."
                elif '추가 정보가 필요합니다' in response:
                    result['ai_response'] = "좀 더 자세히 말씀해 주세요."
        
        return result
    
    def get_health_info(self) -> Dict[str, Any]:
        """서버 상태 정보"""
        try:
            return {
                "status": "healthy",
                "device": Settings.get_device(),
                "llm_type": Settings.LLM_TYPE,
                "stt_model": Settings.STT_MODEL,
                "pipeline_info": self.pipeline.get_pipeline_info(),
                "memory_info": self.memory_manager.get_memory_info(),
                "elderly_settings": {
                    "speech_rate": Settings.SPEECH_RATE,
                    "volume_level": Settings.VOLUME_LEVEL,
                    "simple_responses": Settings.SIMPLE_RESPONSES,
                    "repeat_important": Settings.REPEAT_IMPORTANT
                },
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            self.logger.error(f"Health check failed: {e}")
            return {
                "status": "unhealthy",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    def add_schedule(self, schedule_data: Dict[str, Any], user_id: str) -> Dict[str, Any]:
        """일정 추가"""
        try:

            
            # 일정 데이터 검증
            validation_result = self._validate_schedule_data(schedule_data)
            if not validation_result['valid']:
                return self._create_error_response(validation_result['error'])
            
            # 일정 추가 로직 (실제로는 데이터베이스에 저장)
            schedule_id = f"schedule_{datetime.now().timestamp()}"
            
            # 메모리에 저장
            self.memory_manager.store_schedule(user_id, {
                'id': schedule_id,
                'data': schedule_data,
                'created_at': datetime.now().isoformat()
            })
            
            return {
                "success": True,
                "schedule_id": schedule_id,
                "message": "일정이 성공적으로 추가되었습니다.",
                "schedule": schedule_data
            }
            
        except Exception as e:
            self.logger.error(f"Failed to add schedule: {e}")
            return self._create_error_response(f"일정 추가 중 오류가 발생했습니다: {str(e)}")
    
    def get_schedules(self, user_id: str) -> Dict[str, Any]:
        """일정 목록 조회"""
        try:

            
            schedules = self.memory_manager.get_schedules(user_id)
            
            return {
                "success": True,
                "schedules": schedules,
                "count": len(schedules)
            }
            
        except Exception as e:
            self.logger.error(f"Failed to get schedules: {e}")
            return self._create_error_response(f"일정 조회 중 오류가 발생했습니다: {str(e)}")
    
    def get_user_context(self, user_id: str) -> Dict[str, Any]:
        """사용자 컨텍스트 조회"""
        try:
            context = self.memory_manager.get_context(user_id)
            return {
                "success": True,
                "context": context
            }
        except Exception as e:
            self.logger.error(f"Failed to get user context: {e}")
            return self._create_error_response(f"사용자 정보 조회 중 오류가 발생했습니다: {str(e)}")
    
    def _validate_schedule_data(self, schedule_data: Dict[str, Any]) -> Dict[str, Any]:
        """일정 데이터 검증"""
        required_fields = ['title', 'datetime']
        
        for field in required_fields:
            if field not in schedule_data or not schedule_data[field]:
                return {
                    'valid': False,
                    'error': f"필수 필드가 누락되었습니다: {field}"
                }
        
        return {'valid': True}
    
    def _create_error_response(self, error_message: str) -> Dict[str, Any]:
        """에러 응답 생성"""
        return {
            "success": False,
            "error": error_message,
            "timestamp": datetime.now().isoformat()
        } 