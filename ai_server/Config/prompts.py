#!/usr/bin/env python3
"""
Prompt Manager - 목적별 분리된 프롬프트 관리 시스템
"""

from datetime import datetime
from typing import Dict, Any


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
- schedule_read: 일정 조회 요청 (키워드 검색, 날짜별 조회, 전체 조회 포함)
- schedule_delete: 일정 삭제 요청
- schedule_update: 일정 수정 요청
- general_conversation: 일반 대화
- error_handling: 오류 상황

**일정 추가 요청 감지 규칙 (중요):**
- "~일정 추가해 줘", "~일정 넣어줘", "~일정 등록해 줘" → schedule_add
- "~약속 있어", "~해야 해", "~있어" (시간/날짜와 함께) → schedule_add
- "~일정 만들어 줘", "~일정 잡아줘" → schedule_add
- "다음 주에 ~", "내일 ~", "~일에 ~" (구체적인 활동과 함께) → schedule_add
- "친구랑 ~", "~랑 ~" (시간/날짜와 함께) → schedule_add

**일정 추가 예시:**
- "어 다음 주 토요일 오후 3시에 친구랑 점심 식사 약속 있어" → schedule_add
- "내일 오후 2시에 병원 진료 있어" → schedule_add
- "다음 주 월요일에 회의 있어" → schedule_add
- "친구랑 영화 보기 약속 있어" → schedule_add
- "치과 예약해야 해" → schedule_add
- "약 복용해야 해" → schedule_add

**일정 조회 요청 감지 규칙:**
- "~일정 보여줘", "~일정 알려줘", "~일정 언제" → schedule_read (키워드 검색)
- "~관련 일정", "~일정이 언제" → schedule_read (키워드 검색)
- "내일 일정", "다음주 일정", "특정 날짜 일정" → schedule_read (날짜별 조회)
- "일정 목록", "모든 일정", "일정 보여줘" → schedule_read (전체 조회)
- "중요한 일정", "중요 일정" → schedule_read (중요 일정 조회)
- "~일정이 언제 있어?" (존재 여부만 묻는 경우) → schedule_read

**일정 조회 예시:**
- "다음 주에 뭐 있어?" → schedule_read
- "내일 일정 뭐야?" → schedule_read
- "이번 주 일정 알려줘" → schedule_read
- "병원 일정 언제 있어?" → schedule_read

**구분 기준:**
1. **일정 추가**: 구체적인 활동 + 시간/날짜 → schedule_add
2. **일정 조회**: "뭐 있어?", "언제 있어?", "보여줘" → schedule_read

JSON 형식으로만 응답:
{{
    "intent": "카테고리명",
    "confidence": 0.0-1.0,
    "requires_extraction": true/false
}}
"""

    # ===== 2단계: 일정 정보 추출 프롬프트 (반복 일정 지원) =====
    SCHEDULE_EXTRACTION_PROMPT = """
일정 관련 정보를 추출해주세요.

현재 날짜: {current_date}
사용자 요청: {user_request}

중요: 
1. 일정 제목은 구체적인 내용만 추출하세요.
2. **날짜 정보가 있으면 반드시 날짜 기반 조회로 분류하세요!**
3. 날짜 정보가 없는 경우에만 키워드 검색으로 분류하세요.
4. "이번 주", "다음 주", "내일", "모레" 등의 날짜 표현을 우선적으로 인식하세요.

추가 요청 예시:
- "내일 오후 3시에 병원 진료 일정을 추가해 줘" → title: "병원 진료"
- "다음주 월요일 오전 9시에 회사 회의 일정을 넣어줘" → title: "회사 회의"
- "매일 아침 7시에 약 복용 일정을 등록해 줘" → title: "약 복용"

조회 요청 예시:
**키워드 검색:**
- "병원 관련 일정이 언제 있는지 알려줘" → type: "keyword", keyword: "병원"
- "치과 일정 언제 있어?" → type: "keyword", keyword: "치과"
- "회의 일정 보여줘" → type: "keyword", keyword: "회의"
- "운동 관련 일정 알려줘" → type: "keyword", keyword: "운동"
- "건강 관련 일정 보여줘" → type: "keyword", keyword: "건강"
- "치과 진료 일정 언제" → type: "keyword", keyword: "치과"
- "병원 진료 일정 보여줘" → type: "keyword", keyword: "병원"
- "정기 검진 일정 알려줘" → type: "keyword", keyword: "정기 검진"

