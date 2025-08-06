#!/usr/bin/env python3
"""
Settings Configuration
고령층 일정 메모 관리 AI 서버 설정
"""

import os
from typing import List

class Settings:
    """애플리케이션 설정 클래스"""
    
    # 서버 설정
    HOST = os.getenv('HOST', '0.0.0.0')
    PORT = int(os.getenv('PORT', 5000))
    DEBUG = os.getenv('DEBUG', 'False').lower() == 'true'
    
    # CORS 설정
    ALLOWED_ORIGINS = os.getenv('ALLOWED_ORIGINS', '*').split(',')
    
    # AI 모델 설정
    STT_MODEL = os.getenv('STT_MODEL', 'small')
    LLM_TYPE = os.getenv('LLM_TYPE', 'gemini')
    DEVICE = os.getenv('DEVICE', 'auto')
    
    # 접근성 설정
    FONT_SIZE = os.getenv('FONT_SIZE', 'medium')  # small, medium, large
    VOLUME_LEVEL = float(os.getenv('VOLUME_LEVEL', 1.0))  # 0.5 ~ 2.0
    SPEECH_RATE = float(os.getenv('SPEECH_RATE', 1.0))  # 0.5 ~ 2.0
    HIGH_CONTRAST = os.getenv('HIGH_CONTRAST', 'False').lower() == 'true'
    TEXT_TO_SPEECH = os.getenv('TEXT_TO_SPEECH', 'True').lower() == 'true'
    REPEAT_IMPORTANT = os.getenv('REPEAT_IMPORTANT', 'True').lower() == 'true'
    SIMPLE_RESPONSES = os.getenv('SIMPLE_RESPONSES', 'True').lower() == 'true'
    
    # 일정 관리 설정
    MAX_SCHEDULES_PER_USER = int(os.getenv('MAX_SCHEDULES_PER_USER', 100))
    SCHEDULE_REMINDER_DEFAULT = os.getenv('SCHEDULE_REMINDER_DEFAULT', 'True').lower() == 'true'
    SCHEDULE_CATEGORIES = ['일반', '건강', '경조사']
    SCHEDULE_PRIORITIES = ['not_important', 'important']
    
    # 명령 분류 설정
    COMMAND_CLASSIFICATION_ENABLED = os.getenv('COMMAND_CLASSIFICATION_ENABLED', 'True').lower() == 'true'
    COMMAND_CONFIDENCE_THRESHOLD = float(os.getenv('COMMAND_CONFIDENCE_THRESHOLD', 0.7))
    
    # 기본값 설정
    DEFAULT_FONT_SIZE = 'medium'
    DEFAULT_VOLUME_LEVEL = 1.0
    DEFAULT_SPEECH_RATE = 1.0
    DEFAULT_HIGH_CONTRAST = False
    DEFAULT_TEXT_TO_SPEECH = True
    DEFAULT_REPEAT_IMPORTANT = True
    DEFAULT_SIMPLE_RESPONSES = True
    
    # 보안 설정
    API_KEY = os.getenv('API_KEY')
    MAX_AUDIO_SIZE = int(os.getenv('MAX_AUDIO_SIZE', 10 * 1024 * 1024))  # 10MB
    MAX_REQUEST_SIZE = int(os.getenv('MAX_REQUEST_SIZE', 16 * 1024 * 1024))  # 16MB
    
    # 로깅 설정
    LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
    LOG_FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    
    # 파일 업로드 설정
    UPLOAD_FOLDER = os.getenv('UPLOAD_FOLDER', '/tmp/ai_uploads')
    ALLOWED_AUDIO_EXTENSIONS = {'.wav', '.mp3', '.m4a', '.flac', '.ogg'}
    
    # 메모리 관리 설정
    MAX_MEMORY_ITEMS = int(os.getenv('MAX_MEMORY_ITEMS', 100))
    MEMORY_EXPIRY_HOURS = int(os.getenv('MEMORY_EXPIRY_HOURS', 24))
    
    # 일정 관리 설정
    DEFAULT_REMINDER_MINUTES = int(os.getenv('DEFAULT_REMINDER_MINUTES', 30))
    
    @classmethod
    def get_device(cls) -> str:
        """자동 디바이스 감지"""
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
        """설정 유효성 검사"""
        errors = []
        
        if cls.PORT < 1 or cls.PORT > 65535:
            errors.append("PORT must be between 1 and 65535")
        
        if cls.SPEECH_RATE <= 0 or cls.SPEECH_RATE > 2:
            errors.append("SPEECH_RATE must be between 0 and 2")
        
        if cls.VOLUME_LEVEL <= 0 or cls.VOLUME_LEVEL > 3:
            errors.append("VOLUME_LEVEL must be between 0 and 3")
        
        if cls.MAX_AUDIO_SIZE <= 0:
            errors.append("MAX_AUDIO_SIZE must be positive")
        
        return errors 