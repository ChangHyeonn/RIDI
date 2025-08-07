import os
import logging
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional

class BaseLLM(ABC):
    @abstractmethod
    def generate_response(self, user_input: str) -> str:
        pass
    
    @abstractmethod
    def get_model_info(self) -> Dict[str, Any]:
        pass

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

class GeminiLLM(BaseLLM):
    def __init__(self, **kwargs):
        self._setup_logging()
        self.model_name = "gemini-1.5-flash"  # 최신 모델로 업데이트
        self.api_key = os.getenv('GOOGLE_API_KEY')
        
        # 한국어 프롬프트 설정 (API 키와 관계없이)
        self._setup_korean_prompt()
        
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
            
            # gemini-1.5-pro 또는 gemini-1.5-flash 사용
            if 'models/gemini-1.5-pro' in available_models:
                self.model = genai.GenerativeModel('gemini-1.5-pro')
            elif 'models/gemini-1.5-flash' in available_models:
                self.model = genai.GenerativeModel('gemini-1.5-flash')
            else:
                # 기본값으로 gemini-1.5-flash 시도
                self.model = genai.GenerativeModel('gemini-1.5-flash')
            
            # 간단한 테스트로 모델 상태 확인
            test_response = self.model.generate_content("테스트")
            if test_response and test_response.text:
                self.logger.info("Gemini LLM initialized successfully")
            else:
                self.logger.warning("Gemini model test failed")
                self.model = None
                
        except Exception as e:
            self.logger.error(f"Failed to initialize Gemini LLM: {e}")
            self.model = None
    
    def _setup_logging(self):
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
    
    def _setup_korean_prompt(self):
        """한국어 음성 명령 처리를 위한 시스템 프롬프트 설정"""
        self.korean_system_prompt = """당신은 한국어 음성 명령을 처리하는 AI 어시스턴트입니다. 
사용자의 음성 명령을 이해하고 적절한 응답을 제공하세요. 
특히 일정 관리, 캘린더 관련 명령에 대해 도움을 주세요."""
    
    def _initialize_model(self):
        try:
            import google.generativeai as genai
            genai.configure(api_key=self.api_key)
            self.model = genai.GenerativeModel(self.model_name)
        except Exception as e:
            self.logger.error(f"Failed to initialize Gemini model: {e}")
            raise
    
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
        if model_type.lower() == "gpt":
            return GPTLLM(**kwargs)
        elif model_type.lower() == "gemini":
            return GeminiLLM(**kwargs)
        else:
            raise ValueError(f"Unsupported model type: {model_type}. Use 'gpt' or 'gemini'")

