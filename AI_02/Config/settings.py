#!/usr/bin/env python3
"""
Settings Configuration (Text-based)
설정 파일 (텍스트 기반)
"""

import os
from typing import List

class Settings:
    """설정 클래스"""
    
    # 서버 설정
    HOST = os.getenv('AI_SERVER_HOST', '0.0.0.0')
    PORT = int(os.getenv('AI_SERVER_PORT', 8080))
    DEBUG = os.getenv('AI_SERVER_DEBUG', 'False').lower() == 'true'
    
    # CORS 설정
    ALLOWED_ORIGINS = [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "*"  # 개발 환경용 (프로덕션에서는 제거)
    ]
    
    # AI 모델 설정
    LLM_TYPE = os.getenv('LLM_TYPE', 'gemini')  # gemini, openai, claude
    DEVICE = os.getenv('DEVICE', 'auto')  # auto, cpu, cuda
    
    # API 키 설정
    GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY', '')
    OPENAI_API_KEY = os.getenv('OPENAI_API_KEY', '')
    ANTHROPIC_API_KEY = os.getenv('ANTHROPIC_API_KEY', '')
    
    # 데이터베이스 설정
    DB_ENGINE = os.getenv('DB_ENGINE', 'inmemory')  # inmemory | mongodb
    
    # MongoDB 설정
    MONGO_URI = os.getenv('MONGO_URI', 'mongodb://localhost:27017/')
    MONGO_DB = os.getenv('MONGO_DB', 'ridi_ai')
    
    # 텍스트 처리 설정
    MAX_TEXT_LENGTH = int(os.getenv('MAX_TEXT_LENGTH', 1000))
    MIN_TEXT_LENGTH = int(os.getenv('MIN_TEXT_LENGTH', 1))
    MAX_RESPONSE_LENGTH = int(os.getenv('MAX_RESPONSE_LENGTH', 2000))
    DEFAULT_RESPONSE_TIMEOUT = int(os.getenv('DEFAULT_RESPONSE_TIMEOUT', 30))
    
    # 일정 관리 설정
    MAX_SCHEDULE_TITLE_LENGTH = int(os.getenv('MAX_SCHEDULE_TITLE_LENGTH', 100))
    MAX_SCHEDULE_DESCRIPTION_LENGTH = int(os.getenv('MAX_SCHEDULE_DESCRIPTION_LENGTH', 500))
    
    # 접근성 설정
    DEFAULT_FONT_SIZE = int(os.getenv('DEFAULT_FONT_SIZE', 16))
    DEFAULT_CONTRAST_RATIO = float(os.getenv('DEFAULT_CONTRAST_RATIO', 4.5))
    
    # 로깅 설정
    LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
    LOG_FILE = os.getenv('LOG_FILE', 'logs/ai_server.log')
    
    # 보안 설정
    API_KEY_REQUIRED = os.getenv('API_KEY_REQUIRED', 'False').lower() == 'true'
    MAX_REQUESTS_PER_MINUTE = int(os.getenv('MAX_REQUESTS_PER_MINUTE', 100))
    
    # 메모리 관리 설정
    MAX_MEMORY_ITEMS = int(os.getenv('MAX_MEMORY_ITEMS', 1000))
    MEMORY_CLEANUP_INTERVAL = int(os.getenv('MEMORY_CLEANUP_INTERVAL', 3600))  # 1시간
    
    @classmethod
    def get_device(cls) -> str:
        """디바이스 설정 반환"""
        if cls.DEVICE == "auto":
            try:
                import torch
                if torch.cuda.is_available():
                    return "cuda"
                else:
                    return "cpu"
            except ImportError:
                return "cpu"
        return cls.DEVICE
    
    @classmethod
    def validate_settings(cls) -> List[str]:
        """설정 유효성 검증"""
        errors = []
        
        # 포트 검증
        if not (1024 <= cls.PORT <= 65535):
            errors.append("포트는 1024-65535 사이여야 합니다")
        
        # API 키 검증
        if cls.LLM_TYPE == 'gemini' and not cls.GOOGLE_API_KEY:
            errors.append("Gemini 모델 사용 시 GOOGLE_API_KEY가 필요합니다")
        elif cls.LLM_TYPE == 'openai' and not cls.OPENAI_API_KEY:
            errors.append("OpenAI 모델 사용 시 OPENAI_API_KEY가 필요합니다")
        elif cls.LLM_TYPE == 'claude' and not cls.ANTHROPIC_API_KEY:
            errors.append("Claude 모델 사용 시 ANTHROPIC_API_KEY가 필요합니다")
        
        # MongoDB 설정 검증
        if cls.DB_ENGINE == 'mongodb' and not cls.MONGO_URI:
            errors.append("MongoDB 사용 시 MONGO_URI가 설정되지 않았습니다")
        
        # 텍스트 길이 검증
        if cls.MAX_TEXT_LENGTH < cls.MIN_TEXT_LENGTH:
            errors.append("최대 텍스트 길이는 최소 텍스트 길이보다 커야 합니다")
        
        # 접근성 설정 검증
        if not (8 <= cls.DEFAULT_FONT_SIZE <= 72):
            errors.append("기본 폰트 크기는 8-72 사이여야 합니다")
        
        if not (1.0 <= cls.DEFAULT_CONTRAST_RATIO <= 21.0):
            errors.append("기본 대비 비율은 1.0-21.0 사이여야 합니다")
        
        return errors
    
    @classmethod
    def get_llm_config(cls) -> dict:
        """LLM 설정 반환"""
        config = {
            "type": cls.LLM_TYPE,
            "device": cls.get_device()
        }
        
        if cls.LLM_TYPE == 'gemini':
            config["api_key"] = cls.GOOGLE_API_KEY
        elif cls.LLM_TYPE == 'openai':
            config["api_key"] = cls.OPENAI_API_KEY
        elif cls.LLM_TYPE == 'claude':
            config["api_key"] = cls.ANTHROPIC_API_KEY
        
        return config
    
    @classmethod
    def get_text_processing_config(cls) -> dict:
        """텍스트 처리 설정 반환"""
        return {
            "max_length": cls.MAX_TEXT_LENGTH,
            "min_length": cls.MIN_TEXT_LENGTH,
            "timeout": cls.DEFAULT_RESPONSE_TIMEOUT,
            "max_response_length": cls.MAX_RESPONSE_LENGTH
        }
    
    @classmethod
    def get_database_config(cls) -> dict:
        """데이터베이스 설정 반환"""
        return {
            "engine": cls.DB_ENGINE,
            "mongo_uri": cls.MONGO_URI,
            "mongo_db": cls.MONGO_DB
        }