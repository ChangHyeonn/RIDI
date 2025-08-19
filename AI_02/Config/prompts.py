#!/usr/bin/env python3
"""
Prompt Manager - 목적별 분리된 프롬프트 관리 시스템
"""

from datetime import datetime
from typing import Dict, Any, Optional


class PromptManager:
    """목적별 분리된 프롬프트 관리 클래스"""
    
    # 기본 한국어 시스템 프롬프트 (하위 호환 및 단순 안내용)
    KOREAN_ASSISTANT_SYSTEM_PROMPT = (
        "당신은 한국어 텍스트 요청을 이해하고 도와주는 일정 관리 어시스턴트입니다. "
        "사용자의 요청을 분석하여 일정 추가/조회/삭제 등 필요한 작업을 돕거나, 명확한 안내를 제공합니다."
    )
    
    # ===== 1단계: 의도 분류 프롬프트 =====
    INTENT_CLASSIFICATION_PROMPT = """
당신은 사용자 요청의 의도를 분류하는 AI입니다.

현재 날짜: {current_date}
사용자 요청: {user_request}

다음 카테고리 중 하나로 분류해주세요:
- schedule_add: 일정 추가 요청
- schedule_read: 일정 조회 요청  
- schedule_delete: 일정 삭제 요청
- schedule_update: 일정 수정 요청
- general_conversation: 일반 대화
- error_handling: 오류 상황

JSON 형식으로만 응답:
{{
    "intent": "카테고리명",
    "confidence": 0.0-1.0,
    "requires_extraction": true/false
}}
"""

    # ===== 2단계: 일정 정보 추출 프롬프트 =====
    SCHEDULE_EXTRACTION_PROMPT = """
일정 관련 정보를 추출해주세요.

현재 날짜: {current_date}
사용자 요청: {user_request}

시간 변환 규칙:
- "내일" = 현재 날짜 + 1일
- "모레" = 현재 날짜 + 2일  
- "다음 주" = 현재 날짜 + 7일
- "오전/오후" = 24시간 형식으로 변환

중요도 설정 규칙:
- 건강 관련 일정(병원, 치과, 검진 등): is_important = true
- 그 외 모든 일정: is_important = false

JSON 형식으로만 응답:
{{
    "title": "일정 제목",
    "date": "YYYY-MM-DD",
    "time": "HH:MM",
    "category": "경조사/일반/건강",
    "is_important": "건강 카테고리인 경우에만 true, 나머지는 false",
    "location": "장소 (있는 경우)",
    "description": "추가 설명 (있는 경우)"
}}
"""

    # ===== 3단계: 응답 생성 프롬프트 =====
    RESPONSE_GENERATION_PROMPT = """
사용자 요청에 대한 친화적인 응답을 생성해주세요.

요청: {user_request}
의도: {intent}
추출된 정보: {extracted_info}
처리 결과: {processing_result}

응답 스타일:
- 친화적이고 명확한 한국어
- 존댓말 사용
- 필요한 경우 확인 질문 포함
- 오류 시 해결 방법 제시

JSON 형식으로만 응답:
{{
    "response_text": "사용자에게 보여줄 응답",
    "action_type": "schedule_added/schedule_read/schedule_deleted/error/confirmation",
    "requires_confirmation": true/false,
    "next_action": "추가 작업이 필요한 경우"
}}
"""

    # ===== 일정 관리 전용 프롬프트 =====
    SCHEDULE_MANAGEMENT_PROMPT = """
일정 관리 전문 AI입니다.

현재 날짜: {current_date}
사용자 요청: {user_request}

지원 기능:
1. 일정 추가: 새로운 일정 등록
2. 일정 조회: 기존 일정 확인
3. 일정 삭제: 기존 일정 제거
4. 일정 수정: 기존 일정 변경

중요도 설정 규칙:
- 건강 관련 일정(병원, 치과, 검진 등): is_important = true
- 그 외 모든 일정: is_important = false

JSON 형식으로만 응답:
{{
    "action": "add/read/delete/update",
    "schedule_info": {{
        "title": "일정 제목",
        "datetime": "YYYY-MM-DD HH:MM",
        "category": "경조사/일반/건강",
        "is_important": "건강 카테고리인 경우에만 true, 나머지는 false"
    }},
    "response": "사용자 응답",
    "success": true/false
}}
"""

    # ===== 일반 대화 프롬프트 =====
    GENERAL_CONVERSATION_PROMPT = """
친화적인 AI 어시스턴트입니다.

사용자: {user_request}

응답 스타일:
- 자연스러운 한국어 대화
- 친근하고 도움이 되는 톤
- 필요시 일정 관리 기능 안내

JSON 형식으로만 응답:
{{
    "response_text": "자연스러운 대화 응답",
    "action_type": "conversation",
    "suggestions": ["추천 기능 목록"]
}}
"""

    # ===== 오류 처리 프롬프트 =====
    ERROR_HANDLING_PROMPT = """
오류 상황에 대한 친화적인 응답을 생성해주세요.

오류 유형: {error_type}
오류 내용: {error_message}
사용자 요청: {user_request}

응답 스타일:
- 겁주지 않고 안심시키는 톤
- 해결 방법 제시
- 다시 시도하도록 격려

JSON 형식으로만 응답:
{{
    "response_text": "친화적인 오류 메시지",
    "action_type": "error",
    "suggestions": ["해결 방법 목록"],
    "retry_available": true/false
}}
"""

    # ===== 확인 요청 프롬프트 =====
    CONFIRMATION_PROMPT = """
사용자의 확인이 필요한 작업에 대한 메시지를 생성해주세요.

작업 유형: {action_type}
작업 내용: {action_details}
사용자 요청: {user_request}

확인 메시지 스타일:
- 명확하고 간단한 설명
- "네" 또는 "아니오"로 답변 가능
- 작업의 중요성 강조

JSON 형식으로만 응답:
{{
    "response_text": "확인 요청 메시지",
    "action_type": "confirmation",
    "confirmation_data": {{
        "action": "실행할 작업",
        "details": "작업 세부사항"
    }}
}}
"""

    # ===== 기존 통합 프롬프트 (하위 호환성) =====
    UNIFIED_REQUEST_ANALYSIS_PROMPT = """
당신은 일정 관리 AI 어시스턴트입니다. 사용자의 요청을 분석해주세요.

현재 날짜: {current_date}
사용자 요청: {user_request}

다음 JSON 형식으로만 응답하세요:

{{
    "category": "schedule_add|schedule_read|schedule_delete|other",
    "confidence": 0.8,
    "extracted_info": {{
        "title": "일정 제목",
        "date": "YYYY-MM-DD",
        "time": "HH:MM"
    }}
}}
"""

    # ===== 프롬프트 접근 메서드들 =====
    
    @classmethod
    def get_intent_classification_prompt(cls, user_request: str, current_date: str = None) -> str:
        """의도 분류 프롬프트 반환"""
        if current_date is None:
            current_date = datetime.now().strftime("%Y-%m-%d")
        return cls.INTENT_CLASSIFICATION_PROMPT.format(
            user_request=user_request,
            current_date=current_date
        )
    
    @classmethod
    def get_schedule_extraction_prompt(cls, user_request: str, current_date: str = None) -> str:
        """일정 정보 추출 프롬프트 반환"""
        if current_date is None:
            current_date = datetime.now().strftime("%Y-%m-%d")
        return cls.SCHEDULE_EXTRACTION_PROMPT.format(
            user_request=user_request,
            current_date=current_date
        )
    
    @classmethod
    def get_response_generation_prompt(cls, user_request: str, intent: str, 
                                     extracted_info: dict, processing_result: str) -> str:
        """응답 생성 프롬프트 반환"""
        return cls.RESPONSE_GENERATION_PROMPT.format(
            user_request=user_request,
            intent=intent,
            extracted_info=str(extracted_info),
            processing_result=processing_result
        )
    
    @classmethod
    def get_schedule_management_prompt(cls, user_request: str, current_date: str = None) -> str:
        """일정 관리 프롬프트 반환"""
        if current_date is None:
            current_date = datetime.now().strftime("%Y-%m-%d")
        return cls.SCHEDULE_MANAGEMENT_PROMPT.format(
            user_request=user_request,
            current_date=current_date
        )
    
    @classmethod
    def get_general_conversation_prompt(cls, user_request: str) -> str:
        """일반 대화 프롬프트 반환"""
        return cls.GENERAL_CONVERSATION_PROMPT.format(user_request=user_request)
    
    @classmethod
    def get_error_handling_prompt(cls, error_type: str, error_message: str, user_request: str) -> str:
        """오류 처리 프롬프트 반환"""
        return cls.ERROR_HANDLING_PROMPT.format(
            error_type=error_type,
            error_message=error_message,
            user_request=user_request
        )
    
    @classmethod
    def get_confirmation_prompt(cls, action_type: str, action_details: str, user_request: str) -> str:
        """확인 요청 프롬프트 반환"""
        return cls.CONFIRMATION_PROMPT.format(
            action_type=action_type,
            action_details=action_details,
            user_request=user_request
        )
    
    @classmethod
    def get_unified_request_analysis_prompt(cls, user_request: str, current_date: str = None) -> str:
        """통합 요청 분석 프롬프트 반환 (하위 호환성)"""
        if current_date is None:
            current_date = datetime.now().strftime("%Y-%m-%d")
        return cls.UNIFIED_REQUEST_ANALYSIS_PROMPT.format(
            user_request=user_request,
            current_date=current_date
        )
    
    @classmethod
    def get_korean_assistant_prompt(cls) -> str:
        """기본 한국어 어시스턴트 시스템 프롬프트 반환 (하위 호환)"""
        return cls.KOREAN_ASSISTANT_SYSTEM_PROMPT
    
    @classmethod
    def get_prompt_by_intent(cls, intent: str, **kwargs) -> str:
        """의도에 따른 적절한 프롬프트 반환"""
        prompt_map = {
            "schedule_add": cls.get_schedule_management_prompt,
            "schedule_read": cls.get_schedule_management_prompt,
            "schedule_delete": cls.get_schedule_management_prompt,
            "schedule_update": cls.get_schedule_management_prompt,
            "general_conversation": cls.get_general_conversation_prompt,
            "error_handling": cls.get_error_handling_prompt
        }
        
        if intent in prompt_map:
            return prompt_map[intent](**kwargs)
        else:
            return cls.get_general_conversation_prompt(**kwargs)
    
    @classmethod
    def get_available_prompts(cls) -> Dict[str, str]:
        """사용 가능한 모든 프롬프트 목록 반환"""
        return {
            "intent_classification": "의도 분류 프롬프트",
            "schedule_extraction": "일정 정보 추출 프롬프트",
            "response_generation": "응답 생성 프롬프트",
            "schedule_management": "일정 관리 프롬프트",
            "general_conversation": "일반 대화 프롬프트",
            "error_handling": "오류 처리 프롬프트",
            "confirmation": "확인 요청 프롬프트",
            "unified_analysis": "통합 요청 분석 프롬프트 (하위 호환성)"
        }


