#!/usr/bin/env python3
"""
Voice Chat Pipeline - STT + LLM + TTS 통합 음성 대화 시스템
음성 입력 → 텍스트 변환 → AI 응답 → 음성 출력
"""

import sys
import os
import time
import logging
import tempfile
import soundfile as sf
import numpy as np
from datetime import datetime
from typing import Dict, Any, Optional
from dotenv import load_dotenv

# AI 모듈 import
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'Models'))
from Models.STT import WhisperSTT
from Models.LLM import LLMFactory
from Models.TTS import TTS

class VoiceChatPipeline:
    """음성 대화 파이프라인"""
    
    def __init__(self, 
                 stt_model: str = "small",
                 llm_type: str = None,  # "gpt" or "gemini", None이면 .env에서 가져옴
                 device: str = "auto"):
        # .env 파일 로드
        load_dotenv()
        
        self.device = self._get_device(device)
        self.llm_type = llm_type or os.getenv('LLM_MODEL', 'gemini')
        
        self._setup_logging()
        self._initialize_components(stt_model)
        self.logger.info(f"Voice Chat Pipeline initialized successfully on {self.device}")
    
    def _get_device(self, device: str) -> str:
        """사용 가능한 최적의 device 선택"""
        if device == "auto":
            import torch
            if torch.cuda.is_available():
                return "cuda"
            else:
                return "cpu"
        return device
    
    def _setup_logging(self):
        """로깅 설정"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
    
    def _initialize_components(self, stt_model: str):
        """AI 컴포넌트 초기화"""
        self.logger.info("Initializing AI components...")
        
        # STT 초기화
        self.stt = WhisperSTT(model_name=stt_model, device=self.device)
        self.stt.optimize_for_korean(True)
        
        # LLM 초기화 (GPT/Gemini 선택 가능)
        self.llm = LLMFactory.create_llm(self.llm_type)
        
        # TTS 초기화
        self.tts = TTS()
        
        self.logger.info("All AI components initialized successfully")
    
    def chat_with_voice(self, audio_input_path: str) -> Dict[str, Any]:
        """
        음성으로 대화하는 메인 함수
        
        Args:
            audio_input_path: 입력 음성 파일 경로
            
        Returns:
            Dict[str, Any]: 대화 결과
        """
        start_time = time.time()
        
        try:
            self.logger.info(f"Starting voice chat with: {audio_input_path}")
            
            # Step 1: STT (음성 → 텍스트)
            user_message = self._process_stt(audio_input_path)
            if not user_message:
                return self._create_error_response("음성을 텍스트로 변환할 수 없습니다.")
            
            # Step 2: LLM (텍스트 → AI 응답)
            ai_response = self._process_llm(user_message)
            
            # Step 3: TTS (AI 응답 → 음성)
            audio_response = self._process_tts(ai_response)
            
            total_time = time.time() - start_time
            
            return self._create_success_response(
                user_message, ai_response, audio_response, total_time
            )
            
        except Exception as e:
            self.logger.error(f"Voice chat failed: {e}")
            return self._create_error_response(str(e))
    
    def _process_stt(self, audio_path: str) -> str:
        """STT 처리"""
        self.logger.info("Processing STT...")
        transcribed_text = self.stt.transcribe(audio_path, use_preprocessing=True)
        self.logger.info(f"STT 결과: {transcribed_text}")
        return transcribed_text
    
    def _process_llm(self, user_message: str) -> str:
        """LLM 처리"""
        self.logger.info("Processing LLM...")
        
        # 대화형 프롬프트 구성
        conversation_prompt = f"""
당신은 친근하고 도움이 되는 AI 어시스턴트입니다.
사용자의 메시지에 대해 자연스럽고 유용한 응답을 제공하세요.

사용자: {user_message}
AI: """
        
        llm_response = self.llm.generate_response(conversation_prompt)
        self.logger.info(f"LLM 응답: {llm_response}")
        return llm_response
    
    def _process_tts(self, text: str) -> bytes:
        """TTS 처리"""
        self.logger.info("Processing TTS...")
        audio_response = self.tts.generate_from_llm_response(text)
        self.logger.info("TTS 완료")
        return audio_response
    
    def _create_success_response(self, user_message: str, ai_response: str, 
                               audio_response: bytes, total_time: float) -> Dict[str, Any]:
        """성공 응답 생성"""
        return {
            "success": True,
            "user_message": user_message,
            "ai_response": ai_response,
            "audio_response": audio_response,
            "processing_time": total_time,
            "timestamp": datetime.now().isoformat(),
            "model_info": {
                "stt_model": self.stt.model_name,
                "llm_type": self.llm_type,
                "tts_model": self.tts.model_name
            }
        }
    
    def _create_error_response(self, error_message: str) -> Dict[str, Any]:
        """에러 응답 생성"""
        return {
            "success": False,
            "error": error_message,
            "timestamp": datetime.now().isoformat()
        }
    
    def get_pipeline_info(self) -> Dict[str, Any]:
        """파이프라인 정보 반환"""
        return {
            "device": self.device,
            "llm_type": self.llm_type,
            "components": {
                "stt": self.stt.get_model_info(),
                "llm": self.llm.get_model_info(),
                "tts": self.tts.get_model_info()
            }
        }
    
    def change_llm_model(self, llm_type: str):
        """LLM 모델 변경"""
        self.logger.info(f"Changing LLM model to: {llm_type}")
        self.llm_type = llm_type
        self.llm = LLMFactory.create_llm(llm_type)
        self.logger.info(f"LLM model changed successfully to {llm_type}")

def main():
    """테스트용 메인 함수"""
    # .env 파일에서 API 키와 모델 설정을 자동으로 가져옴
    
    # 파이프라인 초기화
    pipeline = VoiceChatPipeline(
        stt_model="small",
        llm_type=None,  # .env 파일에서 자동으로 가져옴
        device="auto"
    )
    
    # 파이프라인 정보 출력
    info = pipeline.get_pipeline_info()
    print("🎤 Voice Chat Pipeline Info:")
    print(f"Device: {info['device']}")
    print(f"LLM Type: {info['llm_type']}")
    print(f"STT Model: {info['components']['stt']['model_name']}")
    print(f"TTS Model: {info['components']['tts']['model_name']}")
    
    # 테스트 (실제 음성 파일이 필요)
    # result = pipeline.chat_with_voice("test_audio.wav")
    # if result['success']:
    #     print(f"사용자: {result['user_message']}")
    #     print(f"AI: {result['ai_response']}")
    #     print(f"처리 시간: {result['processing_time']:.2f}초")
    # else:
    #     print(f"오류: {result['error']}")

if __name__ == "__main__":
    main() 