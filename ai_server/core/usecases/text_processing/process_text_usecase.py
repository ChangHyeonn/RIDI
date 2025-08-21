#!/usr/bin/env python3
"""
Process Text Use Case
텍스트 처리 Use Case (핵심 비즈니스 로직)
"""

import time
from typing import Dict, Any

from shared.logging.logger import LoggerFactory
from shared.constants.error_types import ErrorTypes
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
                    time.time() - start_time,
                    ErrorTypes.INVALID_REQUEST
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
                        time.time() - start_time,
                        validation_result.get('error_type', ErrorTypes.SCHEDULE_VALIDATION_ERROR)
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
                time.time() - start_time,
                ErrorTypes.SYSTEM_ERROR
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
                return self._create_error_result(
                    result.error_message, 
                    time.time() - start_time,
                    ErrorTypes.SCHEDULE_SAVE_ERROR
                )
                
        except Exception as e:
            self.logger.error(f"Schedule add failed: {e}")
            return self._create_error_result(
                "일정 추가 중 오류가 발생했습니다.", 
                time.time() - start_time,
                ErrorTypes.AI_PROCESSING_ERROR
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
                time.time() - start_time,
                ErrorTypes.AI_PROCESSING_ERROR
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
                time.time() - start_time,
                ErrorTypes.AI_PROCESSING_ERROR
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
                time.time() - start_time,
                ErrorTypes.RESPONSE_GENERATION_ERROR
            )
    
    def _generate_add_response(self, schedule_data: Dict[str, Any]) -> str:
        """일정 추가 응답 메시지 생성 (반복 일정 지원)"""
        try:
            title = schedule_data.get('title', '일정')
            datetime_str = schedule_data.get('datetime', '')
            is_recurring = schedule_data.get('is_recurring', False)
            recurrence = schedule_data.get('recurrence', {})
            
            if is_recurring and recurrence:
                # 반복 일정 응답 생성
                return self._generate_recurring_response(title, datetime_str, recurrence)
            else:
                # 일반 일정 응답 생성 (기존 로직)
                if datetime_str:
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
    
    def _generate_recurring_response(self, title: str, datetime_str: str, recurrence: Dict[str, Any]) -> str:
        """반복 일정 응답 메시지 생성"""
        try:
            recurrence_type = recurrence.get('type', 'daily')
            times = recurrence.get('times', [])
            end_date = recurrence.get('end_date')
            days_of_week = recurrence.get('days_of_week', [])
            
            # 반복 주기 설명
            type_desc = {
                'daily': '매일',
                'weekdays': '평일마다',
                'weekends': '주말마다',
                'custom_days': self._get_custom_days_description(days_of_week)
            }.get(recurrence_type, '반복으로')
            
            # 시간 설명
            times_desc = ""
            if len(times) == 1:
                time_str = times[0].get('time', '').split(':')
                if len(time_str) == 2:
                    hour = int(time_str[0])
                    minute = int(time_str[1])
                    if minute == 0:
                        times_desc = f"{hour}시"
                    else:
                        times_desc = f"{hour}시 {minute}분"
            elif len(times) > 1:
                time_labels = []
                for time_info in times:
                    time_str = time_info.get('time', '').split(':')
                    label = time_info.get('label', '')
                    if len(time_str) == 2:
                        hour = int(time_str[0])
                        minute = int(time_str[1])
                        if label:
                            time_labels.append(f"{label} {hour}시")
                        else:
                            if minute == 0:
                                time_labels.append(f"{hour}시")
                            else:
                                time_labels.append(f"{hour}시 {minute}분")
                
                if len(time_labels) == 2:
                    times_desc = f"{time_labels[0]}와 {time_labels[1]}"
                else:
                    times_desc = ", ".join(time_labels[:-1]) + f"와 {time_labels[-1]}"
            
            # 종료 조건 설명
            end_desc = ""
            if end_date:
                try:
                    from datetime import datetime
                    end_dt = datetime.strptime(end_date, '%Y-%m-%d')
                    end_month = end_dt.month
                    end_year = end_dt.year
                    if end_year != datetime.now().year:
                        end_desc = f"{end_year}년 {end_month}월까지 "
                    else:
                        end_desc = f"{end_month}월까지 "
                except:
                    end_desc = f"{end_date}까지 "
            
            # 최종 메시지 조합
            if times_desc:
                return f"{end_desc}{type_desc} {times_desc}에 {title} 일정을 추가하였습니다."
            else:
                return f"{end_desc}{type_desc} {title} 일정을 추가하였습니다."
                
        except Exception:
            return f"{title} 반복 일정이 성공적으로 추가되었습니다."
    
    def _get_custom_days_description(self, days_of_week: list) -> str:
        """요일 목록을 한국어로 변환"""
        if not days_of_week:
            return "특정 요일마다"
        
        day_names = ['월', '화', '수', '목', '금', '토', '일']
        try:
            selected_days = [day_names[day] for day in days_of_week if 0 <= day <= 6]
            if len(selected_days) == 1:
                return f"{selected_days[0]}요일마다"
            elif len(selected_days) == 2:
                return f"{selected_days[0]}, {selected_days[1]}요일마다"
            else:
                return ", ".join(selected_days[:-1]) + f", {selected_days[-1]}요일마다"
        except:
            return "특정 요일마다"
    
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
        
        # 2. 제목 개선 로직: "일정을 추가해 줘" 같은 문구에서 실제 일정 내용 추출
        improved_title = self._extract_actual_schedule_title(title)
        if improved_title and improved_title != title:
            # 개선된 제목이 있으면 schedule_info 업데이트
            schedule_info['title'] = improved_title
            title = improved_title
        
        # 3. 비구체적 제목 차단
        generic_titles = ['일정', '예약', '할 일', '미팅', '약속', '행사']
        
        if not title:
            return {
                'valid': False,
                'error_message': '구체적인 일정 내용을 말씀해주세요. 예: "병원 진료", "친구 만남", "회사 회의" 등',
                'error_type': ErrorTypes.MISSING_SCHEDULE_TITLE
            }
        
        if title.lower() in [t.lower() for t in generic_titles]:
            return {
                'valid': False,
                'error_message': f'"일정" 대신 구체적인 내용을 말씀해주세요. 예: "병원 진료", "친구 만남" 등',
                'error_type': ErrorTypes.GENERIC_SCHEDULE_TITLE
            }
        
        # 4. 제목 길이 및 의미 검증
        if len(title) < 2:
            return {
                'valid': False,
                'error_message': '일정 제목이 너무 짧습니다. 좀 더 구체적으로 설명해주세요.',
                'error_type': ErrorTypes.SHORT_SCHEDULE_TITLE
            }
        
        # 4. 날짜 및 시간 검증
        if not date:
            return {
                'valid': False,
                'error_message': '일정 날짜를 명확히 말씀해주세요. 예: "내일", "모레", "월요일" 등',
                'error_type': ErrorTypes.MISSING_SCHEDULE_DATE
            }
        
        if not time:
            return {
                'valid': False,
                'error_message': '일정 시간을 명확히 말씀해주세요. 예: "오전 9시", "오후 3시 30분" 등',
                'error_type': ErrorTypes.MISSING_SCHEDULE_TIME
            }
        
        # 5. 날짜 형식 검증
        try:
            from datetime import datetime
            datetime.strptime(date, '%Y-%m-%d')
        except ValueError:
            return {
                'valid': False,
                'error_message': '잘못된 날짜 형식입니다. 날짜를 다시 명확히 말씀해주세요.',
                'error_type': ErrorTypes.INVALID_DATE_FORMAT
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
                'error_message': '잘못된 시간 형식입니다. 시간을 다시 명확히 말씀해주세요.',
                'error_type': ErrorTypes.INVALID_TIME_FORMAT
            }
        
        return {'valid': True}
    
    def _extract_actual_schedule_title(self, title: str) -> str:
        """실제 일정 제목 추출 (generic 제목 개선)"""
        if not title:
            return title
        
        # "일정을 추가해 줘" 같은 문구에서 실제 일정 내용 추출
        title_lower = title.lower()
        
        # 제거할 문구들
        remove_phrases = [
            '일정을 추가해 줘', '일정 추가해 줘', '일정 추가해주세요', '일정을 추가해주세요',
            '일정을 넣어 줘', '일정 넣어 줘', '일정 넣어주세요', '일정을 넣어주세요',
            '일정을 등록해 줘', '일정 등록해 줘', '일정 등록해주세요', '일정을 등록해주세요',
            '일정을 만들어 줘', '일정 만들어 줘', '일정 만들어주세요', '일정을 만들어주세요',
            '일정을 잡아 줘', '일정 잡아 줘', '일정 잡아주세요', '일정을 잡아주세요',
            '일정을 예약해 줘', '일정 예약해 줘', '일정 예약해주세요', '일정을 예약해주세요'
        ]
        
        # 제거할 문구들을 제거
        cleaned_title = title
        for phrase in remove_phrases:
            if phrase in title_lower:
                cleaned_title = title.replace(phrase, '').replace(phrase.replace('줘', '주세요'), '')
                break
        
        # 앞뒤 공백 제거
        cleaned_title = cleaned_title.strip()
        
        # 만약 제거 후 빈 문자열이 되면 원본 반환
        if not cleaned_title:
            return title
        
        return cleaned_title
    
    def _create_error_result(self, error_message: str, processing_time: float, error_type: str = ErrorTypes.SYSTEM_ERROR) -> TextProcessingResult:
        """에러 결과 생성"""
        return TextProcessingResult(
            success=False,
            action_type="error",
            action_data={"error_type": error_type},
            response_text=error_message,
            processing_time=processing_time,
            error_message=error_message
        )
