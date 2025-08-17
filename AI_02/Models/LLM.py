import os
import logging
import sys
import time
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

"""
OpenAI GPT 전용 LLM 구현
"""

class LLMFactory:
    @staticmethod
    def create_llm(model_type: str = "openai", **kwargs) -> BaseLLM:
        """LLM 인스턴스 생성 (OpenAI만 지원)"""
        model_type = (model_type or "openai").lower()
        if model_type == "openai":
            return OpenAILLM(**kwargs)
        raise ValueError(f"Unsupported model type: {model_type}. Supported: 'openai'.")
    
    @staticmethod
    def create_default_llm(**kwargs) -> BaseLLM:
        """기본 LLM 인스턴스 생성"""
        return LLMFactory.create_llm(**kwargs)


class OpenAILLM(BaseLLM):
    """OpenAI GPT 모델(Latest: gpt-4o-mini) 기반 LLM 클래스"""

    def __init__(self, model_name: str = "gpt-4o-mini", **kwargs):
        self._setup_logging()
        self.model_name = model_name
        self.korean_system_prompt = PromptManager.get_korean_assistant_prompt()
        self.api_key = os.getenv('OPENAI_API_KEY', '')
        self.base_url = os.getenv('OPENAI_BASE_URL', 'https://api.openai.com/v1')
        if not self.api_key:
            self.logger.warning("OpenAI API key not found. LLM will be disabled.")
            self.session = None
            return
        try:
            import requests  # ensure available
            self.session = requests.Session()
            self.logger.info(f"OpenAI LLM ({self.model_name}) initialized (HTTP client)")
        except Exception as e:
            self.logger.error(f"Failed to init HTTP client: {e}")
            self.session = None

    def _setup_logging(self):
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)

    def generate_response(self, user_input: str) -> str:
        if not self.session:
            self.logger.warning("OpenAI HTTP client is not initialized. API key may be missing.")
            return "죄송합니다. AI 모델이 초기화되지 않았습니다. API 키를 확인해주세요."
        try:
            content = f"{self.korean_system_prompt}\n\n사용자: {user_input}"
            text = self._chat_completion([
                {"role": "system", "content": "당신은 한국어 어시스턴트입니다."},
                {"role": "user", "content": content}
            ], max_tokens=800)
            return (text or "").strip()
        except Exception as e:
            self.logger.error(f"OpenAI response generation failed: {e}")
            return "죄송합니다. 응답을 생성하는 중에 오류가 발생했습니다."

    def get_model_info(self) -> Dict[str, Any]:
        return {
            "model_name": self.model_name,
            "provider": "OpenAI",
            "supported_languages": ["ko", "en"],
            "features": {
                "korean_optimization": True,
                "context_understanding": True,
                "command_processing": True,
                "response_generation": True
            }
        }

    def generate(self, prompt: str, max_tokens: int = 1000) -> str:
        if not self.session:
            return "죄송합니다. AI 모델이 초기화되지 않았습니다. API 키를 확인해주세요."
        try:
            text = self._chat_completion([
                {"role": "system", "content": "JSON만 반환하세요."},
                {"role": "user", "content": prompt}
            ], max_tokens=max_tokens)
            return text
        except Exception as e:
            self.logger.error(f"Text generation failed: {e}")
            return f"텍스트 생성 중 오류가 발생했습니다: {str(e)}"

    def _chat_completion(self, messages, max_tokens=800, temperature=0.2) -> str:
        if not self.session:
            raise RuntimeError("HTTP client not initialized")
        import requests
        url = f"{self.base_url}/chat/completions"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        payload = {
            "model": self.model_name,
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": temperature
        }
        backoff = 1.0
        for attempt in range(5):
            resp = self.session.post(url, headers=headers, json=payload, timeout=30)
            if resp.status_code == 429:
                retry_after = resp.headers.get("Retry-After")
                wait = float(retry_after) if retry_after and retry_after.isdigit() else backoff
                self.logger.warning(f"429 received. Backing off for {wait} seconds (attempt {attempt+1}/5)")
                time.sleep(wait)
                backoff = min(backoff * 2, 16)
                continue
            resp.raise_for_status()
            data = resp.json()
            return ((data.get("choices") or [{}])[0].get("message") or {}).get("content", "")
        raise requests.HTTPError("429 Too Many Requests after retries")