**날짜별 조회:**
- "내일 일정 보여줘" → type: "date", date: "내일 날짜"
- "다음주 월요일 일정" → type: "date", date: "다음주 월요일 날짜"
- "이번 주 토요일 일정" → type: "date", date: "이번 주 토요일 날짜"
- "이번 주 토요일에 어떤 일정 있는지" → type: "date", date: "이번 주 토요일 날짜"
- "8월 25일 일정" → type: "date", date: "2025-08-25"
- "토요일 일정" → type: "date", date: "토요일 날짜"
- "금요일 일정" → type: "date", date: "금요일 날짜"

**기타 조회:**
- "중요한 일정만 보여줘" → type: "important"
- "일정 목록 보여줘" → type: "all"
- "모든 일정 보여줘" → type: "all"

조회 요청 우선순위 규칙:
1. **날짜 기반 조회** (최우선):
   - "이번 주 토요일 일정" → type: "date", date: "이번 주 토요일 날짜"
   - "내일 일정" → type: "date", date: "내일 날짜"
   - "다음주 월요일 일정" → type: "date", date: "다음주 월요일 날짜"
   - "8월 25일 일정" → type: "date", date: "2025-08-25"

2. **키워드 검색** (날짜 정보가 없는 경우):
   - "~관련 일정" → type: "keyword", keyword: "~"
   - "~일정이 언제" → type: "keyword", keyword: "~"
   - "~일정 언제" → type: "keyword", keyword: "~"
   - "~일정 보여줘" → type: "keyword", keyword: "~"
   - "~일정 알려줘" → type: "keyword", keyword: "~"
   - "~일정" (단독으로 사용) → type: "keyword", keyword: "~"

3. **기타 조회**:
   - "중요한 일정" → type: "important"
   - "모든 일정" → type: "all"

중요: 날짜 정보가 있으면 반드시 날짜 기반 조회로 분류하세요!

삭제 요청 예시:
- "병원 진료 일정 삭제해 줘" → title: "병원 진료"
- "친구 만남 일정 삭제해 줘" → title: "친구 만남"
- "내일 친구 만남 일정 삭제해 줘" → title: "친구 만남", date: "내일 날짜"
- "회의 일정 삭제해 줘" → title: "회의"
- "약 복용 일정 삭제해 줘" → title: "약 복용"
- "병원 일정 삭제해 줘" → title: "병원"
- "치과 일정 삭제해 줘" → title: "치과"

삭제 요청 처리 규칙:
- "~일정 삭제해 줘" → title: "~" (일정 앞의 구체적인 내용만 추출)
- "~일정 지워줘" → title: "~"
- "~일정 취소해 줘" → title: "~"
- "일정", "예약", "할 일" 등의 일반적 단어는 제목에 포함하지 마세요.
- 단일 단어도 유효한 제목입니다 (예: "병원", "치과", "회의" 등)

시간 변환 규칙:
- "내일" = 현재 날짜 + 1일
- "모레" = 현재 날짜 + 2일  
- "다음 주 [요일]" = 현재 주의 다음 주 [요일] (예: 다음 주 수요일 = 이번 주 수요일 + 7일)
- "이번 주 [요일]" = 이번 주의 [요일] (오늘이 지난 경우 다음 주 [요일])
- "오전/오후" = 24시간 형식으로 변환

중요도 설정 규칙:
- 건강 관련 일정(병원, 치과, 검진, 약 복용, 운동, 다이어트, 건강관리, 예방접종, 물리치료, 심리상담, 건강검진 등): is_important = true
- 그 외 모든 일정: is_important = false

반복 일정 감지 규칙:
1. 반복 키워드:
   - "매일", "매일마다", "매일 ~마다", "매일 ~에" → daily (최우선)
   - "평일", "평일마다", "월요일부터 금요일" → weekdays  
   - "주말", "주말마다", "토요일 일요일" → weekends
   - "월, 수, 금", "화목토", 특정 요일들 → custom_days

2. 자동 감지 규칙:
   - "~마다" 표현이 있으면 반복 일정으로 인식 (예: "7시마다", "아침마다")
   - "정기", "반복", "계속", "늘", "항상" 등의 표현도 반복 일정 지표
   - 특별한 요일 명시가 없으면 "매일"로 처리