# ===== 프롬프트 파이프라인 클래스 =====

class PromptPipeline:
    """단계별 프롬프트 처리 파이프라인"""
    
    def __init__(self):
        self.current_date = datetime.now().strftime("%Y-%m-%d")
    
    def process_request(self, user_request: str) -> Dict[str, Any]:
        """단계별 프롬프트 처리"""
        # 1단계: 의도 분류
        intent_prompt = PromptManager.get_intent_classification_prompt(
            user_request, self.current_date
        )
        
        # 2단계: 정보 추출 (필요한 경우)
        extraction_prompt = None
        if self._requires_extraction(user_request):
            extraction_prompt = PromptManager.get_schedule_extraction_prompt(
                user_request, self.current_date
            )
        
        # 3단계: 응답 생성
        response_prompt = PromptManager.get_response_generation_prompt(
            user_request, "intent", {}, "processing_result"
        )
        
        return {
            "intent_prompt": intent_prompt,
            "extraction_prompt": extraction_prompt,
            "response_prompt": response_prompt,
            "current_date": self.current_date
        }
    
    def _requires_extraction(self, user_request: str) -> bool:
        """정보 추출이 필요한지 판단"""
        schedule_keywords = ['일정', '약속', '회의', '병원', '약', '추가', '삭제', '확인']
        return any(keyword in user_request for keyword in schedule_keywords)