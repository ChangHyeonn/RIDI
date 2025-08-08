import sys
import os
import time
import logging
from datetime import datetime
from typing import Dict, Any, Optional
from dotenv import load_dotenv

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from Processor.unified_voice_pipeline import UnifiedVoicePipeline

class IntegratedPipeline:
    def __init__(self, stt_model: str = "small", llm_type: str = "gemini", device: str = "auto"):
        self.stt_model = stt_model
        self.llm_type = llm_type
        self.device = device
        self._setup_logging()
        self._initialize_components()
    
    def _setup_logging(self):
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
    
    def _initialize_components(self):
        """컴포넌트 초기화"""
        try:
            # 통합 음성 파이프라인 사용
            self.unified_pipeline = UnifiedVoicePipeline(
                stt_model=self.stt_model,
                llm_type=self.llm_type,
                device=self.device
            )
            
            self.logger.info("Integrated Pipeline initialized successfully")
            
        except Exception as e:
            self.logger.error(f"Failed to initialize components: {e}")
            raise
    
    def process_voice_command(self, audio_input_path: str, user_id: Optional[str] = None) -> Dict[str, Any]:
        """음성 명령 처리 (LLM 중심 통합 처리)"""
        try:
            # 통합 파이프라인으로 처리
            result = self.unified_pipeline.process_voice(audio_input_path, user_id)
            
            self.logger.info(f"Voice command processed with unified pipeline")
            return result
            
        except Exception as e:
            self.logger.error(f"Voice command processing failed: {e}")
            return {
                'success': False,
                'error': f"음성 명령 처리 중 오류가 발생했습니다: {str(e)}"
            }
    
    def _create_success_response(self, user_message: str, ai_response: str, 
                               audio_response: bytes, schedule_result: Dict[str, Any], 
                               total_time: float) -> Dict[str, Any]:
        return {
            "success": True,
            "user_message": user_message,
            "ai_response": ai_response,
            "audio_response": audio_response,
            "schedule_result": schedule_result,
            "processing_time": total_time,
            "timestamp": datetime.now().isoformat(),
            "pipeline_info": self.get_pipeline_info()
        }
    
    def _create_error_response(self, error_message: str) -> Dict[str, Any]:
        return {
            "success": False,
            "error": error_message,
            "timestamp": datetime.now().isoformat(),
            "pipeline_info": self.get_pipeline_info()
        }
    
    def get_pipeline_info(self) -> Dict[str, Any]:
        return {
            "pipeline_type": "Integrated Voice Pipeline (LLM Centered)",
            "components": {
                "unified_pipeline": self.unified_pipeline.get_pipeline_info()
            },
            "features": {
                "llm_centered": True,
                "unified_processing": True,
                "voice_to_voice": True,
                "memory_integration": True,
                "error_handling": True
            }
        }
    
    def change_llm_model(self, llm_type: str):
        self.llm_type = llm_type
        self.unified_pipeline.change_llm_model(llm_type)
        self.logger.info(f"LLM model changed to: {llm_type}")