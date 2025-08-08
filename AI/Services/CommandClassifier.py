#!/usr/bin/env python3
"""
Command Classifier
음성 명령 분류 클래스
"""

import logging
import re
import sys
import os
from typing import Dict, Any, List, Optional
from datetime import datetime

# 프롬프트 매니저 import
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from Config.prompts import PromptManager

class CommandClassifier:
    """음성 명령 분류 클래스"""
    
    def __init__(self, llm_type: str = "gemini"):
        self.llm_type = llm_type
        self._setup_logging()
        self._setup_command_patterns()
    
    def _setup_logging(self):
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
    
    def _setup_command_patterns(self):
        """명령 패턴 설정"""
        self.command_patterns = {
            "add_schedule": [
                r"일정\s*추가|일정\s*등록|일정\s*잡아|일정\s*만들어",
                r"내일|오늘|다음주|이번주|월요일|화요일|수요일|목요일|금요일|토요일|일요일",
                r"시|분|시간|오전|오후|아침|점심|저녁"
            ],
            "delete_schedule": [
                r"일정\s*삭제|일정\s*취소|일정\s*지워|일정\s*삭제해",
                r"취소|삭제|지워|없애"
            ],
            "read_schedule": [
                r"일정\s*알려|일정\s*읽어|일정\s*보여|일정\s*말해",
                r"내일\s*일정|오늘\s*일정|다음주\s*일정|이번주\s*일정",
                r"무엇|뭐|어떤|일정"
            ],
            "important_schedule": [
                r"중요\s*일정|중요한\s*일정|중요한\s*것|중요한\s*거",
                r"중요|필요|꼭|반드시"
            ],
            "accessibility": [
                r"글씨\s*크게|글씨\s*작게|글씨\s*조절|폰트\s*크기",
                r"소리\s*크게|소리\s*작게|볼륨\s*조절|음량\s*조절",
                r"속도\s*빠르게|속도\s*느리게|음성\s*속도"
            ]
        }
    
    def classify_command(self, text: str) -> Dict[str, Any]:
        """음성 명령 분류"""
        try:
            # 패턴 매칭으로 기본 분류
            command_type = self._pattern_match(text)
            
            # LLM을 사용한 정확한 분류
            llm_classification = self._llm_classify(text)
            
            # 패턴과 LLM 결과 결합
            final_classification = self._combine_classifications(
                pattern_result=command_type,
                llm_result=llm_classification
            )
            
            self.logger.info(f"Command classified: {text} -> {final_classification['type']}")
            
            return final_classification
            
        except Exception as e:
            self.logger.error(f"Command classification failed: {e}")
            return {
                "type": "unknown",
                "confidence": 0.0,
                "text": text,
                "error": str(e)
            }
    
    def _pattern_match(self, text: str) -> Dict[str, Any]:
        """패턴 매칭으로 명령 분류"""
        text_lower = text.lower()
        
        for command_type, patterns in self.command_patterns.items():
            for pattern in patterns:
                if re.search(pattern, text_lower):
                    return {
                        "type": command_type,
                        "confidence": 0.7,
                        "method": "pattern_match"
                    }
        
        return {
            "type": "unknown",
            "confidence": 0.0,
            "method": "pattern_match"
        }
    
    def _llm_classify(self, text: str) -> Dict[str, Any]:
        """LLM을 사용한 명령 분류"""
        try:
            # 간단한 규칙 기반 분류 (LLM 없이)
            prompt = PromptManager.get_command_classification_prompt(text)
            
            # 실제로는 LLM 호출
            # 현재는 간단한 키워드 기반 분류
            return self._simple_classify(text)
            
        except Exception as e:
            self.logger.error(f"LLM classification failed: {e}")
            return {
                "type": "unknown",
                "confidence": 0.0,
                "method": "llm_classify"
            }
    
    def _simple_classify(self, text: str) -> Dict[str, Any]:
        """간단한 키워드 기반 분류"""
        text_lower = text.lower()
        
        # 일정 추가 키워드
        if any(word in text_lower for word in ["추가", "등록", "잡아", "만들어", "예약"]):
            return {
                "type": "add_schedule",
                "confidence": 0.8,
                "method": "simple_classify"
            }
        
        # 일정 삭제 키워드
        elif any(word in text_lower for word in ["삭제", "취소", "지워", "없애"]):
            return {
                "type": "delete_schedule",
                "confidence": 0.8,
                "method": "simple_classify"
            }
        
        # 일정 읽기 키워드
        elif any(word in text_lower for word in ["알려", "읽어", "보여", "말해", "무엇", "뭐"]):
            return {
                "type": "read_schedule",
                "confidence": 0.8,
                "method": "simple_classify"
            }
        
        # 중요 일정 키워드
        elif any(word in text_lower for word in ["중요", "필요", "꼭", "반드시"]):
            return {
                "type": "important_schedule",
                "confidence": 0.8,
                "method": "simple_classify"
            }
        
        # 접근성 키워드
        elif any(word in text_lower for word in ["글씨", "폰트", "소리", "볼륨", "속도"]):
            return {
                "type": "accessibility",
                "confidence": 0.8,
                "method": "simple_classify"
            }
        
        return {
            "type": "unknown",
            "confidence": 0.0,
            "method": "simple_classify"
        }
    
    def _combine_classifications(self, pattern_result: Dict[str, Any], 
                               llm_result: Dict[str, Any]) -> Dict[str, Any]:
        """패턴과 LLM 결과 결합"""
        pattern_confidence = pattern_result.get("confidence", 0.0)
        llm_confidence = llm_result.get("confidence", 0.0)
        
        # 더 높은 신뢰도를 가진 결과 선택
        if llm_confidence > pattern_confidence:
            return llm_result
        else:
            return pattern_result
    
    def extract_command_info(self, text: str, command_type: str) -> Dict[str, Any]:
        """명령에서 정보 추출"""
        try:
            if command_type == "add_schedule":
                return self._extract_schedule_info(text)
            elif command_type == "delete_schedule":
                return self._extract_delete_info(text)
            elif command_type == "read_schedule":
                return self._extract_date_info(text)
            elif command_type == "accessibility":
                return self._extract_accessibility_info(text)
            else:
                return {"raw_text": text}
                
        except Exception as e:
            self.logger.error(f"Info extraction failed: {e}")
            return {"raw_text": text}
    
    def _extract_schedule_info(self, text: str) -> Dict[str, Any]:
        """일정 정보 추출"""
        # 간단한 정규식 기반 추출
        info = {
            "title": "",
            "datetime": "",
            "category": "일반",
            "priority": "not_important"
        }
        
        # 날짜/시간 패턴
        date_patterns = [
            r"내일|오늘|다음주|이번주",
            r"월요일|화요일|수요일|목요일|금요일|토요일|일요일",
            r"\d{1,2}시|\d{1,2}분|오전|오후|아침|점심|저녁"
        ]
        
        for pattern in date_patterns:
            match = re.search(pattern, text)
            if match:
                info["datetime"] = match.group()
                break
        
        return info
    
    def _extract_delete_info(self, text: str) -> Dict[str, Any]:
        """삭제 정보 추출"""
        return {
            "target": text,
            "action": "delete"
        }
    
    def _extract_date_info(self, text: str) -> Dict[str, Any]:
        """날짜 정보 추출"""
        date_patterns = [
            r"내일|오늘|다음주|이번주",
            r"월요일|화요일|수요일|목요일|금요일|토요일|일요일"
        ]
        
        for pattern in date_patterns:
            match = re.search(pattern, text)
            if match:
                return {"date": match.group()}
        
        return {"date": "today"}
    
    def _extract_accessibility_info(self, text: str) -> Dict[str, Any]:
        """접근성 정보 추출"""
        text_lower = text.lower()
        
        if "글씨" in text_lower or "폰트" in text_lower:
            if "크게" in text_lower:
                return {"setting": "font_size", "value": "large"}
            elif "작게" in text_lower:
                return {"setting": "font_size", "value": "small"}
        
        elif "소리" in text_lower or "볼륨" in text_lower:
            if "크게" in text_lower:
                return {"setting": "volume_level", "value": "increase"}
            elif "작게" in text_lower:
                return {"setting": "volume_level", "value": "decrease"}
        
        elif "속도" in text_lower:
            if "빠르게" in text_lower:
                return {"setting": "speech_rate", "value": "increase"}
            elif "느리게" in text_lower:
                return {"setting": "speech_rate", "value": "decrease"}
        
        return {"setting": "unknown", "value": "unknown"}
    
    def get_classifier_info(self) -> Dict[str, Any]:
        """분류기 정보"""
        return {
            "classifier_type": "Command Classifier",
            "supported_commands": [
                "add_schedule",
                "delete_schedule", 
                "read_schedule",
                "important_schedule",
                "accessibility"
            ],
            "llm_type": self.llm_type,
            "features": {
                "pattern_matching": True,
                "llm_classification": True,
                "info_extraction": True
            }
        } 