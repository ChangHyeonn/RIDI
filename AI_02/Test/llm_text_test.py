#!/usr/bin/env python3
"""
LLM 텍스트 처리 테스트
사용자가 텍스트를 입력하면 AI 서버의 LLM이 처리한 응답을 시뮬레이션하여 출력
"""

import sys
import os
import json
from typing import Dict, Any

# AI_02 모듈 import를 위한 경로 추가
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from Processor.unified_voice_pipeline import UnifiedTextPipeline
from Config.settings import Settings
from Services.ScheduleManager import ScheduleManager
from Models.LLM import LLMFactory

class LLMTextTester:
    """LLM 텍스트 처리 테스터"""
    
    def __init__(self):
        """초기화"""
        self.pipeline = None
        self.schedule_manager = None
        self.user_id = "test_user_123"
        self.llm = None
        
        print("🤖 LLM 텍스트 처리 테스터 초기화 중...")
        self._initialize_components()
        print("✅ 초기화 완료!")
        print()
    
    def _initialize_components(self):
        """컴포넌트 초기화"""
        try:
            # 설정 검증
            errors = Settings.validate_settings()
            if errors:
                print("❌ 설정 오류:")
                for error in errors:
                    print(f"   - {error}")
                return
            
            # LLM 설정 확인
            llm_config = Settings.get_llm_config()
            if not llm_config.get("api_key"):
                print("⚠️  API 키가 설정되지 않았습니다. 기본 응답 모드로 실행됩니다.")
                print("   환경 변수 GOOGLE_API_KEY를 설정하세요.")
            
            # 스케줄 매니저 초기화
            self.schedule_manager = ScheduleManager()
            
            # 텍스트 파이프라인 초기화
            self.pipeline = UnifiedTextPipeline(
                llm_type=Settings.LLM_TYPE
            )
            # 직접 LLM 호출용 클라이언트 (OpenAI)
            self.llm = LLMFactory.create_llm(model_type=Settings.LLM_TYPE)
            
        except Exception as e:
            print(f"❌ 초기화 오류: {e}")
            raise
    
    def simulate_text_processing(self, user_text: str) -> Dict[str, Any]:
        """텍스트 처리 시뮬레이션
        - 우선 직접 LLM 한 번 호출하여 답변 반환 (요청 1회)
        - 실패 시 파이프라인으로 처리 시도
        """
        try:
            print(f"📝 사용자 입력: {user_text}")
            print("🔄 AI 서버에서 처리 중...")
            
            # 1) 직접 LLM 호출 (단일 호출)
            if self.llm is not None:
                answer = self.llm.generate_response(user_text)
                if answer and isinstance(answer, str) and answer.strip():
                    print("✅ 처리 완료! (Direct LLM)")
                    return {
                        "success": True,
                        "text_response": {
                            "text": answer.strip(),
                            "display_automatically": True
                        },
                        "action": {
                            "type": "general_response",
                            "data": {}
                        }
                    }
            
            # 2) 파이프라인 처리 (의도/추출 포함)
            response = self.pipeline.process_text(user_text, user_id=self.user_id)
            print("✅ 처리 완료! (Pipeline)")
            return response
            
        except Exception as e:
            print(f"❌ 처리 오류: {e}")
            return {
                "success": False,
                "error": str(e),
                "text_response": {
                    "text": "죄송합니다. 처리 중 오류가 발생했습니다.",
                    "display_automatically": True
                }
            }
    
    def format_response(self, response: Dict[str, Any]) -> str:
        """응답을 사용자 친화적으로 포맷팅"""
        if not response.get("success", False):
            return f"❌ 오류: {response.get('error', '알 수 없는 오류')}"
        
        # 텍스트 응답 추출
        text_response = response.get("text_response", {})
        response_text = text_response.get("text", "응답이 없습니다.")
        
        # 액션 정보 추출
        action = response.get("action", {})
        action_type = action.get("type", "unknown")
        action_data = action.get("data", {})
        
        # 포맷팅된 출력
        output = []
        output.append("🤖 AI 응답:")
        output.append(f"   💬 {response_text}")
        output.append("")
        
        if action_type != "unknown":
            output.append("📋 처리된 액션:")
            output.append(f"   🎯 타입: {action_type}")
            
            # 액션 타입별 상세 정보
            if action_type == "schedule_add":
                schedule = action_data.get("schedule", {})
                output.append(f"   📅 일정: {schedule.get('title', 'N/A')}")
                output.append(f"   🕐 시간: {schedule.get('datetime', 'N/A')}")
                
            elif action_type == "schedule_list":
                schedules = action_data.get("schedules", [])
                output.append(f"   📋 일정 개수: {len(schedules)}개")
                for i, schedule in enumerate(schedules[:3], 1):  # 최대 3개만 표시
                    output.append(f"   {i}. {schedule.get('title', 'N/A')} - {schedule.get('datetime', 'N/A')}")
                if len(schedules) > 3:
                    output.append(f"   ... 외 {len(schedules) - 3}개")
                    
            elif action_type == "schedule_delete":
                deleted = action_data.get("deleted_schedule", {})
                output.append(f"   🗑️ 삭제된 일정: {deleted.get('title', 'N/A')}")
                
            elif action_type == "clarification_request":
                message = action_data.get("message", "추가 정보가 필요합니다.")
                output.append(f"   ❓ 명확화 요청: {message}")
                
            elif action_type == "general_response":
                output.append("   💭 일반 대화 응답")
        
        # UI 지시사항 표시
        ui_instructions = action.get("ui_instructions", {})
        if ui_instructions:
            output.append("")
            output.append("📱 UI 지시사항:")
            for key, value in ui_instructions.items():
                output.append(f"   • {key}: {value}")
        
        return "\n".join(output)
    
    def run_interactive_test(self):
        """대화형 테스트 실행"""
        print("=" * 60)
        print("🤖 LLM 텍스트 처리 테스터")
        print("=" * 60)
        print("사용법:")
        print("  • 텍스트를 입력하면 AI 서버가 처리한 응답을 시뮬레이션합니다")
        print("  • 'quit' 또는 'exit'를 입력하면 종료됩니다")
        print("  • 'help'를 입력하면 예시를 볼 수 있습니다")
        print("=" * 60)
        print()
        
        while True:
            try:
                # 사용자 입력 받기
                user_input = input("💬 사용자: ").strip()
                
                if not user_input:
                    continue
                
                # 종료 명령
                if user_input.lower() in ['quit', 'exit', '종료']:
                    print("👋 테스트를 종료합니다.")
                    break
                
                # 도움말
                if user_input.lower() in ['help', '도움말']:
                    self._show_help()
                    continue
                
                # 테스트 실행
                response = self.simulate_text_processing(user_input)
                formatted_response = self.format_response(response)
                
                print()
                print(formatted_response)
                print()
                print("-" * 60)
                
            except KeyboardInterrupt:
                print("\n👋 테스트를 종료합니다.")
                break
            except Exception as e:
                print(f"❌ 예상치 못한 오류: {e}")
                print()
    
    def _show_help(self):
        """도움말 표시"""
        print()
        print("📚 테스트 예시:")
        print("=" * 40)
        print("1. 일정 추가:")
        print("   • '내일 오후 3시에 병원 예약이 있어'")
        print("   • '다음 주 월요일 오전 10시에 회의가 있어'")
        print()
        print("2. 일정 조회:")
        print("   • '내일 일정이 뭐야?'")
        print("   • '이번 주 일정 알려줘'")
        print()
        print("3. 일정 삭제:")
        print("   • '병원 예약 취소해줘'")
        print("   • '내일 회의 삭제해줘'")
        print()
        print("4. 일반 대화:")
        print("   • '안녕하세요'")
        print("   • '오늘 날씨 어때?'")
        print("   • '도움말을 알려줘'")
        print()
        print("5. 명확화 요청 테스트:")
        print("   • '일정 추가해줘' (시간 정보 없음)")
        print("   • '회의 취소해줘' (어떤 회의인지 모호함)")
        print("=" * 40)
        print()

def main():
    """메인 함수"""
    try:
        tester = LLMTextTester()
        tester.run_interactive_test()
    except Exception as e:
        print(f"❌ 테스터 실행 오류: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
