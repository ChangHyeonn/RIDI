#!/usr/bin/env python3
"""
Application Settings - Clean Architecture
애플리케이션 설정 (Clean Architecture 버전)
"""

import os
from typing import List, Dict, Any
from dataclasses import dataclass


@dataclass
class ServerConfig:
    """서버 설정"""
    host: str = os.getenv('AI_SERVER_HOST', '0.0.0.0')
    port: int = int(os.getenv('AI_SERVER_PORT', '8080'))
    debug: bool = os.getenv('AI_SERVER_DEBUG', 'False').lower() == 'true'
    allowed_origins: List[str] = None
    
    def __post_init__(self):
        if self.allowed_origins is None:
            self.allowed_origins = [
                "http://localhost:3000",
                "http://127.0.0.1:3000", 
                "http://localhost:8080",
                "http://127.0.0.1:8080",
                "*"  # 개발용
            ]


@dataclass
class LLMConfig:
    """LLM 설정"""
    provider: str = os.getenv('LLM_TYPE', 'openai')
    api_key: str = os.getenv('OPENAI_API_KEY', '')
    model_name: str = os.getenv('LLM_MODEL', 'gpt-4o-mini')
    max_tokens: int = int(os.getenv('LLM_MAX_TOKENS', '1000'))
    temperature: float = float(os.getenv('LLM_TEMPERATURE', '0.2'))


@dataclass 
class DatabaseConfig:
    """데이터베이스 설정"""
    engine: str = os.getenv('DB_ENGINE', 'inmemory')
    mongo_uri: str = os.getenv('MONGO_URI', 'mongodb://localhost:27017/')
    mongo_db: str = os.getenv('MONGO_DB', 'ridi_ai')


@dataclass
class TextProcessingConfig:
    """텍스트 처리 설정"""
    max_length: int = int(os.getenv('MAX_TEXT_LENGTH', '1000'))
    min_length: int = int(os.getenv('MIN_TEXT_LENGTH', '1'))
    timeout: int = int(os.getenv('DEFAULT_RESPONSE_TIMEOUT', '30'))


class AppSettings:
    """애플리케이션 설정 통합 관리"""
    
    def __init__(self):
        self.server = ServerConfig()
        self.llm = LLMConfig()
        self.database = DatabaseConfig()
        self.text_processing = TextProcessingConfig()
    
    def validate(self) -> List[str]:
        """설정 유효성 검증"""
        errors = []
        
        # 서버 설정 검증
        if not (1024 <= self.server.port <= 65535):
            errors.append("포트는 1024-65535 사이여야 합니다")
        
        # LLM 설정 검증
        if self.llm.provider == 'openai' and not self.llm.api_key:
            errors.append("OpenAI 사용 시 OPENAI_API_KEY가 필요합니다")
        
        # 데이터베이스 설정 검증
        if self.database.engine == 'mongodb' and not self.database.mongo_uri:
            errors.append("MongoDB 사용 시 MONGO_URI가 필요합니다")
        
        # 텍스트 처리 설정 검증
        if self.text_processing.max_length < self.text_processing.min_length:
            errors.append("최대 텍스트 길이는 최소 텍스트 길이보다 커야 합니다")
        
        return errors
    
    def to_dict(self) -> Dict[str, Any]:
        """딕셔너리로 변환"""
        return {
            'server': self.server.__dict__,
            'llm': self.llm.__dict__,
            'database': self.database.__dict__,
            'text_processing': self.text_processing.__dict__
        }


# 전역 설정 인스턴스
settings = AppSettings()
