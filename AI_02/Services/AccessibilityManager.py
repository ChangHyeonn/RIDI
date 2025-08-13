#!/usr/bin/env python3
"""
Accessibility Manager
접근성 관리 전담 클래스
"""

import logging
from typing import Dict, Any, Optional
from collections import defaultdict

class AccessibilityManager:
    """접근성 관리 전담 클래스"""
    
    def __init__(self):
        self.user_settings = defaultdict(dict)  # user_id -> accessibility_settings
        self._setup_logging()
        self._setup_default_settings()
    
    def _setup_logging(self):
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
    
    def _setup_default_settings(self):
        """기본 접근성 설정"""
        self.default_settings = {
            "font_size": "medium",  # small, medium, large
            "volume_level": 1.0,    # 0.5 ~ 2.0
            "speech_rate": 1.0,     # 0.5 ~ 2.0
            "high_contrast": False,  # 고대비 모드
            "text_to_speech": True,  # 텍스트 음성 변환
            "repeat_important": True, # 중요한 내용 반복
            "simple_responses": True  # 간단한 응답
        }
    
    def update_accessibility_settings(self, user_id: str, settings: Dict[str, Any]) -> Dict[str, Any]:
        """접근성 설정 업데이트"""
        try:
            # 기존 설정 가져오기
            current_settings = self.user_settings[user_id].copy()
            
            # 새 설정 적용
            for key, value in settings.items():
                if key in self.default_settings:
                    # 값 검증
                    validated_value = self._validate_setting(key, value)
                    current_settings[key] = validated_value
            
            # 기본값으로 채우기
            for key, default_value in self.default_settings.items():
                if key not in current_settings:
                    current_settings[key] = default_value
            
            self.user_settings[user_id] = current_settings
            
            self.logger.info(f"Accessibility settings updated for user {user_id}")
            
            return {
                "success": True,
                "message": "접근성 설정이 업데이트되었습니다.",
                "settings": current_settings
            }
            
        except Exception as e:
            self.logger.error(f"Failed to update accessibility settings: {e}")
            return {
                "success": False,
                "error": f"접근성 설정 업데이트 중 오류가 발생했습니다: {str(e)}"
            }
    
    def get_accessibility_settings(self, user_id: str) -> Dict[str, Any]:
        """접근성 설정 조회"""
        if user_id not in self.user_settings:
            # 기본 설정 반환
            return self.default_settings.copy()
        
        return self.user_settings[user_id]
    
    def _validate_setting(self, key: str, value: Any) -> Any:
        """설정값 검증"""
        if key == "font_size":
            valid_sizes = ["small", "medium", "large"]
            return value if value in valid_sizes else "medium"
        
        elif key == "volume_level":
            try:
                volume = float(value)
                return max(0.5, min(2.0, volume))
            except (ValueError, TypeError):
                return 1.0
        
        elif key == "speech_rate":
            try:
                rate = float(value)
                return max(0.5, min(2.0, rate))
            except (ValueError, TypeError):
                return 1.0
        
        elif key in ["high_contrast", "text_to_speech", "repeat_important", "simple_responses"]:
            return bool(value)
        
        return value
    
    def get_font_size_multiplier(self, user_id: str) -> float:
        """글씨 크기 배율 반환"""
        settings = self.get_accessibility_settings(user_id)
        font_size = settings.get("font_size", "medium")
        
        multipliers = {
            "small": 0.8,
            "medium": 1.0,
            "large": 1.3
        }
        
        return multipliers.get(font_size, 1.0)
    
    def get_volume_level(self, user_id: str) -> float:
        """볼륨 레벨 반환"""
        settings = self.get_accessibility_settings(user_id)
        return settings.get("volume_level", 1.0)
    
    def get_speech_rate(self, user_id: str) -> float:
        """음성 속도 반환"""
        settings = self.get_accessibility_settings(user_id)
        return settings.get("speech_rate", 1.0)
    
    def should_repeat_important(self, user_id: str) -> bool:
        """중요 내용 반복 여부"""
        settings = self.get_accessibility_settings(user_id)
        return settings.get("repeat_important", True)
    
    def should_use_simple_responses(self, user_id: str) -> bool:
        """간단한 응답 사용 여부"""
        settings = self.get_accessibility_settings(user_id)
        return settings.get("simple_responses", True)
    
    def get_accessibility_info(self) -> Dict[str, Any]:
        """접근성 관리 정보"""
        total_users = len(self.user_settings)
        
        # 설정 통계
        font_size_stats = defaultdict(int)
        volume_stats = defaultdict(int)
        
        for user_settings in self.user_settings.values():
            font_size = user_settings.get("font_size", "medium")
            font_size_stats[font_size] += 1
            
            volume = user_settings.get("volume_level", 1.0)
            volume_range = "normal"
            if volume < 0.8:
                volume_range = "low"
            elif volume > 1.2:
                volume_range = "high"
            volume_stats[volume_range] += 1
        
        return {
            "total_users": total_users,
            "font_size_distribution": dict(font_size_stats),
            "volume_distribution": dict(volume_stats),
            "memory_usage": len(self.user_settings)
        } 