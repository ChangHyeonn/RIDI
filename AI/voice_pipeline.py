import sys
import os
import time
import logging
from typing import Dict, Any

# AI 모듈 import
sys.path.append(os.path.join(os.path.dirname(__file__), 'Models'))
from Models.STT import WhisperSTT
from Models.LLM import LLMFactory
from Models.TTS import TTS

class VoicePipeline:
    """STT → LLM → TTS 음성 처리 파이프라인"""
    
    def __init__(self, 
                 stt_model: str = "small",
                 llm_type: str = "gemini",  # "gpt" or "gemini"
                 device: str = "auto"):
        self.device = self._get_device(device)
        self.llm_type = llm_type
        self._setup_logging()
        self._initialize_components(stt_model)
        self.logger.info(f"Voice Pipeline initialized successfully on {self.device}")
    
    def _get_device(self, device: str) -> str:
        if device == "auto":
            import torch
            # CUDA 확인 (가장 빠름)
            if torch.cuda.is_available():
                return "cuda"
            # CPU (MPS 호환성 문제로 인해 기본값)
            else:
                return "cpu"
        return device
    
    def _setup_logging(self):
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
    
    def _initialize_components(self, stt_model: str):
        self.logger.info("Initializing AI components...")
        
        self.stt = WhisperSTT(model_name=stt_model, device=self.device)
        self.stt.optimize_for_korean(True)
        
        # LLM 초기화 (GPT/Gemini 선택 가능)
        self.llm = LLMFactory.create_llm(self.llm_type)
        
        self.tts = TTS()
        
        self.logger.info("All AI components initialized")
    
    def process_voice_input(self, audio_path: str) -> Dict[str, Any]:
        """
        음성 입력을 처리하는 메인 파이프라인
        
        Args:
            audio_path: 음성 파일 경로
            
        Returns:
            Dict[str, Any]: 처리 결과
        """
        start_time = time.time()
        
        try:
            # Step 1: STT (음성 → 텍스트)
            transcribed_text = self._process_stt(audio_path)
            if not transcribed_text:
                return self._create_error_response("음성을 텍스트로 변환할 수 없습니다.")
            
            # Step 2: LLM (텍스트 → 응답)
            llm_response = self._process_llm(transcribed_text)
            
            # Step 3: TTS (텍스트 → 음성)
            audio_output = self._process_tts(llm_response)
            
            total_time = time.time() - start_time
            
            return self._create_success_response(
                transcribed_text, llm_response, audio_output, total_time
            )
            
        except Exception as e:
            self.logger.error(f"Pipeline processing failed: {e}")
            return self._create_error_response(str(e))
    
    def _process_stt(self, audio_path: str) -> str:
        """STT 처리"""
        self.logger.info("Processing STT...")
        transcribed_text = self.stt.transcribe(audio_path, use_preprocessing=True)
        self.logger.info(f"STT 결과: {transcribed_text}")
        return transcribed_text
    
    def _process_llm(self, text: str) -> str:
        """LLM 처리"""
        self.logger.info("Processing LLM...")
        llm_response = self.llm.generate_response(text)
        self.logger.info(f"LLM 응답: {llm_response}")
        return llm_response
    
    def _process_tts(self, text: str) -> bytes:
        """TTS 처리"""
        self.logger.info("Processing TTS...")
        audio_output = self.tts.generate_from_llm_response(text)
        return audio_output
    
    def _create_success_response(self, transcribed_text: str, llm_response: str, 
                               audio_output: bytes, total_time: float) -> Dict[str, Any]:
        """성공 응답 생성"""
        return {
            "success": True,
            "transcribed_text": transcribed_text,
            "llm_response": llm_response,
            "audio_output": audio_output,
            "total_time": round(total_time, 2)
        }
    
    def _create_error_response(self, error_message: str) -> Dict[str, Any]:
        """오류 응답 생성"""
        return {
            "success": False,
            "error": error_message,
            "transcribed_text": None,
            "llm_response": None,
            "audio_output": None
        }
    
    def get_pipeline_info(self) -> Dict[str, Any]:
        """파이프라인 정보 반환"""
        return {
            "pipeline_name": "STT → LLM → TTS",
            "device": self.device,
            "components": {
                "stt": self.stt.get_model_info(),
                "llm": self.llm.get_model_info(),
                "tts": self.tts.get_model_info()
            }
        }
    
    def __del__(self):
        """리소스 정리"""
        if hasattr(self, 'stt'):
            del self.stt
        if hasattr(self, 'llm'):
            del self.llm
        if hasattr(self, 'tts'):
            del self.tts

def main():
    """메인 함수 - 파이프라인 테스트"""
    print("🎤 Voice Pipeline 테스트")
    print("=" * 50)
    
    # 파이프라인 초기화 (device 자동 선택)
    pipeline = VoicePipeline(
        stt_model="small",
        llm_model="meta-llama/Llama-3-8B-Instruct",
        use_quantization=True,
        device="auto"  # 자동으로 MPS/CUDA/CPU 선택
    )
    
    # 파이프라인 정보 출력
    pipeline_info = pipeline.get_pipeline_info()
    print(f"📊 파이프라인 정보:")
    print(f"  이름: {pipeline_info['pipeline_name']}")
    print(f"  Device: {pipeline_info['device']}")
    print(f"  STT 모델: {pipeline_info['components']['stt']['model_name']}")
    print(f"  LLM 모델: {pipeline_info['components']['llm']['model_name']}")
    print(f"  TTS 모델: {pipeline_info['components']['tts']['model_name']}")
    
    # 테스트할 음성 파일들
    test_files = [
        "test_audio.wav",
        "sample_voice.mp3", 
        "recording.m4a",
        "voice_sample.wav"
    ]
    
    # 존재하는 파일 찾기
    audio_file = None
    for file in test_files:
        if os.path.exists(file):
            audio_file = file
            break
    
    if not audio_file:
        print("\n❌ 테스트용 음성 파일을 찾을 수 없습니다.")
        print("💡 다음 중 하나의 파일을 준비해주세요:")
        for file in test_files:
            print(f"  - {file}")
        print("\n또는 직접 파일 경로를 입력하세요:")
        audio_file = input("파일 경로: ").strip()
        
        if not audio_file or not os.path.exists(audio_file):
            print("❌ 유효한 음성 파일이 없습니다.")
            return
    
    # 파이프라인 테스트 실행
    print(f"\n🎯 파이프라인 테스트 시작: {audio_file}")
    result = pipeline.process_voice_input(audio_file)
    
    if result["success"]:
        print(f"\n✅ 파이프라인 성공!")
        print(f"📝 STT 결과: {result['transcribed_text']}")
        print(f"🤖 LLM 응답: {result['llm_response']}")
        print(f"⏱️  총 처리 시간: {result['total_time']}초")
    else:
        print(f"\n❌ 파이프라인 실패: {result['error']}")

if __name__ == "__main__":
    main() 