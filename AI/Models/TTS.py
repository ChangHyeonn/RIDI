import logging
import re
import tempfile
import os
from typing import Union, Dict, Any
from gtts import gTTS

class TTS:
    def __init__(self, model_name=None):
        self.model_name = model_name or "google_tts"
        self._setup_logging()
        self.logger.info("Google TTS initialized successfully")
    
    def _setup_logging(self):
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
    
    def generate_from_llm_response(self, llm_response: str, output_path=None) -> Union[bytes, str]:
        try:
            processed_text = self._preprocess_korean_text(llm_response)
            return self._generate_speech(processed_text, output_path)
        except Exception as e:
            self.logger.error(f"LLM response to speech failed: {e}")
            raise
    
    def _preprocess_korean_text(self, text: str) -> str:
        """한국어 텍스트 전처리"""
        if not text:
            return ""
        
        # 텍스트 정리
        text = re.sub(r'\s+', ' ', text)
        text = text.strip()
        
        # 긴 텍스트 자르기 (TTS 제한)
        if len(text) > 500:
            sentences = text.split('.')
            text = '. '.join(sentences[:3]) + '.'
        
        return text.strip()
    
    def _generate_speech(self, text: str, output_path=None) -> Union[bytes, str]:
        try:
            if not output_path:
                with tempfile.NamedTemporaryFile(delete=False, suffix='.mp3') as tmp_file:
                    output_path = tmp_file.name
            
            tts = gTTS(text=text, lang='ko', slow=False)
            tts.save(output_path)
            
            with open(output_path, 'rb') as f:
                audio_data = f.read()
            
            if output_path.startswith('/tmp/'):
                os.unlink(output_path)
            
            return audio_data
        except Exception as e:
            self.logger.error(f"Speech generation failed: {e}")
            raise
    
    def get_model_info(self) -> Dict[str, Any]:
        return {
            "model_name": self.model_name,
            "model_type": "google_tts",
            "quantization": "N/A",
            "supported_languages": ["ko", "en", "ja", "zh", "es", "fr", "de", "it", "pt", "ru", "ar", "hi"],
            "features": {
                "quality": "High",
                "speed": "Fast",
                "voice_naturalness": "High",
                "offline": False,
                "cost": "Free (with limits)",
                "model_size": "N/A (Cloud-based)",
                "memory_usage": "Low"
            }
        }
    
    def change_model(self, model_name: str):
        self.logger.info(f"Changing TTS model to: {model_name}")
        self.model_name = model_name
    
    def __del__(self):
        pass
