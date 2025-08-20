#!/usr/bin/env python3
"""
OpenAI LLM Service Implementation
OpenAI LLM 서비스 구현 (어댑터)
"""

import json
import time
import requests
from typing import Dict, Any

from shared.logging.logger import LoggerFactory
from shared.config.settings import LLMConfig
from core.entities.text_request import IntentAnalysis
from core.interfaces.services.llm_service import ILLMService


class OpenAILLMService(ILLMService):
    """OpenAI LLM 서비스 구현"""
    
    def __init__(self, config: LLMConfig):
        self.config = config
        self.logger = LoggerFactory.get_logger(__name__)
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {config.api_key}'
        })
        
        if not config.api_key:
            self.logger.warning("OpenAI API key not provided")
    
    def analyze_intent(self, text: str) -> IntentAnalysis:
        """의도 분석"""
        try:
            prompt = self._get_intent_prompt(text)
            response = self._chat_completion(prompt, max_tokens=200)
            
            # AI_02 스타일 로그: LLM 응답 로깅
            self.logger.debug(f"LLM intent response: {response}")
            
            # JSON 파싱
            try:
                analysis_data = json.loads(response)
                intent_category = analysis_data.get('intent', 'other')
                confidence = analysis_data.get('confidence', 0.5)
                
                # AI_02 스타일 로그: 분석 결과
                self.logger.info(f"LLM intent analysis: {text} -> {intent_category} (confidence: {confidence})")
                
                return IntentAnalysis(
                    category=intent_category,
                    confidence=confidence,
                    extracted_info={},
                    raw_analysis=response
                )
            except json.JSONDecodeError:
                self.logger.warning(f"Failed to parse intent analysis: {response}")
                return IntentAnalysis(
                    category='other',
                    confidence=0.3,
                    extracted_info={},
                    raw_analysis=response
                )
                
        except Exception as e:
            self.logger.error(f"Intent analysis failed: {e}")
            return IntentAnalysis(
                category='other',
                confidence=0.1,
                extracted_info={},
                raw_analysis=str(e)
            )
    
    def extract_schedule_info(self, text: str) -> Dict[str, Any]:
        """일정 정보 추출"""
        try:
            prompt = self._get_extraction_prompt(text)
            response = self._chat_completion(prompt, max_tokens=300)
            
            # AI_02 스타일 로그: LLM 응답 로깅
            self.logger.debug(f"LLM extraction response: {response}")
            
            # JSON 파싱
            try:
                schedule_info = json.loads(response)
                
                # AI_02 스타일 로그: 추출 결과
                self.logger.info(f"LLM schedule extraction: {text} -> {schedule_info}")
                
                return schedule_info
            except json.JSONDecodeError:
                self.logger.warning(f"Failed to parse schedule info: {response}")
                return {}
                
        except Exception as e:
            self.logger.error(f"Schedule extraction failed: {e}")
            return {}
    
    def generate_response(self, prompt: str, max_tokens: int = 1000) -> str:
        """텍스트 응답 생성"""
        try:
            return self._chat_completion(prompt, max_tokens)
        except Exception as e:
            self.logger.error(f"Response generation failed: {e}")
            return "죄송합니다. 응답을 생성하는 중에 오류가 발생했습니다."
    
    def get_model_info(self) -> Dict[str, Any]:
        """모델 정보 반환"""
        return {
            'provider': 'openai',
            'model': self.config.model_name,
            'max_tokens': self.config.max_tokens,
            'temperature': self.config.temperature
        }
    
    def _chat_completion(self, prompt: str, max_tokens: int = None) -> str:
        """OpenAI Chat Completion API 호출"""
        if not self.config.api_key:
            raise Exception("OpenAI API key not configured")
        
        max_tokens = max_tokens or self.config.max_tokens
        
        payload = {
            'model': self.config.model_name,
            'messages': [
                {'role': 'system', 'content': '당신은 일정 관리를 도와주는 한국어 AI 어시스턴트입니다.'},
                {'role': 'user', 'content': prompt}
            ],
            'max_tokens': max_tokens,
            'temperature': self.config.temperature
        }
        
        # 재시도 로직 (지수 백오프)
        for attempt in range(5):
            try:
                response = self.session.post(
                    'https://api.openai.com/v1/chat/completions',
                    json=payload,
                    timeout=30
                )
                
                if response.status_code == 200:
                    data = response.json()
                    return data['choices'][0]['message']['content'].strip()
                elif response.status_code == 429:
                    # Rate limit - 지수 백오프
                    wait_time = (2 ** attempt) + 1
                    self.logger.warning(f"Rate limit hit, waiting {wait_time}s (attempt {attempt + 1})")
                    time.sleep(wait_time)
                    continue
                else:
                    error_msg = f"OpenAI API error: {response.status_code} - {response.text}"
                    self.logger.error(error_msg)
                    raise Exception(error_msg)
                    
            except requests.exceptions.RequestException as e:
                self.logger.error(f"Request failed (attempt {attempt + 1}): {e}")
                if attempt == 4:  # 마지막 시도
                    raise
                time.sleep(2 ** attempt)
        
        raise Exception("OpenAI API call failed after all retries")
    
    def _get_intent_prompt(self, text: str) -> str:
        """의도 분석 프롬프트 생성 (Config/prompts.py 사용)"""
        from Config.prompts import PromptManager
        return PromptManager.get_intent_classification_prompt(text)
    
    def _get_extraction_prompt(self, text: str) -> str:
        """정보 추출 프롬프트 생성 (Config/prompts.py 사용)"""
        from Config.prompts import PromptManager
        return PromptManager.get_schedule_extraction_prompt(text)
