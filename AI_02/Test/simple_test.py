#!/usr/bin/env python3
"""
간단한 LLM 기능 테스트
기본적인 텍스트 처리 기능을 테스트합니다.
"""

import sys
import os

# AI_02 모듈 import를 위한 경로 추가
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from Processor.unified_text_pipeline import UnifiedTextPipeline
from Config.settings import Settings
from Services.ScheduleManager import ScheduleManager

def test_basic_functionality():
    """기본 기능 테스트"""
    print("🧪 기본 LLM 기능 테스트 시작...")
    print()
    
    try:
        # 설정 검증
        errors = Settings.validate_settings()
        if errors:
            print("❌ 설정 오류:")
            for error in errors:
                print(f"   - {error}")
            return False
        
        # 스케줄 매니저 초기화
        schedule_manager = ScheduleManager()
        
        # 텍스트 파이프라인 초기화
        pipeline = UnifiedTextPipeline(
            llm_type=Settings.LLM_TYPE
        )
        
        print("✅ 컴포넌트 초기화 완료")
        
        # 테스트 케이스들
        test_cases = [
            "안녕하세요",
            "내일 오후 3시에 병원 예약이 있어",
            "내일 일정이 뭐야?",
            "병원 예약 취소해줘"
        ]
        
        for i, test_text in enumerate(test_cases, 1):
            print(f"\n📝 테스트 {i}: {test_text}")
            print("-" * 50)
            
            try:
                response = pipeline.process_text(test_text, user_id="test_user")
                
                if response.get("success"):
                    print("✅ 성공")
                    print(f"응답: {response.get('response_text', 'N/A')}")
                    print(f"액션: {response.get('processing_result', {}).get('result', {}).get('action', 'N/A')}")
                else:
                    print("❌ 실패")
                    print(f"오류: {response.get('error', 'N/A')}")
                    
            except Exception as e:
                print(f"❌ 예외 발생: {e}")
        
        print("\n🎉 모든 테스트 완료!")
        return True
        
    except Exception as e:
        print(f"❌ 테스트 실행 오류: {e}")
        return False

def test_schedule_operations():
    """일정 관리 기능 테스트"""
    print("\n📅 일정 관리 기능 테스트...")
    print()
    
    try:
        # 스케줄 매니저 초기화
        schedule_manager = ScheduleManager()
        
        # 텍스트 파이프라인 초기화
        pipeline = UnifiedTextPipeline(
            llm_type=Settings.LLM_TYPE
        )
        
        # 일정 추가 테스트
        print("1. 일정 추가 테스트")
        response = pipeline.process_text("내일 오후 2시에 회의가 있어", user_id="test_user")
        if response.get("success"):
            print("✅ 일정 추가 성공")
        else:
            print("❌ 일정 추가 실패")
        
        # 일정 조회 테스트
        print("\n2. 일정 조회 테스트")
        response = pipeline.process_text("내일 일정이 뭐야?", user_id="test_user")
        if response.get("success"):
            print("✅ 일정 조회 성공")
        else:
            print("❌ 일정 조회 실패")
        
        # 일정 삭제 테스트
        print("\n3. 일정 삭제 테스트")
        response = pipeline.process_text("내일 회의 취소해줘", user_id="test_user")
        if response.get("success"):
            print("✅ 일정 삭제 성공")
        else:
            print("❌ 일정 삭제 실패")
        
        print("\n🎉 일정 관리 테스트 완료!")
        return True
        
    except Exception as e:
        print(f"❌ 일정 관리 테스트 오류: {e}")
        return False

def main():
    """메인 함수"""
    print("=" * 60)
    print("🤖 AI_02 LLM 기능 테스트")
    print("=" * 60)
    
    # 기본 기능 테스트
    basic_success = test_basic_functionality()
    
    # 일정 관리 테스트
    schedule_success = test_schedule_operations()
    
    print("\n" + "=" * 60)
    print("📊 테스트 결과 요약:")
    print(f"   기본 기능: {'✅ 성공' if basic_success else '❌ 실패'}")
    print(f"   일정 관리: {'✅ 성공' if schedule_success else '❌ 실패'}")
    
    if basic_success and schedule_success:
        print("\n🎉 모든 테스트가 성공했습니다!")
        print("이제 'python3 Test/llm_text_test.py'로 대화형 테스트를 실행할 수 있습니다.")
    else:
        print("\n⚠️  일부 테스트가 실패했습니다.")
        print("설정을 확인하고 다시 시도해주세요.")
    
    print("=" * 60)

if __name__ == "__main__":
    main()
