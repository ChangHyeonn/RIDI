#!/usr/bin/env python3
"""
AI Service for Text Processing
텍스트 기반 AI 서비스 (STT/TTS 제거)
"""

import sys
import os
import logging
from datetime import datetime
from typing import Dict, Any, Optional

# 프로젝트 루트를 Python 경로에 추가
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

from Config.settings import Settings
from Processor.unified_text_pipeline import UnifiedTextPipeline
from Services.Memory import MemoryManager
from Services.ScheduleManager import ScheduleManager
from Services.AccessibilityManager import AccessibilityManager


class AIService:
    """AI 서비스 클래스 (텍스트 기반)"""
    
    def __init__(self):
        self._setup_logging()
        self._initialize_components()
    
    def _setup_logging(self):
        """로깅 설정"""
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
    
    def _initialize_components(self):
        """AI 컴포넌트 초기화"""
        try:
            # 텍스트 처리 파이프라인 초기화
            self.pipeline = UnifiedTextPipeline(
                llm_type=Settings.LLM_TYPE,
                device=Settings.get_device()
            )
            self.memory_manager = MemoryManager()
            
            # 매니저들 초기화
            self.schedule_manager = ScheduleManager()
            self.accessibility_manager = AccessibilityManager()
            
            self.logger.info("AI Service initialized successfully")
            
        except Exception as e:
            self.logger.error(f"AI Service initialization failed: {e}")
            raise
    
    def process_text_command(self, user_text: str, user_id: Optional[str] = None) -> Dict[str, Any]:
        """텍스트 명령 처리 (LLM 중심 통합 처리)"""
        try:
            # 통합 파이프라인으로 처리 (LLM이 모든 분류와 추출을 담당)
            result = self.pipeline.process_text(user_text, user_id)
            
            if not result:
                return {
                    "success": False,
                    "error": "텍스트 처리에 실패했습니다."
                }
            
            # LLM 중심 처리로 모든 분류와 추출이 이미 완료됨
            return result
            
        except Exception as e:
            self.logger.error(f"Text command processing failed: {e}")
            return {
                "success": False,
                "error": f"텍스트 명령 처리 중 오류가 발생했습니다: {str(e)}"
            }
    
    def get_health_info(self) -> Dict[str, Any]:
        """서버 상태 정보"""
        try:
            return {
                "status": "healthy",
                "device": Settings.get_device(),
                "llm_type": Settings.LLM_TYPE,
                "pipeline_info": self.pipeline.get_pipeline_info(),
                "memory_info": self.memory_manager.get_memory_info(),
                "text_processing_config": Settings.get_text_processing_config(),
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
    
    def delete_schedule(self, user_id: str, schedule_id: str) -> Dict[str, Any]:
        """일정 삭제"""
        try:
            result = self.schedule_manager.delete_schedule(user_id, schedule_id)
            return result
        except Exception as e:
            self.logger.error(f"Failed to delete schedule: {e}")
            return {
                "success": False,
                "error": f"일정 삭제 중 오류가 발생했습니다: {str(e)}"
            }
    
    def get_schedules_by_date(self, user_id: str, target_date: str) -> Dict[str, Any]:
        """특정 날짜 일정 조회"""
        try:
            schedules = self.schedule_manager.get_schedules_by_date(user_id, target_date)
            return {
                "success": True,
                "schedules": schedules,
                "date": target_date,
                "count": len(schedules)
            }
        except Exception as e:
            self.logger.error(f"Failed to get schedules by date: {e}")
            return {
                "success": False,
                "error": f"일정 조회 중 오류가 발생했습니다: {str(e)}"
            }
    
    def get_important_schedules(self, user_id: str) -> Dict[str, Any]:
        """중요 일정 조회"""
        try:
            schedules = self.schedule_manager.get_important_schedules(user_id)
            return {
                "success": True,
                "schedules": schedules,
                "count": len(schedules)
            }
        except Exception as e:
            self.logger.error(f"Failed to get important schedules: {e}")
            return {
                "success": False,
                "error": f"중요 일정 조회 중 오류가 발생했습니다: {str(e)}"
            }
    
    def update_accessibility_settings(self, user_id: str, settings: Dict[str, Any]) -> Dict[str, Any]:
        """접근성 설정 업데이트"""
        try:
            result = self.accessibility_manager.update_accessibility_settings(user_id, settings)
            return result
        except Exception as e:
            self.logger.error(f"Failed to update accessibility settings: {e}")
            return {
                "success": False,
                "error": f"접근성 설정 업데이트 중 오류가 발생했습니다: {str(e)}"
            }
    
    def get_accessibility_settings(self, user_id: str) -> Dict[str, Any]:
        """접근성 설정 조회"""
        try:
            settings = self.accessibility_manager.get_accessibility_settings(user_id)
            return {
                "success": True,
                "settings": settings
            }
        except Exception as e:
            self.logger.error(f"Failed to get accessibility settings: {e}")
            return {
                "success": False,
                "error": f"접근성 설정 조회 중 오류가 발생했습니다: {str(e)}"
            }
    
    def _validate_schedule_data(self, schedule_data: Dict[str, Any]) -> Dict[str, Any]:
        """일정 데이터 검증"""
        if not schedule_data:
            return {"valid": False, "error": "일정 데이터가 없습니다."}
        
        if not schedule_data.get('title'):
            return {"valid": False, "error": "일정 제목이 필요합니다."}
        
        if not schedule_data.get('datetime'):
            return {"valid": False, "error": "일정 날짜와 시간이 필요합니다."}
        
        return {"valid": True}
    
    def _create_error_response(self, error_message: str) -> Dict[str, Any]:
        """에러 응답 생성"""
        return {
            "success": False,
            "error": error_message,
            "timestamp": datetime.now().isoformat()
        } 