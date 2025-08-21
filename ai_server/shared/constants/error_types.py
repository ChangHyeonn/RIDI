#!/usr/bin/env python3
"""
Error Type Constants
에러 타입 상수 정의
"""

class ErrorTypes:
    """에러 타입 상수"""
    
    # 1. 입력 검증 에러
    VALIDATION_ERROR = "validation_error"
    INVALID_REQUEST = "invalid_request"
    MISSING_CONTENT_TYPE = "missing_content_type"
    MISSING_REQUIRED_DATA = "missing_required_data"
    
    # 2. 일정 정보 검증 에러
    SCHEDULE_VALIDATION_ERROR = "schedule_validation_error"
    MISSING_SCHEDULE_TITLE = "missing_schedule_title"
    GENERIC_SCHEDULE_TITLE = "generic_schedule_title"
    SHORT_SCHEDULE_TITLE = "short_schedule_title"
    MISSING_SCHEDULE_DATE = "missing_schedule_date"
    MISSING_SCHEDULE_TIME = "missing_schedule_time"
    INVALID_DATE_FORMAT = "invalid_date_format"
    INVALID_TIME_FORMAT = "invalid_time_format"
    
    # 3. 데이터베이스/저장 에러
    DATABASE_ERROR = "database_error"
    SCHEDULE_SAVE_ERROR = "schedule_save_error"
    DATA_PARSING_ERROR = "data_parsing_error"
    
    # 4. 일정 조회/삭제 에러
    SCHEDULE_NOT_FOUND = "schedule_not_found"
    SCHEDULE_DELETE_ERROR = "schedule_delete_error"
    INSUFFICIENT_DELETE_INFO = "insufficient_delete_info"
    
    # 5. LLM/AI 처리 에러
    AI_PROCESSING_ERROR = "ai_processing_error"
    LLM_ERROR = "llm_error"
    INTENT_ANALYSIS_ERROR = "intent_analysis_error"
    RESPONSE_GENERATION_ERROR = "response_generation_error"
    
    # 6. 서버 상태 에러
    HEALTH_CHECK_ERROR = "health_check"
    SERVER_ERROR = "server_error"
    
    # 7. HTTP 에러
    BAD_REQUEST = "bad_request"
    NOT_FOUND = "not_found"
    INTERNAL_ERROR = "internal_error"
    
    # 8. 시스템 예외
    SYSTEM_ERROR = "system_error"
    UNEXPECTED_ERROR = "unexpected_error"
    
    @classmethod
    def get_user_friendly_message(cls, error_type: str) -> str:
        """에러 타입별 사용자 친화적 메시지 반환"""
        messages = {
            cls.VALIDATION_ERROR: "입력 정보를 확인해주세요.",
            cls.INVALID_REQUEST: "잘못된 요청입니다.",
            cls.MISSING_CONTENT_TYPE: "요청 형식이 올바르지 않습니다.",
            cls.MISSING_REQUIRED_DATA: "필수 정보가 누락되었습니다.",
            
            cls.SCHEDULE_VALIDATION_ERROR: "일정 정보를 확인해주세요.",
            cls.MISSING_SCHEDULE_TITLE: "일정 제목을 입력해주세요.",
            cls.GENERIC_SCHEDULE_TITLE: "구체적인 일정 내용을 입력해주세요.",
            cls.SHORT_SCHEDULE_TITLE: "일정 제목이 너무 짧습니다.",
            cls.MISSING_SCHEDULE_DATE: "일정 날짜를 입력해주세요.",
            cls.MISSING_SCHEDULE_TIME: "일정 시간을 입력해주세요.",
            cls.INVALID_DATE_FORMAT: "날짜 형식이 올바르지 않습니다.",
            cls.INVALID_TIME_FORMAT: "시간 형식이 올바르지 않습니다.",
            
            cls.DATABASE_ERROR: "데이터 저장 중 오류가 발생했습니다.",
            cls.SCHEDULE_SAVE_ERROR: "일정 저장에 실패했습니다.",
            cls.DATA_PARSING_ERROR: "데이터 처리 중 오류가 발생했습니다.",
            
            cls.SCHEDULE_NOT_FOUND: "일정을 찾을 수 없습니다.",
            cls.SCHEDULE_DELETE_ERROR: "일정 삭제에 실패했습니다.",
            cls.INSUFFICIENT_DELETE_INFO: "삭제할 일정 정보가 부족합니다.",
            
            cls.AI_PROCESSING_ERROR: "AI 처리 중 오류가 발생했습니다.",
            cls.LLM_ERROR: "언어모델 처리 중 오류가 발생했습니다.",
            cls.INTENT_ANALYSIS_ERROR: "요청 분석 중 오류가 발생했습니다.",
            cls.RESPONSE_GENERATION_ERROR: "응답 생성 중 오류가 발생했습니다.",
            
            cls.HEALTH_CHECK_ERROR: "서버 상태 확인 중 오류가 발생했습니다.",
            cls.SERVER_ERROR: "서버 오류가 발생했습니다.",
            
            cls.BAD_REQUEST: "잘못된 요청입니다.",
            cls.NOT_FOUND: "요청한 리소스를 찾을 수 없습니다.",
            cls.INTERNAL_ERROR: "서버 내부 오류가 발생했습니다.",
            
            cls.SYSTEM_ERROR: "시스템 오류가 발생했습니다.",
            cls.UNEXPECTED_ERROR: "예상치 못한 오류가 발생했습니다."
        }
        
        return messages.get(error_type, "오류가 발생했습니다.")
