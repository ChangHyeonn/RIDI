#!/usr/bin/env python3
"""
Unified Text Processing Pipeline
LLM 중심의 통합 텍스트 처리 파이프라인 (STT/TTS 제거)
"""

import sys
import os
import time
import logging
from datetime import datetime
from typing import Dict, Any, Optional

# 프로젝트 루트를 Python 경로에 추가
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from Services.UnifiedRequestProcessor import UnifiedRequestProcessor
from Config.prompts import PromptManager


class UnifiedTextPipeline:
    """LLM 중심의 통합 텍스트 처리 파이프라인"""
    
    def __init__(self, 
                 llm_type: str = "openai",
                 device: str = "auto"):
        self._setup_logging()
        self._initialize_components(llm_type, device)
        self.logger.info("Unified Text Pipeline initialized successfully")
    
    def _setup_logging(self):
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
    
    def _initialize_components(self, llm_type: str, device: str):
        """컴포넌트 초기화"""
        try:
            self.request_processor = UnifiedRequestProcessor(llm_type=llm_type)
            self.device = self._get_device(device)
            
        except Exception as e:
            self.logger.error(f"Failed to initialize components: {e}")
            raise
    
    def _get_device(self, device: str) -> str:
        """디바이스 설정"""
        if device == "auto":
            try:
                import torch
                if torch.cuda.is_available():
                    return "cuda"
                else:
                    return "cpu"
            except ImportError:
                return "cpu"
        return device
    
    def process_text(self, user_text: str, user_id: Optional[str] = None) -> Dict[str, Any]:
        """텍스트 처리 메인 파이프라인"""
        start_time = time.time()
        
        try:
            # 입력 텍스트 검증
            if not user_text or not user_text.strip():
                return self._create_error_response("입력 텍스트가 비어있습니다.")
            
            # LLM 기반 요청 분석 및 처리
            processing_result = self.request_processor.process_request(user_text, user_id)
            
            # 응답 생성
            if processing_result.get('success'):
                # 성공 시: 결과에 따른 응답 생성
                response_text = self._generate_response_text(processing_result)
                
                return self._create_success_response(
                    user_text, processing_result, response_text, 
                    time.time() - start_time
                )
            else:
                # 실패 시: 에러 메시지 응답
                error_text = processing_result.get('error', '처리 중 오류가 발생했습니다.')
                
                return self._create_error_response(
                    error_text, time.time() - start_time
                )
                
        except Exception as e:
            self.logger.error(f"Text processing failed: {e}")
            return self._create_error_response(f"텍스트 처리 중 오류가 발생했습니다: {str(e)}")
    
    def _generate_response_text(self, processing_result: Dict[str, Any]) -> str:
        """처리 결과에 따른 응답 텍스트 생성"""
        try:
            result = processing_result.get('result', {})
            
            # 성공 메시지가 있으면 사용
            if result.get('message'):
                return result['message']
            
            # 액션별 기본 메시지
            action = result.get('action', '')
            
            if action == 'schedule_added':
                return "일정이 성공적으로 추가되었습니다."
            elif action == 'schedule_modify':
                return "일정 수정을 진행하겠습니다."
            elif action == 'schedule_delete':
                return "일정 삭제를 진행하겠습니다."
            elif action == 'schedule_read':
                return "일정을 조회합니다."
            elif action == 'accessibility_change':
                return "접근성 설정을 변경하겠습니다."
            else:
                return "요청을 처리했습니다."
                
        except Exception as e:
            self.logger.error(f"Response text generation failed: {e}")
            return "요청을 처리했습니다."
    
    def _create_success_response(self, user_text: str, processing_result: Dict[str, Any], 
                               response_text: str, processing_time: float) -> Dict[str, Any]:
        """성공 응답 생성"""
        return {
            "success": True,
            "user_text": user_text,
            "processing_result": processing_result,
            "response_text": response_text,
            "processing_time": processing_time,
            "timestamp": datetime.now().isoformat(),
            "pipeline_info": self.get_pipeline_info()
        }
    
    def _create_error_response(self, error_message: str, processing_time: float = 0.0) -> Dict[str, Any]:
        """에러 응답 생성"""
        response = {
            "success": False,
            "error": error_message,
            "processing_time": processing_time,
            "timestamp": datetime.now().isoformat(),
            "pipeline_info": self.get_pipeline_info()
        }
        
        return response
    
    def get_pipeline_info(self) -> Dict[str, Any]:
        """파이프라인 정보"""
        return {
            "pipeline_type": "Unified Text Pipeline",
            "components": {
                "request_processor": self.request_processor.get_processor_info()
            },
            "features": {
                "llm_centered": True,
                "unified_processing": True,
                "text_to_text": True,
                "error_handling": True,
                "memory_integration": True,
                "no_stt_tts": True
            }
        }
    
    def change_llm_model(self, llm_type: str):
        """LLM 모델 변경"""
        self.request_processor = UnifiedRequestProcessor(llm_type=llm_type)
        self.logger.info(f"LLM model changed to: {llm_type}")
    
    def get_processing_stats(self) -> Dict[str, Any]:
        """처리 통계"""
        return {
            "pipeline_type": "Unified Text Pipeline",
            "device": self.device,
            "components": {
                "llm_model": self.request_processor.llm.get_model_info().get('model_name', 'unknown')
            }
        }
