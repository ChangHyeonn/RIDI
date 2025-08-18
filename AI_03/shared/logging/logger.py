#!/usr/bin/env python3
"""
Unified Logging System
통합 로깅 시스템 - 모든 로깅 설정을 중앙화
"""

import logging
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional


class LoggerFactory:
    """중앙화된 로거 팩토리"""
    
    _configured = False
    _log_level = logging.INFO
    _log_format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    
    @classmethod
    def setup_logging(cls, 
                     level: int = logging.INFO,
                     log_to_file: bool = True,
                     log_file_path: Optional[str] = None):
        """전역 로깅 설정 (앱 시작 시 한 번만 호출)"""
        if cls._configured:
            return
            
        cls._log_level = level
        
        # 루트 로거 설정
        root_logger = logging.getLogger()
        root_logger.setLevel(level)
        
        # 기존 핸들러 제거
        for handler in root_logger.handlers[:]:
            root_logger.removeHandler(handler)
        
        # 포매터 설정
        formatter = logging.Formatter(cls._log_format)
        
        # 콘솔 핸들러
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setFormatter(formatter)
        console_handler.setLevel(level)
        root_logger.addHandler(console_handler)
        
        # 파일 핸들러 (선택적)
        if log_to_file:
            if not log_file_path:
                log_dir = Path("logs")
                log_dir.mkdir(exist_ok=True)
                log_file_path = log_dir / f"ai_server_{datetime.now().strftime('%Y%m%d')}.log"
            
            file_handler = logging.FileHandler(log_file_path, encoding='utf-8')
            file_handler.setFormatter(formatter)
            file_handler.setLevel(level)
            root_logger.addHandler(file_handler)
        
        # 외부 라이브러리 로그 레벨 조정
        logging.getLogger('werkzeug').setLevel(logging.WARNING)
        logging.getLogger('urllib3').setLevel(logging.WARNING)
        
        cls._configured = True
    
    @classmethod
    def get_logger(cls, name: str) -> logging.Logger:
        """로거 인스턴스 반환"""
        if not cls._configured:
            cls.setup_logging()
        return logging.getLogger(name)
    
    @classmethod
    def is_configured(cls) -> bool:
        """로깅이 설정되었는지 확인"""
        return cls._configured
