import os
import logging
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional

# Base LLM class
class BaseLLM(ABC):
    @abstractmethod
    def generate_response(self, user_input: str) -> str:
        pass
    
    @abstractmethod
    def get_model_info(self) -> Dict[str, Any]:
        pass

# GPT LLM Implementation
class GPTLLM(BaseLLM):
    def __init__(self, api_key: Optional[str] = None, model: str = "gpt-3.5-turbo"):
        self.model = model
        self.api_key = api_key or os.getenv('OPENAI_API_KEY')
        
        if not self.api_key:
            raise ValueError("OpenAI API key is required. Set OPENAI_API_KEY environment variable.")
        
        self._setup_logging()
        self._setup_korean_prompt()
        self.logger.info(f"GPT LLM initialized successfully with model: {self.model}")
    
    def _setup_logging(self):
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
    
    def _setup_korean_prompt(self):
        """한국어 음성 명령 처리를 위한 시스템 프롬프트 설정"""
        self.korean_system_prompt = """당신은 한국어 음성 명령을 처리하는 AI 어시스턴트입니다. 
사용자의 음성 명령을 이해하고 적절한 응답을 제공하세요. 
특히 일정 관리, 캘린더 관련 명령에 대해 도움을 주세요."""
    
    def generate_response(self, user_input: str) -> str:
        """사용자 입력에 대한 응답 생성"""
        try:
            import openai
            openai.api_key = self.api_key
            
            response = openai.ChatCompletion.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": self.korean_system_prompt},
                    {"role": "user", "content": user_input}
                ],
                max_tokens=512,
                temperature=0.7
            )
            
            return response.choices[0].message.content.strip()
            
        except Exception as e:
            self.logger.error(f"GPT response generation failed: {e}")
            return "죄송합니다. 응답을 생성하는 중에 오류가 발생했습니다."
    
    def get_model_info(self) -> Dict[str, Any]:
        """모델 정보 반환"""
        return {
            "model_name": self.model,
            "provider": "OpenAI",
            "supported_languages": ["ko", "en"],
            "features": {
                "korean_optimization": True,
                "context_understanding": True,
                "command_processing": True,
                "response_generation": True
            }
        }

# Gemini LLM Implementation
class GeminiLLM(BaseLLM):
    def __init__(self, api_key: Optional[str] = None, model: str = "gemini-pro"):
        self.model_name = model
        self.api_key = api_key or os.getenv('GOOGLE_API_KEY')
        
        if not self.api_key:
            raise ValueError("Google API key is required. Set GOOGLE_API_KEY environment variable.")
        
        self._setup_logging()
        self._setup_korean_prompt()
        self._initialize_model()
        self.logger.info(f"Gemini LLM initialized successfully with model: {self.model_name}")
    
    def _setup_logging(self):
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
    
    def _setup_korean_prompt(self):
        """한국어 음성 명령 처리를 위한 시스템 프롬프트 설정"""
        self.korean_system_prompt = """당신은 한국어 음성 명령을 처리하는 AI 어시스턴트입니다. 
사용자의 음성 명령을 이해하고 적절한 응답을 제공하세요. 
특히 일정 관리, 캘린더 관련 명령에 대해 도움을 주세요."""
    
    def _initialize_model(self):
        """Gemini 모델 초기화"""
        try:
            import google.generativeai as genai
            genai.configure(api_key=self.api_key)
            self.model = genai.GenerativeModel(self.model_name)
        except Exception as e:
            self.logger.error(f"Failed to initialize Gemini model: {e}")
            raise
    
    def generate_response(self, user_input: str) -> str:
        """사용자 입력에 대한 응답 생성"""
        try:
            # 시스템 프롬프트와 사용자 입력 결합
            full_prompt = f"{self.korean_system_prompt}\n\n사용자: {user_input}"
            
            response = self.model.generate_content(full_prompt)
            
            if response.text:
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

# LLM Factory for easy model selection
class LLMFactory:
    @staticmethod
    def create_llm(model_type: str = "gemini", **kwargs) -> BaseLLM:
        """
        LLM 모델 생성 팩토리
        
        Args:
            model_type: "gpt" or "gemini"
            **kwargs: 모델별 추가 파라미터
        """
        if model_type.lower() == "gpt":
            return GPTLLM(**kwargs)
        elif model_type.lower() == "gemini":
            return GeminiLLM(**kwargs)
        else:
            raise ValueError(f"Unsupported model type: {model_type}. Use 'gpt' or 'gemini'")

# Llama3LLM 클래스는 삭제됨 - GPT/Gemini만 지원