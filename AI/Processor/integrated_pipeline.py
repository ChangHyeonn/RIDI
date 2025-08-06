import sys
import os
import time
import logging
from datetime import datetime
from typing import Dict, Any, Optional
from dotenv import load_dotenv

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from Processor.voice_pipeline import VoicePipeline
from Services.Classifier import ScheduleClassifier
from Services.CommandClassifier import CommandClassifier

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
            # 기존 컴포넌트
            self.voice_pipeline = VoicePipeline(
                stt_model=self.stt_model,
                llm_type=self.llm_type,
                device=self.device
            )
            self.schedule_classifier = ScheduleClassifier()
            
            # 새로운 컴포넌트
            self.command_classifier = CommandClassifier(llm_type=self.llm_type)
            
            self.logger.info("Integrated Pipeline initialized successfully")
            
        except Exception as e:
            self.logger.error(f"Failed to initialize components: {e}")
            raise
    
    def process_voice_command(self, audio_input_path: str, user_id: Optional[str] = None) -> Dict[str, Any]:
        """음성 명령 처리 (확장된 버전)"""
        try:
            # 1. 음성 처리 (STT -> LLM -> TTS)
            voice_result = self.voice_pipeline.process_voice(audio_input_path)
            
            if not voice_result.get('success'):
                return voice_result
            
            # 2. 명령 분류
            text = voice_result.get('text', '')
            command_result = self.command_classifier.classify_command(text)
            
            # 3. 명령 타입에 따른 처리
            command_type = command_result.get('type', 'unknown')
            confidence = command_result.get('confidence', 0.0)
            
            result = {
                'success': True,
                'text': text,
                'command_classification': command_result,
                'command_type': command_type,
                'confidence': confidence,
                'user_id': user_id
            }
            
            # 4. 명령 타입별 특별 처리
            if command_type == "add_schedule":
                # 일정 추가 처리
                schedule_info = self.command_classifier.extract_command_info(text, command_type)
                schedule_result = self.schedule_classifier.classify_schedule(text)
                result['schedule_info'] = schedule_info
                result['schedule_classification'] = schedule_result
                
            elif command_type == "delete_schedule":
                # 일정 삭제 처리
                delete_info = self.command_classifier.extract_command_info(text, command_type)
                result['delete_info'] = delete_info
                
            elif command_type == "read_schedule":
                # 일정 읽기 처리
                date_info = self.command_classifier.extract_command_info(text, command_type)
                result['date_info'] = date_info
                
            elif command_type == "important_schedule":
                # 중요 일정 처리
                result['important_schedule_request'] = True
                
            elif command_type == "accessibility":
                # 접근성 설정 처리
                accessibility_info = self.command_classifier.extract_command_info(text, command_type)
                result['accessibility_info'] = accessibility_info
            
            # 5. 음성 응답 생성
            if voice_result.get('audio_response'):
                result['audio_response'] = voice_result['audio_response']
            
            self.logger.info(f"Voice command processed: {command_type} (confidence: {confidence})")
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
            "pipeline_type": "Integrated Voice Pipeline",
            "components": {
                "voice_pipeline": self.voice_pipeline.get_pipeline_info(),
                "schedule_classifier": self.schedule_classifier.get_classifier_info()
            },
            "features": {
                "basic_voice_processing": True,
                "schedule_classification": True,
                "voice_to_voice": True,
                "input_validation": True,
                "error_handling": True
            }
        }
    
    def change_llm_model(self, llm_type: str):
        self.llm_type = llm_type
        self.voice_pipeline.change_llm_model(llm_type)
        self.schedule_classifier = ScheduleClassifier(llm_type=llm_type)
        self.logger.info(f"LLM model changed to: {llm_type}")