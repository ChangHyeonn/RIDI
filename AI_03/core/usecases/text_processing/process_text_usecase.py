#!/usr/bin/env python3
"""
Process Text Use Case
텍스트 처리 Use Case (핵심 비즈니스 로직)
"""

import time
from typing import Dict, Any

from shared.logging.logger import LoggerFactory
from core.entities.text_request import TextRequest, TextProcessingResult, IntentAnalysis
from core.interfaces.services.llm_service import ILLMService
from core.usecases.schedule.add_schedule_usecase import AddScheduleUseCase
from core.usecases.schedule.get_schedule_usecase import GetScheduleUseCase
from core.usecases.schedule.delete_schedule_usecase import DeleteScheduleUseCase


class ProcessTextUseCase:
    """텍스트 처리 Use Case - 메인 엔트리 포인트"""
    
    def __init__(self,
                 llm_service: ILLMService,
                 add_schedule_usecase: AddScheduleUseCase,
                 get_schedule_usecase: GetScheduleUseCase,
                 delete_schedule_usecase: DeleteScheduleUseCase):
        self.llm_service = llm_service
        self.add_schedule_usecase = add_schedule_usecase
        self.get_schedule_usecase = get_schedule_usecase
        self.delete_schedule_usecase = delete_schedule_usecase
        self.logger = LoggerFactory.get_logger(__name__)
    
    def execute(self, request: TextRequest) -> TextProcessingResult:
        """텍스트 요청 처리 (AI_02 호환 방식)"""
        start_time = time.time()
        
        try:
            # 1. 입력 검증
            if not request.is_valid():
                return self._create_error_result(
                    "유효하지 않은 요청입니다.", 
                    time.time() - start_time
                )
            
            # 2. 의도 분석
            intent = self.llm_service.analyze_intent(request.text)
            
            # AI_02 스타일 로그: Intent Classification
            self.logger.info(f"Intent classified: {request.text} -> {intent.category}")
            self.logger.info(f"Intent analyzed: {intent.category} (confidence: {intent.confidence})")
            
            # 3. 일정 관련 요청의 경우 정보 추출
            if intent.category == "schedule_add":
                schedule_info = self.llm_service.extract_schedule_info(request.text)
                
                # AI_02 스타일 로그: Information Extraction
                self.logger.info(f"Information extracted: {schedule_info}")
                
                # 엄격한 일정 정보 검증
                validation_result = self._validate_schedule_info(schedule_info)
                if validation_result['valid']:
                    # AI_02 스타일 로그: Request Analysis
                    self.logger.info(f"Request analyzed: {request.text} -> {intent.category}")
                    return self._handle_schedule_add_with_info(request, schedule_info, start_time)
                else:
                    return self._create_error_result(
                        validation_result['error_message'], 
                        time.time() - start_time
                    )
            elif intent.category == "schedule_read":
                # AI_02 스타일 로그: Request Analysis
                self.logger.info(f"Request analyzed: {request.text} -> {intent.category}")
                return self._handle_schedule_read(request, intent, start_time)
            elif intent.category == "schedule_delete":
                # AI_02 스타일 로그: Request Analysis
                self.logger.info(f"Request analyzed: {request.text} -> {intent.category}")
                return self._handle_schedule_delete(request, intent, start_time)
            else:
                # AI_02 스타일 로그: Request Analysis
                self.logger.info(f"Request analyzed: {request.text} -> {intent.category}")
                return self._handle_general_conversation(request, intent, start_time)
                
        except Exception as e:
            self.logger.error(f"Text processing failed: {e}")
            return self._create_error_result(
                f"처리 중 오류가 발생했습니다: {str(e)}", 
                time.time() - start_time
            )
    
    def _handle_schedule_add_with_info(self, request: TextRequest, schedule_info: dict, start_time: float) -> TextProcessingResult:
        """일정 추가 처리 (정보 추출 완료)"""
        try:
            result = self.add_schedule_usecase.execute(request.user_id, schedule_info)
            
            if result.success:
                response_text = self._generate_add_response(result.schedule_data)
                return TextProcessingResult(
                    success=True,
                    action_type="schedule_add",
                    action_data={"schedule_data": result.schedule_data},
                    response_text=response_text,
                    processing_time=time.time() - start_time
                )
            else:
                return self._create_error_result(result.error_message, time.time() - start_time)
                
        except Exception as e:
            self.logger.error(f"Schedule add failed: {e}")
            return self._create_error_result(
                "일정 추가 중 오류가 발생했습니다.", 
                time.time() - start_time
            )
    
    def _handle_schedule_add(self, request: TextRequest, intent: IntentAnalysis, start_time: float) -> TextProcessingResult:
        """일정 추가 처리"""
        try:
            result = self.add_schedule_usecase.execute(request.user_id, intent.extracted_info)
            
            if result.success:
                response_text = self._generate_add_response(result.schedule_data)
                return TextProcessingResult(
                    success=True,
                    action_type="schedule_add",
                    action_data={"schedule_data": result.schedule_data},
                    response_text=response_text,
                    processing_time=time.time() - start_time
                )
            else:
                return self._create_error_result(result.error_message, time.time() - start_time)
                
        except Exception as e:
            self.logger.error(f"Schedule add failed: {e}")
            return self._create_error_result(
                "일정 추가 중 오류가 발생했습니다.", 
                time.time() - start_time
            )
    
    def _handle_schedule_read(self, request: TextRequest, intent: IntentAnalysis, start_time: float) -> TextProcessingResult:
        """일정 조회 처리"""
        try:
            result = self.get_schedule_usecase.execute(request.user_id, intent.extracted_info)
            
            response_text = self._generate_read_response(result.schedules)
            return TextProcessingResult(
                success=True,
                action_type="schedule_read",
                action_data={"schedules": [s.to_dict() for s in result.schedules]},
                response_text=response_text,
                processing_time=time.time() - start_time
            )
            
        except Exception as e:
            self.logger.error(f"Schedule read failed: {e}")
            return self._create_error_result(
                "일정 조회 중 오류가 발생했습니다.", 
                time.time() - start_time
            )
    
    def _handle_schedule_delete(self, request: TextRequest, intent: IntentAnalysis, start_time: float) -> TextProcessingResult:
        """일정 삭제 처리"""
        try:
            result = self.delete_schedule_usecase.execute(request.user_id, intent.extracted_info)
            
            if result.success:
                response_text = f"{result.deleted_title} 일정을 삭제했습니다."
                return TextProcessingResult(
                    success=True,
                    action_type="schedule_delete",
                    action_data={"deleted_schedule": result.deleted_title},
                    response_text=response_text,
                    processing_time=time.time() - start_time
                )
            else:
                return self._create_error_result(result.error_message, time.time() - start_time)
                
        except Exception as e:
            self.logger.error(f"Schedule delete failed: {e}")
            return self._create_error_result(
                "일정 삭제 중 오류가 발생했습니다.", 
                time.time() - start_time
            )
    
    def _handle_general_conversation(self, request: TextRequest, intent: IntentAnalysis, start_time: float) -> TextProcessingResult:
        """일반 대화 처리"""
        try:
            response = self.llm_service.generate_response(
                f"사용자 질문: {request.text}\n한국어로 친근하게 답변해주세요."
            )
            
            return TextProcessingResult(
                success=True,
                action_type="general_response",
                action_data={"message": response},
                response_text=response,
                processing_time=time.time() - start_time
            )
            
        except Exception as e:
            self.logger.error(f"General conversation failed: {e}")
            return self._create_error_result(
                "응답 생성 중 오류가 발생했습니다.", 
                time.time() - start_time
            )
    
    def _generate_add_response(self, schedule_data: Dict[str, Any]) -> str:
        """일정 추가 응답 메시지 생성"""
        try:
            title = schedule_data.get('title', '일정')
            datetime_str = schedule_data.get('datetime', '')
            
            if datetime_str:
                # YYYY-MM-DD HH:MM 형식 파싱
                from datetime import datetime
                dt = datetime.fromisoformat(datetime_str.replace('T', ' ')[:16])
                month = dt.month
                day = dt.day
                hour = dt.hour
                minute = dt.minute
                
                if minute == 0:
                    return f"{month}월 {day}일 {hour}시에 {title} 일정을 추가하였습니다."
                else:
                    return f"{month}월 {day}일 {hour}시 {minute}분에 {title} 일정을 추가하였습니다."
            else:
                return f"{title} 일정을 추가하였습니다."
                
        except Exception:
            return "일정이 성공적으로 추가되었습니다."
    
    def _generate_read_response(self, schedules: list) -> str:
        """일정 조회 응답 메시지 생성"""
        if not schedules:
            return "등록된 일정이 없습니다."
        
        count = len(schedules)
        return f"{count}개의 일정을 찾았습니다."
    
    def _validate_schedule_info(self, schedule_info: Dict[str, Any]) -> Dict[str, Any]:
        """일정 정보 엄격 검증"""
        
        # 1. 기본 정보 존재 확인
        title = schedule_info.get('title', '').strip()
        date = schedule_info.get('date', '').strip()
        time = schedule_info.get('time', '').strip()
        
        # 2. 비구체적 제목 차단
        generic_titles = ['일정', '예약', '할 일', '미팅', '약속', '행사']
        
        if not title:
            return {
                'valid': False,
                'error_message': '구체적인 일정 내용을 말씀해주세요. 예: "병원 진료", "친구 만남", "회사 회의" 등'
            }
        
        if title.lower() in [t.lower() for t in generic_titles]:
            return {
                'valid': False,
                'error_message': f'"일정" 대신 구체적인 내용을 말씀해주세요. 예: "병원 진료", "친구 만남" 등'
            }
        
        # 3. 제목 길이 및 의미 검증
        if len(title) < 2:
            return {
                'valid': False,
                'error_message': '일정 제목이 너무 짧습니다. 좀 더 구체적으로 설명해주세요.'
            }
        
        # 4. 날짜 및 시간 검증
        if not date:
            return {
                'valid': False,
                'error_message': '일정 날짜를 명확히 말씀해주세요. 예: "내일", "모레", "월요일" 등'
            }
        
        if not time:
            return {
                'valid': False,
                'error_message': '일정 시간을 명확히 말씀해주세요. 예: "오전 9시", "오후 3시 30분" 등'
            }
        
        # 5. 날짜 형식 검증
        try:
            from datetime import datetime
            datetime.strptime(date, '%Y-%m-%d')
        except ValueError:
            return {
                'valid': False,
                'error_message': '잘못된 날짜 형식입니다. 날짜를 다시 명확히 말씀해주세요.'
            }
        
        # 6. 시간 형식 검증
        try:
            hour, minute = time.split(':')
            hour_int = int(hour)
            minute_int = int(minute)
            if not (0 <= hour_int <= 23 and 0 <= minute_int <= 59):
                raise ValueError()
        except (ValueError, AttributeError):
            return {
                'valid': False,
                'error_message': '잘못된 시간 형식입니다. 시간을 다시 명확히 말씀해주세요.'
            }
        
        return {'valid': True}
    
    def _create_error_result(self, error_message: str, processing_time: float) -> TextProcessingResult:
        """에러 결과 생성"""
        return TextProcessingResult(
            success=False,
            action_type="error",
            action_data={},
            response_text=error_message,
            processing_time=processing_time,
            error_message=error_message
        )
