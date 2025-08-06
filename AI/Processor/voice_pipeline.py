#!/usr/bin/env python3
"""
Voice Pipeline - 기본 음성 처리 파이프라인
STT → LLM → TTS 기본 처리
"""

import sys
import os
import time
import logging
import tempfile
import soundfile as sf
import numpy as np
from datetime import datetime
from typing import Dict, Any
from dotenv import load_dotenv

# AI 모듈 import
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from Models.STT import WhisperSTT
from Models.LLM import LLMFactory
from Models.TTS import TTS

class VoicePipeline:
    """기본 음성 처리 파이프라인"""
    
    def __init__(self, 
                 stt_model: str = "small",
                 llm_type: str = None,
                 device: str = "auto"):
        load_dotenv()
        
        self.device = self._get_device(device)
        self.llm_type = llm_type or os.getenv('LLM_MODEL', 'gemini')
        
        self._setup_logging()
        self._initialize_components(stt_model)
        self.logger.info(f"Voice Pipeline initialized successfully")
    
    def _get_device(self, device: str) -> str:
        if device == "auto":
            import torch
            if torch.cuda.is_available():
                return "cuda"
            else:
                return "cpu"
        return device
    
    def _setup_logging(self):
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
    
    def _initialize_components(self, stt_model: str):
        self.logger.info("Initializing AI components...")
        
        self.stt = WhisperSTT(model_name=stt_model, device=self.device)
        self.stt.optimize_for_korean(True)
        
        self.llm = LLMFactory.create_llm(self.llm_type)
        
        self.tts = TTS()
        
        self.logger.info("All AI components initialized successfully")
    
    def process_voice(self, audio_input_path: str) -> Dict[str, Any]:
        start_time = time.time()
        
        try:
            self.logger.info(f"Processing voice: {audio_input_path}")
            
            user_message = self._process_stt(audio_input_path)
            if not user_message:
                return self._create_error_response("음성을 텍스트로 변환할 수 없습니다.")
            
            time.sleep(2)
            ai_response = self._process_llm(user_message)
            
            audio_response = self._process_tts(ai_response)
            
            total_time = time.time() - start_time
            
            return self._create_success_response(
                user_message, ai_response, audio_response, total_time
            )
            
        except Exception as e:
            self.logger.error(f"Voice processing failed: {e}")
            return self._create_error_response(f"처리 중 오류가 발생했습니다: {str(e)}")
    
    def _process_stt(self, audio_path: str) -> str:
        try:
            self.logger.info("Processing STT...")
            text = self.stt.transcribe(audio_path)
            self.logger.info(f"STT Result: {text}")
            return text.strip()
        except Exception as e:
            self.logger.error(f"STT processing failed: {e}")
            return ""
    
    def _process_llm(self, user_message: str) -> str:
        try:
            self.logger.info("Processing LLM...")
            response = self.llm.generate_response(user_message)
            self.logger.info(f"LLM Response: {response}")
            return response
        except Exception as e:
            self.logger.error(f"LLM processing failed: {e}")
            return "죄송합니다. 응답을 생성하는 중에 오류가 발생했습니다."
    
    def _process_tts(self, text: str) -> bytes:
        try:
            self.logger.info("Processing TTS...")
            audio_data = self.tts.generate_from_llm_response(text)
            self.logger.info("TTS processing completed")
            return audio_data
        except Exception as e:
            self.logger.error(f"TTS processing failed: {e}")
            raise
    
    def _create_success_response(self, user_message: str, ai_response: str, 
                               audio_response: bytes, total_time: float) -> Dict[str, Any]:
        return {
            "success": True,
            "user_message": user_message,
            "ai_response": ai_response,
            "audio_response": audio_response,
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
            "pipeline_type": "Basic Voice Pipeline",
            "components": {
                "stt": self.stt.get_model_info(),
                "llm": self.llm.get_model_info(),
                "tts": self.tts.get_model_info()
            },
            "features": {
                "voice_to_voice": True,
                "error_handling": True
            }
        }
    
    def change_llm_model(self, llm_type: str):
        self.llm_type = llm_type
        self.llm = LLMFactory.create_llm(llm_type)
        self.logger.info(f"LLM model changed to: {llm_type}")

 