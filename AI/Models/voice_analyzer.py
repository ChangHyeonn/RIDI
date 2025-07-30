# Example

import re
import json
from datetime import datetime, timedelta
from typing import Dict, Any

class VoiceAnalyzer:
    """음성 입력을 분석하여 구조화된 데이터로 변환"""
    
    def __init__(self):
        self._setup_categories()
        self._setup_time_patterns()
        self._setup_date_patterns()
    
    def _setup_categories(self):
        """카테고리 매핑 설정"""
        self.categories = {
            "가족": "family",
            "병원": "medical", 
            "회의": "meeting",
            "약속": "appointment",
            "생일": "birthday",
            "기념일": "anniversary",
            "식사": "meal",
            "저녁": "meal",
            "점심": "meal",
            "아침": "meal",
            "일반": "general"
        }
    
    def _setup_time_patterns(self):
        """시간 패턴 설정"""
        self.time_patterns = [
            r"오전\s*(\d{1,2})시",
            r"오후\s*(\d{1,2})시", 
            r"(\d{1,2})시",
            r"(\d{1,2}):(\d{2})",
            r"저녁\s*(\d{1,2})시",
            r"점심\s*(\d{1,2})시",
            r"아침\s*(\d{1,2})시"
        ]
    
    def _setup_date_patterns(self):
        """날짜 패턴 설정"""
        self.date_patterns = [
            r"오늘",
            r"내일", 
            r"모레",
            r"이틀\s*뒤",
            r"삼일\s*뒤",
            r"일주일\s*뒤",
            r"다음\s*주",
            r"(\d{1,2})월\s*(\d{1,2})일",
            r"(\d{1,2})일"
        ]
    
    def analyze_voice_input(self, transcribed_text: str) -> Dict[str, Any]:
        """음성 입력을 분석하여 구조화된 데이터 반환"""
        
        print(f"🔍 음성 분석 시작: '{transcribed_text}'")
        
        # 1. 날짜 추출
        date_info = self._extract_date(transcribed_text)
        print(f"📅 날짜 추출: {date_info}")
        
        # 2. 시간 추출
        time_info = self._extract_time(transcribed_text)
        print(f"⏰ 시간 추출: {time_info}")
        
        # 3. 제목 추출
        title_info = self._extract_title(transcribed_text)
        print(f"📝 제목 추출: {title_info}")
        
        # 4. 카테고리 분류
        category_info = self._classify_category(transcribed_text)
        print(f"🏷️ 카테고리 분류: {category_info}")
        
        # 5. 구조화된 데이터 생성
        structured_data = {
            "date": date_info,
            "time": time_info,
            "title": title_info,
            "category": category_info,
            "original_text": transcribed_text,
            "confidence": self._calculate_confidence(transcribed_text)
        }
        
        print(f"✅ 구조화 완료: {json.dumps(structured_data, ensure_ascii=False, indent=2)}")
        return structured_data
    
    def _extract_date(self, text: str) -> str:
        """날짜 추출"""
        today = datetime.now()
        
        # 상대적 날짜 패턴 매칭
        if "오늘" in text:
            return today.strftime("%Y-%m-%d")
        elif "내일" in text:
            return (today + timedelta(days=1)).strftime("%Y-%m-%d")
        elif "모레" in text or "이틀 뒤" in text:
            return (today + timedelta(days=2)).strftime("%Y-%m-%d")
        elif "삼일 뒤" in text:
            return (today + timedelta(days=3)).strftime("%Y-%m-%d")
        elif "일주일 뒤" in text or "다음 주" in text:
            return (today + timedelta(days=7)).strftime("%Y-%m-%d")
        
        # 절대적 날짜 패턴 매칭
        month_day_pattern = r"(\d{1,2})월\s*(\d{1,2})일"
        match = re.search(month_day_pattern, text)
        if match:
            month = int(match.group(1))
            day = int(match.group(2))
            return f"{today.year}-{month:02d}-{day:02d}"
        
        # 기본값: 오늘
        return today.strftime("%Y-%m-%d")
    
    def _extract_time(self, text: str) -> str:
        """시간 추출"""
        # 시간 패턴 매칭
        for pattern in self.time_patterns:
            match = re.search(pattern, text)
            if match:
                if "오후" in pattern or "저녁" in pattern:
                    hour = int(match.group(1)) + 12
                    if hour == 24:
                        hour = 12
                elif "오전" in pattern or "아침" in pattern:
                    hour = int(match.group(1))
                    if hour == 12:
                        hour = 0
                else:
                    hour = int(match.group(1))
                
                if len(match.groups()) > 1:
                    minute = match.group(2)
                else:
                    minute = "00"
                
                return f"{hour:02d}:{minute}"
        
        # 기본값: 오후 2시
        return "14:00"
    
    def _extract_title(self, text: str) -> str:
        """제목 추출"""
        # 제거할 키워드들
        remove_keywords = [
            "일정", "약속", "예약", "추가", "등록", "잡아", "잡아주세요",
            "오늘", "내일", "모레", "이틀 뒤", "삼일 뒤", "일주일 뒤", "다음 주",
            "오전", "오후", "저녁", "점심", "아침", "시", "분",
            "나", "저", "제가", "있어", "해주세요", "부탁해"
        ]
        
        title = text
        for keyword in remove_keywords:
            title = title.replace(keyword, "")
        
        # 불필요한 공백 제거
        title = " ".join(title.split())
        
        # 기본값 설정
        if not title or len(title) < 2:
            title = "일정"
        
        return title.strip()
    
    def _classify_category(self, text: str) -> str:
        """카테고리 분류"""
        text_lower = text.lower()
        
        # 카테고리 키워드 매칭
        for korean, english in self.categories.items():
            if korean in text_lower:
                return english
        
        # 추가 분류 로직
        if "가족" in text or "가족들" in text:
            return "family"
        elif "병원" in text or "의원" in text or "클리닉" in text:
            return "medical"
        elif "회의" in text or "미팅" in text:
            return "meeting"
        elif "식사" in text or "저녁" in text or "점심" in text or "아침" in text:
            return "meal"
        elif "생일" in text:
            return "birthday"
        elif "기념일" in text:
            return "anniversary"
        
        return "general"
    
    def _calculate_confidence(self, text: str) -> float:
        """신뢰도 계산"""
        confidence = 0.0
        
        # 날짜 정보가 있으면 +0.3
        if any(keyword in text for keyword in ["오늘", "내일", "모레", "이틀", "일주일"]):
            confidence += 0.3
        
        # 시간 정보가 있으면 +0.3
        if any(keyword in text for keyword in ["시", "분", "오전", "오후", "저녁", "점심"]):
            confidence += 0.3
        
        # 카테고리 정보가 있으면 +0.2
        if any(keyword in text for keyword in self.categories.keys()):
            confidence += 0.2
        
        # 제목 정보가 있으면 +0.2
        if len(self._extract_title(text)) > 2:
            confidence += 0.2
        
        return min(confidence, 1.0)

def main():
    print("🔍 Voice Analyzer 테스트")
    
    analyzer = VoiceAnalyzer()
    
    # 테스트 케이스들
    test_cases = [
        "나 이틀 뒤 오후 7시에 가족들이랑 저녁 식사 일정 있어",
        "내일 오전 10시에 병원 예약 잡아주세요",
        "다음 주 월요일 오후 2시에 회의가 있어요",
        "오늘 저녁 6시에 가족과 저녁 식사",
        "내일 오후 3시에 치과 예약"
    ]
    
    for i, test_case in enumerate(test_cases, 1):
        print(f"\n🧪 테스트 케이스 {i}: '{test_case}'")
        result = analyzer.analyze_voice_input(test_case)
        
        print(f"📊 분석 결과:")
        print(f"  📅 날짜: {result['date']}")
        print(f"  ⏰ 시간: {result['time']}")
        print(f"  📝 제목: {result['title']}")
        print(f"  🏷️ 카테고리: {result['category']}")
        print(f"  🎯 신뢰도: {result['confidence']:.1%}")

if __name__ == "__main__":
    main() 