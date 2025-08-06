import sys
import os
import json
import logging
import re
from datetime import datetime, timedelta
from typing import Dict, Any, Optional
from dotenv import load_dotenv

from LLM import LLMFactory

class ScheduleClassifier:
    """일정 정보 분류기"""
    
    def __init__(self, llm_type: str = "gemini"):
        load_dotenv()
        
        self.llm_type = llm_type
        self._setup_logging()
        self._initialize_llm()
        self._setup_prompts()
        self.logger.info(f"Schedule Classifier initialized successfully with {llm_type}")
    
    def _setup_logging(self):
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
    
    def _initialize_llm(self):
        try:
            self.llm = LLMFactory.create_llm(self.llm_type)
            self.logger.info(f"LLM initialized: {self.llm.get_model_info()['model_name']}")
        except Exception as e:
            self.logger.error(f"Failed to initialize LLM: {e}")
            raise
    
    def _setup_prompts(self):
        current_date = datetime.now().strftime("%Y-%m-%d")
        
        self.system_prompt = f"""당신은 일정 관리 AI 어시스턴트입니다. 
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
    
    def classify_schedule(self, text: str) -> Dict[str, Any]:
        try:
            self.logger.info(f"Classifying schedule from: {text}")
            
            # 현재 날짜 정보 추가
            current_date = datetime.now().strftime("%Y-%m-%d")
            prompt = self.system_prompt.replace("{current_date}", current_date)
            
            # LLM에 분석 요청
            full_prompt = f"{prompt}\n\n사용자 입력: {text}\n\n분석 결과 (JSON만):"
            response = self.llm.generate_response(full_prompt)
            
            # 응답 정리
            response = response.strip()
            if response.startswith("```json"):
                response = response[7:]
            if response.endswith("```"):
                response = response[:-3]
            response = response.strip()
            
            # JSON 파싱
            schedule_info = self._parse_json_response(response)
            
            # 입력 완성도 검증
            validation_result = self._validate_input_completeness(schedule_info, text)
            if validation_result["needs_clarification"]:
                return {
                    "is_schedule": False,
                    "needs_clarification": True,
                    "questions": validation_result["questions"],
                    "original_input": text
                }
            
            # 검증 및 보정
            validated_info = self._validate_and_correct(schedule_info, text)
            
            return {
                "is_schedule": True,
                "schedule_info": validated_info,
                "original_input": text
            }
            
        except Exception as e:
            self.logger.error(f"Schedule classification failed: {e}")
            return {
                "is_schedule": False,
                "error": str(e),
                "original_input": text
            }
    
    def _parse_json_response(self, response: str) -> Dict[str, Any]:
        """LLM 응답에서 JSON 파싱"""
        try:
            import re
            
            json_pattern = r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}'
            matches = re.findall(json_pattern, response)
            
            if matches:
                json_str = max(matches, key=len)
                self.logger.info(f"Found JSON: {json_str}")
                return json.loads(json_str)
            
            start_idx = response.find('{')
            end_idx = response.rfind('}') + 1
            
            if start_idx != -1 and end_idx != -1:
                json_str = response[start_idx:end_idx]
                self.logger.info(f"Fallback JSON: {json_str}")
                return json.loads(json_str)
            else:
                raise ValueError("JSON not found in response")
                
        except Exception as e:
            self.logger.error(f"Failed to parse JSON: {e}")
            raise
    
    def _validate_input_completeness(self, schedule_info: Dict[str, Any], original_text: str) -> Dict[str, Any]:
        """입력 완성도 검증"""
        missing_info = []
        
        # 제목 검증
        if not schedule_info.get("title") or schedule_info["title"] in ["일정", "일정 제목"]:
            missing_info.append("일정 내용")
        
        # 시간 검증
        current_time = datetime.now().strftime("%Y-%m-%d %H:%M")
        if not schedule_info.get("datetime") or schedule_info["datetime"] == current_time:
            missing_info.append("일정 시간")
        
        # 구체적인 시간이 없는 경우 검증
        if self._has_vague_time_expression(original_text):
            missing_info.append("정확한 시간")
        
        if missing_info:
            questions = []
            if "일정 내용" in missing_info:
                questions.append("일정 내용을 말씀해 주시겠어요?")
            if "일정 시간" in missing_info or "정확한 시간" in missing_info:
                questions.append("정확한 시간을 말씀해 주시겠어요? (예: 오전 9시, 오후 2시)")
            
            return {
                "needs_clarification": True,
                "missing_info": missing_info,
                "questions": questions,
                "original_input": original_text,
                "partial_info": schedule_info
            }
        
        return {"needs_clarification": False}
    
    def _has_vague_time_expression(self, text: str) -> bool:
        # 구체적인 시간 패턴 (숫자 + 시)
        specific_time_patterns = [
            r"(\d{1,2})시",
            r"오전\s*(\d{1,2})시",
            r"오후\s*(\d{1,2})시",
            r"아침\s*(\d{1,2})시",
            r"저녁\s*(\d{1,2})시"
        ]
        
        # 모호한 시간 표현
        vague_time_patterns = [
            r"오전", r"오후", r"아침", r"저녁", r"점심", r"밤"
        ]
        
        # 구체적인 시간이 있는지 확인
        has_specific_time = any(re.search(pattern, text) for pattern in specific_time_patterns)
        
        # 모호한 시간 표현이 있는지 확인
        has_vague_time = any(re.search(pattern, text) for pattern in vague_time_patterns)
        
        # 모호한 시간만 있고 구체적인 시간이 없는 경우
        return has_vague_time and not has_specific_time
    
    def _validate_and_correct(self, schedule_info: Dict[str, Any], original_text: str) -> Dict[str, Any]:
        """추출된 정보 검증 및 보정"""
        default_info = {
            "title": "일정",
            "datetime": datetime.now().strftime("%Y-%m-%d %H:%M"),
            "category": "일반",
            "priority": "medium",
            "repeat": False,
            "reminder": True,
            "description": original_text
        }
        
        # 필수 필드 검증
        for key, default_value in default_info.items():
            if key not in schedule_info or not schedule_info[key]:
                schedule_info[key] = default_value
        
        # 날짜/시간 검증 및 보정
        try:
            datetime.strptime(schedule_info["datetime"], "%Y-%m-%d %H:%M")
        except:
            corrected_datetime = self._extract_datetime_from_text(original_text)
            if corrected_datetime:
                schedule_info["datetime"] = corrected_datetime
            else:
                schedule_info["datetime"] = default_info["datetime"]
        
        # 카테고리 검증
        valid_categories = ["건강", "경조사", "일반"]
        if schedule_info["category"] not in valid_categories:
            schedule_info["category"] = "일반"
        
        # 중요도 검증 및 자동 설정
        valid_priorities = ["important", "not_important"]
        if schedule_info["priority"] not in valid_priorities:
            if schedule_info["category"] == "건강":
                schedule_info["priority"] = "important"
            else:
                schedule_info["priority"] = "not_important"
        
        return schedule_info
    
    def _extract_datetime_from_text(self, text: str) -> Optional[str]:
        try:
            now = datetime.now()
            
            # 구체적인 시간 패턴만 허용 (default 값 제거)
            time_patterns = [
                (r"저녁\s*(\d{1,2})시", lambda hour: f"{hour:02d}:00"),
                (r"오후\s*(\d{1,2})시", lambda hour: f"{hour+12:02d}:00" if hour < 12 else f"{hour:02d}:00"),
                (r"오전\s*(\d{1,2})시", lambda hour: f"{hour:02d}:00"),
                (r"아침\s*(\d{1,2})시", lambda hour: f"{hour:02d}:00"),
                (r"(\d{1,2})시", lambda hour: f"{hour:02d}:00")
            ]
            
            time_str = None
            
            for pattern, time_func in time_patterns:
                match = re.search(pattern, text)
                if match:
                    time_str = time_func(int(match.group(1)))
                    break
            
            if time_str is None:
                return None
            
            # 날짜 패턴 매칭
            if "내일" in text:
                target_date = now + timedelta(days=1)
            elif "어제" in text:
                target_date = now + timedelta(days=-1)
            elif "모레" in text:
                target_date = now + timedelta(days=2)
            elif "그저께" in text or "그제" in text:
                target_date = now + timedelta(days=-2)
            elif "다음 주" in text or "다음주" in text:
                target_date = now + timedelta(days=7)
            elif "다음 달" in text or "다음달" in text:
                target_date = now + timedelta(days=30)
            elif "오늘" in text:
                target_date = now
            else:
                target_date = now
            
            return target_date.strftime("%Y-%m-%d") + " " + time_str
            
        except Exception as e:
            self.logger.error(f"Failed to extract datetime from text: {e}")
            return None
    
    def get_classifier_info(self) -> Dict[str, Any]:
        """분류기 정보 반환"""
        return {
            "classifier_type": "Schedule Classifier",
            "llm_model": self.llm.get_model_info(),
            "supported_categories": ["건강", "경조사", "일반"],
            "supported_priorities": ["important", "not_important"],
            "features": {
                "schedule_extraction": True,
                "time_validation": True,
                "input_completeness_check": True,
                "auto_health_priority": True
            }
        }

 