중요: "매일" 표현은 반드시 daily 타입으로 분류하세요!

2. 요일 매핑 (custom_days용):
   - 월요일=0, 화요일=1, 수요일=2, 목요일=3, 금요일=4, 토요일=5, 일요일=6

3. 다중 시간 감지:
   - "아침 7시, 저녁 6시"
   - "오전 8시, 오후 1시, 저녁 8시"
   - "하루 2번", "하루 3번"

4. 종료 조건:
   - "~까지", "~년 ~월까지", "다음주 ~요일까지", "다다음주 ~요일까지", "이번주 ~요일까지" → 특정 날짜
   - 상대적 기간 표현:
     * "~일 뒤까지", "~일 후까지" → 현재 날짜 + N일
     * "~주 뒤까지", "~주 후까지" → 현재 날짜 + N주
     * "~달 뒤까지", "~개월 뒤까지" → 현재 날짜 + N개월
     * "~년 뒤까지", "~년 후까지" → 현재 날짜 + N년
   - 자연어 날짜 파싱: 
     * "다음주 금요일까지" → 해당 날짜의 YYYY-MM-DD 형식
     * "다다음주 금요일까지" → 2주 후 해당 요일의 YYYY-MM-DD 형식
   - 날짜 계산 시 정확한 요일 확인 필수 (예: 2025년 8월 29일은 월요일, 9월 5일이 금요일, 9월 12일이 금요일)
   - 명시 없음 → 무기한 (end_date: null)

