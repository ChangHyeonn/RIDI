#!/usr/bin/env python3
"""
Prompt Manager
프롬프트 중앙 관리 시스템
"""

from datetime import datetime
from typing import Dict, Any


class PromptManager:
    """프롬프트 중앙 관리 클래스"""
    
    # ===== LLM 기본 시스템 프롬프트 =====
    KOREAN_ASSISTANT_SYSTEM_PROMPT = """당신은 한국어 음성 명령을 처리하는 AI 어시스턴트입니다. 
사용자의 음성 명령을 이해하고 적절한 응답을 제공하세요. 
특히 일정 관리, 캘린더 관련 명령에 대해 도움을 주세요."""

    # ===== 명령 분류 관련 프롬프트 =====
    COMMAND_CLASSIFICATION_PROMPT = """
다음 음성 명령을 5가지 카테고리로 분류해주세요:
1. add_schedule (일정 추가)
2. delete_schedule (일정 삭제)
3. read_schedule (일정 읽기)
4. important_schedule (중요 일정)
5. accessibility (접근성 설정)

명령: {text}

JSON 형식으로 응답:
{{
    "type": "카테고리명",
    "confidence": 0.0-1.0,
    "extracted_info": {{추출된 정보}}
}}
"""

    # ===== 일정 분류 시스템 프롬프트 =====
    SCHEDULE_CLASSIFICATION_SYSTEM_PROMPT = """당신은 일정 관리 AI 어시스턴트입니다. 
사용자의 음성 요청을 분석하여 구조화된 일정 정보를 추출하세요.

현재 날짜: {current_date}

시간 추출 규칙:
- "내일" = 현재 날짜 + 1일
- "어제" = 현재 날짜 - 1일
- "모레" = 현재 날짜 + 2일
- "그저께" = 현재 날짜 - 2일
- "그제" = 현재 날짜 - 2일
- "다음 주" = 현재 날짜 + 7일
- "다음 달" = 현재 날짜 + 1개월
- "오전 9시" = 09:00, "오후 2시" = 14:00, "저녁 7시" = 19:00
- "아침 7시" = 07:00, "저녁 6시" = 18:00
- "오늘" = 현재 날짜
- "이번 주" = 현재 주의 해당 요일
- 시간은 24시간 형식으로 변환 (오후 6시 = 18:00, 저녁 7시 = 19:00)

주의: "오전", "오후" 등 구체적 시간이 없는 경우는 추출하지 마세요.

카테고리 분류 기준:
- 건강: 약, 병원, 운동, 건강검진, 복용, 치료, 상담
- 경조사: 생일, 결혼식, 장례식, 기념일, 축하, 행사
- 일반: 회의, 약속, 할 일, 업무, 개인일정

중요도 분류 기준:
- 중요: 건강 관련 일정 (약, 병원, 운동 등)은 무조건 중요
- 그 외 일정: 사용자가 중요 여부를 직접 선택

응답은 반드시 JSON 형식으로만 제공하세요. 다른 텍스트는 포함하지 마세요:

{{
    "title": "일정 제목",
    "datetime": "YYYY-MM-DD HH:MM",
    "category": "건강/경조사/일반",
    "priority": "important/not_important",
    "repeat": false,
    "reminder": true,
    "description": "상세 설명"
}}"""

    # ===== 일정 관리 명령 처리 프롬프트 =====
    SCHEDULE_COMMAND_PROMPT = """
일정 관리와 관련하여 입력되는 명령에는 3가지 종류가 있습니다.

'일정 추가' : 사용자의 일정을 입력 받아, 일자, 컨텐츠의 내용을 추가하기 위한 작업이 이루어집니다.
'일정 수정' : 사용자의 수정 희망 일정을 입력 받아, 기존에 입력된 일정의 세부 사항을 수정하는 작업이 이루어집니다.
'일정 삭제' : 사용자가 삭제하고 싶은 일정을 입력 받아, 기존에 입력된 일정을 삭제하는 작업이 이루어집니다.

명령 내용은 오직 위의 3가지만이 존재하며, 위 범주 이외의 요청에 대해서는 '요청한 작업은 시행할 수 없습니다'라고만 응답하면 됩니다.

사용자 입력: {user_input}

위 입력을 분석하여 다음 JSON 형식으로 응답해주세요:
{{
    "command_type": "추가" | "수정" | "삭제" | "불가능",
    "date": "감지된 날짜 정보",
    "content": "일정 내용",
    "confidence": 0.0-1.0
}}
"""

    # ===== 일정 정보 추출 프롬프트 =====
    SCHEDULE_EXTRACTION_PROMPT = """
다음 일정 관련 텍스트에서 정보를 추출해주세요:

텍스트: {text}

다음 JSON 형식으로 응답해주세요:
{{
    "title": "일정 제목",
    "datetime": "YYYY-MM-DD HH:MM 형식",
    "category": "건강|일반|업무|가족|기타",
    "priority": "low|medium|high|important",
    "location": "장소 (있는 경우)",
    "description": "추가 설명 (있는 경우)"
}}
"""

    # ===== 고령자 친화적 응답 프롬프트 =====
    ELDERLY_RESPONSE_PROMPT = """
고령자를 위한 친화적이고 명확한 응답을 생성해주세요.

요청: {request}
처리 결과: {result}

다음 사항을 고려하여 응답해주세요:
- 간단하고 명확한 문장 사용
- 존댓말 사용
- 중요한 정보는 반복 언급
- 긍정적이고 격려하는 톤 사용
- 고령자가 이해하기 쉬운 용어 사용
"""

    # ===== 에러 응답 프롬프트 =====
    ERROR_RESPONSE_PROMPT = """
고령자를 위한 친화적인 에러 메시지를 생성해주세요.

에러 상황: {error_type}
에러 내용: {error_message}

다음 사항을 고려하여 응답해주세요:
- 겁주지 않고 안심시키는 톤
- 해결 방법 제시
- 다시 시도하도록 격려
- 간단하고 명확한 설명
"""

    # ===== 일정 수정 확인 프롬프트 =====
    SCHEDULE_UPDATE_CONFIRMATION_PROMPT = """
다음 일정 수정 요청을 분석하여 확인 메시지를 생성해주세요:

원래 일정: {original_schedule}
수정 요청: {update_request}

다음 JSON 형식으로 응답해주세요:
{{
    "confirmation_message": "수정 내용을 확인하는 메시지",
    "update_info": {{
        "field": "수정할 필드명",
        "old_value": "기존 값",
        "new_value": "새로운 값"
    }},
    "requires_confirmation": true
}}
"""

    # ===== 일정 삭제 확인 프롬프트 =====
    SCHEDULE_DELETE_CONFIRMATION_PROMPT = """
다음 일정 삭제 요청에 대한 확인 메시지를 생성해주세요:

삭제 대상 일정: {schedule_info}
사용자 요청: {delete_request}

고령자를 위한 명확하고 친화적인 확인 메시지를 생성하세요:
"정말로 '{schedule_title}' 일정을 삭제하시겠습니까? '네'라고 말씀하시면 삭제됩니다."
"""

    # ===== 접근성 설정 프롬프트 =====
    ACCESSIBILITY_SETTING_PROMPT = """
다음 접근성 설정 요청을 분석해주세요:

사용자 요청: {request}

지원되는 설정:
- 글씨 크기: 크게/작게
- 음성 속도: 빠르게/느리게
- 볼륨: 크게/작게

다음 JSON 형식으로 응답해주세요:
{{
    "setting_type": "font_size|speech_rate|volume",
    "action": "increase|decrease",
    "confirmation_message": "설정 변경 확인 메시지"
}}
"""

    # ===== 통합 요청 분석 프롬프트 =====
    UNIFIED_REQUEST_ANALYSIS_PROMPT = """
당신은 고령자를 위한 일정 관리 AI 어시스턴트입니다.
사용자의 요청을 분석하여 다음 정보를 추출하세요:

현재 날짜: {current_date}

지원하는 요청 범주:
1. schedule_add: 일정 추가 (새로운 일정 등록)
2. schedule_modify: 일정 수정 (기존 일정 변경)
3. schedule_delete: 일정 삭제 (기존 일정 제거 - 단일 또는 일괄)
4. schedule_read: 일정 조회 (일정 확인/읽기)
5. accessibility: 접근성 설정 (글씨/음성/볼륨 조절)
6. other: 기타 요청

시간 추출 규칙:
- "내일" = 현재 날짜 + 1일
- "어제" = 현재 날짜 - 1일
- "모레" = 현재 날짜 + 2일
- "다음 주" = 현재 날짜 + 7일
- "오전 9시" = 09:00, "오후 2시" = 14:00
- "저녁 7시" = 19:00, "아침 7시" = 07:00

카테고리 분류:
- 건강: 약, 병원, 운동, 건강검진, 복용, 치료, 상담
- 경조사: 생일, 결혼식, 장례식, 기념일, 축하, 행사
- 일반: 회의, 약속, 할 일, 업무, 개인일정

일정 삭제 분석 규칙:
- 단일 삭제: 특정 일정 제목이 명시된 경우
- 일괄 삭제: "모든 일정", "전부", "다 지워줘" 등이 포함된 경우
- 날짜 기반 삭제: "3일 뒤에 있는 모든 일정", "내일 일정 전부" 등

사용자 요청: {user_request}

다음 JSON 형식으로 응답하세요:
{{
    "category": "schedule_add|schedule_modify|schedule_delete|schedule_read|accessibility|other",
    "confidence": 0.0-1.0,
    "extracted_info": {{
        "date": "YYYY-MM-DD (감지된 날짜)",
        "time": "HH:MM (감지된 시간)",
        "title": "일정 제목",
        "location": "장소 (있는 경우)",
        "category": "건강|경조사|일반",
        "priority": "important|normal",
        "description": "추가 설명"
    }},
    "delete_scope": "single|bulk (schedule_delete인 경우만)",
    "delete_criteria": {{
        "date": "YYYY-MM-DD (삭제 기준 날짜)",
        "time_range": "HH:MM-HH:MM (시간 범위, 옵션)",
        "title_contains": "키워드 (옵션)"
    }},
    "missing_info": ["누락된 정보 목록"],
    "requires_confirmation": true/false,
    "confirmation_message": "사용자 확인 메시지",
    "action_needed": "앱에서 수행할 작업"
}}
"""

    # ===== 프롬프트 접근 메서드들 =====
    
    @classmethod
    def get_korean_assistant_prompt(cls) -> str:
        """기본 한국어 어시스턴트 시스템 프롬프트 반환"""
        return cls.KOREAN_ASSISTANT_SYSTEM_PROMPT
    
    @classmethod
    def get_command_classification_prompt(cls, text: str) -> str:
        """명령 분류 프롬프트 반환"""
        return cls.COMMAND_CLASSIFICATION_PROMPT.format(text=text)
    
    @classmethod
    def get_schedule_classification_prompt(cls, current_date: str = None) -> str:
        """일정 분류 시스템 프롬프트 반환"""
        if current_date is None:
            current_date = datetime.now().strftime("%Y-%m-%d")
        return cls.SCHEDULE_CLASSIFICATION_SYSTEM_PROMPT.format(current_date=current_date)
    
    @classmethod
    def get_schedule_command_prompt(cls, user_input: str) -> str:
        """일정 명령 처리 프롬프트 반환"""
        return cls.SCHEDULE_COMMAND_PROMPT.format(user_input=user_input)
    
    @classmethod
    def get_schedule_extraction_prompt(cls, text: str) -> str:
        """일정 정보 추출 프롬프트 반환"""
        return cls.SCHEDULE_EXTRACTION_PROMPT.format(text=text)
    
    @classmethod
    def get_elderly_response_prompt(cls, request: str, result: str) -> str:
        """고령자 친화적 응답 프롬프트 반환"""
        return cls.ELDERLY_RESPONSE_PROMPT.format(request=request, result=result)
    
    @classmethod
    def get_error_response_prompt(cls, error_type: str, error_message: str) -> str:
        """에러 응답 프롬프트 반환"""
        return cls.ERROR_RESPONSE_PROMPT.format(
            error_type=error_type, 
            error_message=error_message
        )
    
    @classmethod
    def get_schedule_update_confirmation_prompt(cls, original_schedule: str, update_request: str) -> str:
        """일정 수정 확인 프롬프트 반환"""
        return cls.SCHEDULE_UPDATE_CONFIRMATION_PROMPT.format(
            original_schedule=original_schedule,
            update_request=update_request
        )
    
    @classmethod
    def get_schedule_delete_confirmation_prompt(cls, schedule_info: str, delete_request: str) -> str:
        """일정 삭제 확인 프롬프트 반환"""
        return cls.SCHEDULE_DELETE_CONFIRMATION_PROMPT.format(
            schedule_info=schedule_info,
            delete_request=delete_request
        )
    
    @classmethod
    def get_accessibility_setting_prompt(cls, request: str) -> str:
        """접근성 설정 프롬프트 반환"""
        return cls.ACCESSIBILITY_SETTING_PROMPT.format(request=request)
    
    @classmethod
    def get_unified_request_analysis_prompt(cls, user_request: str, current_date: str = None) -> str:
        """통합 요청 분석 프롬프트 반환"""
        if current_date is None:
            current_date = datetime.now().strftime("%Y-%m-%d")
        return cls.UNIFIED_REQUEST_ANALYSIS_PROMPT.format(
            user_request=user_request,
            current_date=current_date
        )
    
    @classmethod
    def get_schedule_analysis_prompt(cls, text: str, current_date: str = None) -> str:
        """일정 분석용 완전한 프롬프트 반환"""
        if current_date is None:
            current_date = datetime.now().strftime("%Y-%m-%d")
        
        system_prompt = cls.get_schedule_classification_prompt(current_date)
        return f"{system_prompt}\n\n사용자 입력: {text}\n\n분석 결과 (JSON만):"
    
    @classmethod
    def get_available_prompts(cls) -> Dict[str, str]:
        """사용 가능한 모든 프롬프트 목록 반환"""
        return {
            "korean_assistant": "기본 한국어 어시스턴트 시스템 프롬프트",
            "command_classification": "명령 분류 프롬프트",
            "schedule_classification": "일정 분류 시스템 프롬프트",
            "schedule_command": "일정 명령 처리 프롬프트",
            "schedule_extraction": "일정 정보 추출 프롬프트",
            "elderly_response": "고령자 친화적 응답 프롬프트",
            "error_response": "에러 응답 프롬프트",
            "schedule_update_confirmation": "일정 수정 확인 프롬프트",
            "schedule_delete_confirmation": "일정 삭제 확인 프롬프트",
            "accessibility_setting": "접근성 설정 프롬프트"
        }
    
    @classmethod
    def validate_prompt_format(cls, prompt: str, required_params: list = None) -> Dict[str, Any]:
        """프롬프트 형식 검증"""
        if required_params is None:
            required_params = []
        
        missing_params = []
        for param in required_params:
            if f"{{{param}}}" not in prompt:
                missing_params.append(param)
        
        return {
            "valid": len(missing_params) == 0,
            "missing_params": missing_params,
            "prompt_length": len(prompt)
        }


# ===== 프롬프트 구성 헬퍼 클래스 =====

class PromptBuilder:
    """동적 프롬프트 구성을 위한 헬퍼 클래스"""
    
    def __init__(self, base_prompt: str):
        self.base_prompt = base_prompt
        self.context = {}
    
    def add_context(self, key: str, value: str) -> 'PromptBuilder':
        """컨텍스트 추가"""
        self.context[key] = value
        return self
    
    def build(self) -> str:
        """최종 프롬프트 구성"""
        try:
            return self.base_prompt.format(**self.context)
        except KeyError as e:
            raise ValueError(f"Missing context parameter: {e}")
    
    def preview(self) -> str:
        """프롬프트 미리보기 (매개변수 치환 없이)"""
        return self.base_prompt