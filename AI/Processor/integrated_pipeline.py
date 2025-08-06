#!/usr/bin/env python3
"""
Integrated Pipeline - 통합 음성 처리 파이프라인
기본 음성 처리 + 일정 분류 기능 통합
"""

import sys
import os
import time
import logging
from datetime import datetime
from typing import Dict, Any
from dotenv import load_dotenv

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from Processor.voice_pipeline import VoicePipeline
from Models.Classifier import ScheduleClassifier

class IntegratedPipeline:
    """통합 음성 처리 파이프라인"""
    
    def __init__(self, 
                 stt_model: str = "small",
                 llm_type: str = None,
                 device: str = "auto"):
        load_dotenv()
        
        self.device = device
        self.llm_type = llm_type or os.getenv('LLM_MODEL', 'gemini')
        
        self._setup_logging()
        self._initialize_components(stt_model)
        self.logger.info(f"Integrated Pipeline initialized successfully")
    
    def _setup_logging(self):
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
    
    def _initialize_components(self, stt_model: str):
        self.logger.info("Initializing components...")
        
        self.voice_pipeline = VoicePipeline(
            stt_model=stt_model,
            llm_type=self.llm_type,
            device=self.device
        )
        
        self.schedule_classifier = ScheduleClassifier(llm_type=self.llm_type)
        
        self.logger.info("All components initialized successfully")
    
    def process_voice_command(self, audio_input_path: str) -> Dict[str, Any]:
        start_time = time.time()
        
        try:
            self.logger.info(f"Processing voice command: {audio_input_path}")
            
            voice_result = self.voice_pipeline.process_voice(audio_input_path)
            
            if not voice_result["success"]:
                return voice_result
            
            user_message = voice_result["user_message"]
            
            schedule_result = self.schedule_classifier.classify_schedule(user_message)
            
            if schedule_result.get("is_schedule"):
                schedule_info = schedule_result["schedule_info"]
                ai_response = f"일정이 등록되었습니다. 제목: {schedule_info['title']}, 시간: {schedule_info['datetime']}, 카테고리: {schedule_info['category']}"
            elif schedule_result.get("needs_clarification"):
                questions = schedule_result["questions"]
                ai_response = "추가 정보가 필요합니다. " + " ".join(questions)
            else:
                ai_response = voice_result["ai_response"]
            
            audio_response = self.voice_pipeline._process_tts(ai_response)
            
            total_time = time.time() - start_time
            
            return self._create_success_response(
                user_message, ai_response, audio_response, 
                schedule_result, total_time
            )
            
        except Exception as e:
            self.logger.error(f"Voice command processing failed: {e}")
            return self._create_error_response(f"처리 중 오류가 발생했습니다: {str(e)}")
    
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