중요: JSON 형식으로만 응답하세요. 마크다운 코드 블록(```json)을 사용하지 마세요.

**일정 추가/삭제용:**
{{
    "title": "일정 제목 (구체적인 내용만, '일정', '예약' 등의 일반적 단어 제외)",
    "date": "YYYY-MM-DD",
    "time": "HH:MM",
    "category": "경조사/일반/건강",
    "is_important": "건강 카테고리인 경우에만 true, 나머지는 false",
    "location": "장소 (있는 경우)",
    "description": "추가 설명 (있는 경우)",
    "is_recurring": "반복 일정 여부 (true/false)",
    "recurrence": {{
        "type": "daily/weekdays/weekends/custom_days (is_recurring이 true인 경우만)",
        "times": [
            {{"time": "07:00", "label": "아침"}},
            {{"time": "18:00", "label": "저녁"}}
        ],
        "end_date": "YYYY-MM-DD 또는 null (무기한, 자연어 날짜는 파싱하여 YYYY-MM-DD로 변환)",
        "days_of_week": "[0,2,4] (custom_days인 경우만, 월=0, 화=1, ...)"
    }}
}}

**일정 조회용 (키워드 검색 우선):**
{{
    "type": "keyword/date/important/all",
    "keyword": "검색 키워드 (type이 keyword인 경우만, 구체적인 키워드만 추출)",
    "date": "YYYY-MM-DD (type이 date인 경우만)"
}}

**키워드 추출 규칙:**
- "병원 관련 일정" → keyword: "병원"
- "치과 진료 일정" → keyword: "치과"
- "정기 검진 일정" → keyword: "정기 검진"
- "회의 일정" → keyword: "회의"
- "운동 일정" → keyword: "운동"

예시:
**일정 추가:**
- "내일 오후 3시에 병원 진료" → title: "병원 진료", date: "2025-08-22", time: "15:00", is_recurring: false
- "다음 주 수요일 오전 9시에 친구랑 아침 식사" → title: "아침 식사", date: "2025-08-27", time: "09:00", is_recurring: false
- "매일 아침 7시, 저녁 6시에 약 복용" → title: "약 복용", date: "2025-08-22", time: "07:00", is_recurring: true, type: "daily"
- "매일 아침 7시마다 약 복용" → title: "약 복용", date: "2025-08-22", time: "07:00", is_recurring: true, type: "daily"
- "매일 아침 7시에 약을 먹어야 돼" → title: "약 복용", date: "2025-08-22", time: "07:00", is_recurring: true, type: "daily"
- "아침 7시마다 약 복용" → title: "약 복용", date: "2025-08-22", time: "07:00", is_recurring: true, type: "daily"
- "7시마다 약 복용" → title: "약 복용", date: "2025-08-22", time: "07:00", is_recurring: true, type: "daily"
- "매일 아침 7시에 약 복용, 다음주 금요일까지" → title: "약 복용", date: "2025-08-22", time: "07:00", is_recurring: true, type: "daily", end_date: "2025-09-05"
- "평일마다 오후 6시에 축구, 다다음주 금요일까지" → title: "축구", date: "2025-08-22", time: "18:00", is_recurring: true, type: "weekdays", end_date: "2025-09-12"
- "매일 아침 7시에 약 복용, 30일 뒤까지" → title: "약 복용", date: "2025-08-22", time: "07:00", is_recurring: true, type: "daily", end_date: "2025-09-21"
- "평일마다 오후 6시에 운동, 3개월 뒤까지" → title: "운동", date: "2025-08-22", time: "18:00", is_recurring: true, type: "weekdays", end_date: "2025-11-22"

**일정 조회 (키워드 검색):**
- "치과 일정 언제 있어?" → type: "keyword", keyword: "치과"
- "병원 관련 일정이 언제 있는지 알려줘" → type: "keyword", keyword: "병원"
- "정기 검진 일정 보여줘" → type: "keyword", keyword: "정기 검진"
- "회의 일정 알려줘" → type: "keyword", keyword: "회의"

**일정 조회 (날짜별):**
- "내일 일정 보여줘" → type: "date", date: "2025-08-22"
- "다음주 월요일 일정" → type: "date", date: "2025-08-25"
- "다음 주 수요일 일정" → type: "date", date: "2025-08-27"
- "이번 주 토요일 일정" → type: "date", date: "2025-08-23"

**일정 조회 (기타):**
- "중요한 일정만 보여줘" → type: "important"
- "모든 일정 보여줘" → type: "all"

**일정 삭제:**
- "병원 일정 삭제해 줘" → title: "병원"
- "병원 진료 일정 삭제해 줘" → title: "병원 진료"
- "내일 병원 진료 일정 삭제해 줘" → title: "병원 진료", date: "2025-08-22"
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

    # ===== 일정 선택 프롬프트 =====
    SCHEDULE_SELECTION_PROMPT = """
사용자가 삭제하고 싶은 일정을 선택하도록 안내해주세요.

검색된 일정 목록:
{schedule_list}

사용자 요청: {user_request}

응답 스타일:
- 친화적이고 명확한 안내
- 번호로 선택할 수 있도록 안내
- 다중 선택 가능함을 안내
- "모두" 또는 "전부"로 전체 삭제 가능함을 안내

JSON 형식으로만 응답:
{{
    "response_text": "사용자에게 보여줄 선택 안내 메시지",
    "action_type": "schedule_selection",
    "requires_user_selection": true,
    "selection_options": ["번호 선택", "모두 삭제", "취소"]
}}
"""

    # ===== 일정 선택 응답 처리 프롬프트 =====
    SCHEDULE_SELECTION_RESPONSE_PROMPT = """
사용자의 일정 선택 응답을 처리해주세요.

사용자 응답: {user_response}
선택 가능한 일정 목록:
{schedule_list}

응답 형식 분석:
- 단일 선택: "1번", "병원 진료" → 해당 일정만 선택
- 다중 선택: "1번, 3번", "병원 진료, 치과 진료" → 여러 일정 선택
- 모두 삭제: "모두", "전부", "다" → 모든 일정 선택
- 취소: "취소", "안할래요", "그만" → 선택 취소

JSON 형식으로만 응답:
{{
    "selected_indices": [0, 2],  // 선택된 일정의 인덱스 (0부터 시작)
    "selected_schedule_ids": ["id1", "id2"],  // 선택된 일정의 ID 목록
    "action": "delete_multiple/delete_all/cancel",
    "is_valid_selection": true/false,
    "error_message": "잘못된 선택인 경우 오류 메시지"
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
    def get_schedule_selection_prompt(cls, schedule_list: str, user_request: str) -> str:
        """일정 선택 프롬프트 반환"""
        return cls.SCHEDULE_SELECTION_PROMPT.format(
            schedule_list=schedule_list,
            user_request=user_request
        )
    
    @classmethod
    def get_schedule_selection_response_prompt(cls, user_response: str, schedule_list: str) -> str:
        """일정 선택 응답 처리 프롬프트 반환"""
        return cls.SCHEDULE_SELECTION_RESPONSE_PROMPT.format(
            user_response=user_response,
            schedule_list=schedule_list
        )


