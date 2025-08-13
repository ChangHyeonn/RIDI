import os
import logging
import sys
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional

# 프롬프트 매니저 import
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from Config.prompts import PromptManager

class BaseLLM(ABC):
    @abstractmethod
    def generate_response(self, user_input: str) -> str:
        pass
    
    @abstractmethod
    def get_model_info(self) -> Dict[str, Any]:
        pass

class LLM(BaseLLM):
    """Gemini 기반 LLM 클래스"""
    
    def __init__(self, model_name: str = "gemini-1.5-flash", **kwargs):
        self._setup_logging()
        self.model_name = model_name
        self.api_key = os.getenv('GOOGLE_API_KEY')
        
        # 한국어 프롬프트 설정
        self.korean_system_prompt = PromptManager.get_korean_assistant_prompt()
        
        if not self.api_key:
            self.logger.warning("Google API key not found. LLM will be disabled.")
            self.model = None
            return
        
        try:
            import google.generativeai as genai
            genai.configure(api_key=self.api_key)
            
            # 사용 가능한 모델 목록 확인
            models = genai.list_models()
            available_models = [model.name for model in models]
            self.logger.info(f"Available models: {available_models}")
            
            # 지정된 모델 또는 기본 모델 사용
            if f'models/{self.model_name}' in available_models:
                self.model = genai.GenerativeModel(self.model_name)
            elif 'models/gemini-1.5-pro' in available_models:
                self.model = genai.GenerativeModel('gemini-1.5-pro')
                self.model_name = 'gemini-1.5-pro'
            elif 'models/gemini-1.5-flash' in available_models:
                self.model = genai.GenerativeModel('gemini-1.5-flash')
                self.model_name = 'gemini-1.5-flash'
            else:
                # 기본값으로 gemini-1.5-flash 시도
                self.model = genai.GenerativeModel('gemini-1.5-flash')
                self.model_name = 'gemini-1.5-flash'
            
            # 간단한 테스트로 모델 상태 확인
            test_response = self.model.generate_content("테스트")
            if test_response and test_response.text:
                self.logger.info(f"Gemini LLM ({self.model_name}) initialized successfully")
            else:
                self.logger.warning("Gemini model test failed")
                self.model = None
                
        except Exception as e:
            self.logger.error(f"Failed to initialize Gemini LLM: {e}")
            self.model = None
    
    def _setup_logging(self):
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
    

    
    def generate_response(self, user_input: str) -> str:
        # 모델이 초기화되지 않았는지 확인
        if not self.model:
            self.logger.warning("Gemini model is not initialized. API key may be missing.")
            return "죄송합니다. AI 모델이 초기화되지 않았습니다. API 키를 확인해주세요."
        
        try:
            full_prompt = f"{self.korean_system_prompt}\n\n사용자: {user_input}"
            
            response = self.model.generate_content(full_prompt)
            
            if response and response.text:
                return response.text.strip()
            else:
                return "죄송합니다. 응답을 생성할 수 없습니다."
                
        except Exception as e:
            self.logger.error(f"Gemini response generation failed: {e}")
            return "죄송합니다. 응답을 생성하는 중에 오류가 발생했습니다."
    
    def get_model_info(self) -> Dict[str, Any]:
        """모델 정보 반환"""
        return {
            "model_name": self.model_name,
            "provider": "Google",
            "supported_languages": ["ko", "en"],
            "features": {
                "korean_optimization": True,
                "context_understanding": True,
                "command_processing": True,
                "response_generation": True,
                "multimodal": True
            }
        }

    def generate(self, prompt: str, max_tokens: int = 1000) -> str:
        """텍스트 생성"""
        if not self.model:
            return "죄송합니다. AI 모델이 초기화되지 않았습니다. API 키를 확인해주세요."
        
        try:
            response = self.model.generate_content(prompt)
            return response.text
        except Exception as e:
            self.logger.error(f"Text generation failed: {e}")
            return f"텍스트 생성 중 오류가 발생했습니다: {str(e)}"

class LLMFactory:
    @staticmethod
    def create_llm(model_type: str = "gemini", **kwargs) -> BaseLLM:
        """LLM 인스턴스 생성 (Gemini만 지원)"""
        if model_type.lower() == "gemini":
            return LLM(**kwargs)
        else:
            raise ValueError(f"Unsupported model type: {model_type}. Only 'gemini' is supported.")
    
    @staticmethod
    def create_default_llm(**kwargs) -> BaseLLM:
        """기본 LLM 인스턴스 생성"""
        return LLM(**kwargs)

