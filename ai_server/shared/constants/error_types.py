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
    
    # 4. 일정 조회/삭제 에러
    SCHEDULE_NOT_FOUND = "schedule_not_found"
    SCHEDULE_DELETE_ERROR = "schedule_delete_error"
    
    # 5. LLM/AI 처리 에러
    AI_PROCESSING_ERROR = "ai_processing_error"
    LLM_ERROR = "llm_error"
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
    

