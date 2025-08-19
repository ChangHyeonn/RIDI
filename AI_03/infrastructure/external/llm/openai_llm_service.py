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
        """의도 분석 프롬프트 생성"""
        from datetime import datetime
        current_date = datetime.now().strftime("%Y-%m-%d")
        
        return f"""
사용자 요청을 분석하여 의도를 파악해주세요.

현재 날짜: {current_date}
사용자 요청: {text}

다음 카테고리 중 하나로 분류:
- schedule_add: 일정 추가 요청
- schedule_read: 일정 조회 요청  
- schedule_delete: 일정 삭제 요청
- other: 일반 대화

JSON 형식으로만 응답:
{{
    "intent": "카테고리명",
    "confidence": 0.0-1.0,
    "requires_extraction": true/false
}}
"""
    
    def _get_extraction_prompt(self, text: str) -> str:
        """정보 추출 프롬프트 생성"""
        from datetime import datetime
        current_date = datetime.now().strftime("%Y-%m-%d")
        
        return f"""
일정 관련 정보를 추출해주세요.

현재 날짜: {current_date}
사용자 요청: {text}

중요: 반드시 구체적이고 의미있는 일정 제목이 명시되어야 합니다.
"일정", "예약", "할 일" 같은 비구체적 제목은 거부합니다.
예시: "병원 진료", "친구 만남", "회사 회의" 같은 구체적 내용이 필요합니다.

시간 변환:
- "내일" = 현재 날짜 + 1일
- "모레" = 현재 날짜 + 2일
- "다음 주" = 현재 날짜 + 7일
- "오전/오후" = 24시간 형식

카테고리 및 중요도 설정 규칙:
- 건강: 병원, 치과, 검진, 약 복용, 운동, 다이어트, 건강관리, 예방접종, 물리치료, 심리상담, 건강검진 등 모든 건강 관련 일정 (is_important = true)
- 경조사: 결혼식, 장례식, 돌있을, 생일잉이, 기념일 등 경조사 관련 일정 (is_important = false)
- 일반: 그 외 모든 일상적인 일정 (is_important = false)

추출 규칙:
1. 구체적인 일정 내용이 없으면 title을 비워두세요 ("")
2. 명확한 날짜/시간이 없으면 해당 필드를 비워두세요
3. 추측이나 가정으로 정보를 만들지 마세요

JSON 형식으로만 응답:
{{
    "title": "구체적인 일정 제목 (비구체적이면 빈 문자열)",
    "date": "YYYY-MM-DD (명시되지 않으면 빈 문자열)",
    "time": "HH:MM (명시되지 않으면 빈 문자열)",
    "category": "경조사/일반/건강",
    "is_important": "건강 카테고리인 경우에만 true, 경조사와 일반은 false",
    "location": "장소 (있는 경우)",
    "description": "추가 설명 (있는 경우)"
}}
"""
