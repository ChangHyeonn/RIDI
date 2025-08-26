#!/usr/bin/env python3
"""
Process Text Use Case
텍스트 처리 Use Case (핵심 비즈니스 로직)
"""

import time
import re
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
        
        # 간단한 메모리 기반 세션 저장소 (실제로는 Redis나 DB 사용 권장)
        self._user_sessions = {}
    
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
            
            # 의도 분류 후처리 (LLM 분류 결과 보정)
            corrected_intent = self._correct_intent_classification(request.text, intent)
            if corrected_intent.category != intent.category:
                self.logger.info(f"Intent corrected: {intent.category} -> {corrected_intent.category}")
                intent = corrected_intent
            
            # AI_02 스타일 로그: Intent Classification
            self.logger.info(f"Intent classified: {request.text} -> {intent.category}")
            self.logger.info(f"Intent analyzed: {intent.category} (confidence: {intent.confidence})")
            
            # 2.5. 일정 선택 응답 감지 (스펙트럼 삭제 후 사용자 선택)
            if self._is_schedule_selection_response(request.text):
                return self._handle_schedule_selection_response(request, start_time)
            
            # 3. 일정 관련 요청의 경우 정보 추출
            if intent.category == "schedule_add":
                # 시간 정보만 제공하는 경우 세션에서 이전 정보 가져오기
                if self._is_time_only_response(request.text):
                    self.logger.info(f"Time-only response detected: {request.text}")
                    pending_schedule = self._get_pending_schedule(request.user_id)
                    self.logger.info(f"Pending schedule for user {request.user_id}: {pending_schedule}")
                    if pending_schedule:
                        # 이전 일정 정보에 시간 정보 추가 (AI 추출 건너뛰기)
                        schedule_info = self._merge_time_with_pending_schedule(request.text, pending_schedule)
                        self.logger.info(f"Merged schedule info: {schedule_info}")
                    else:
                        # 세션에 이전 정보가 없으면 AI 추출
                        schedule_info = self.llm_service.extract_schedule_info(request.text)
                        self.logger.info(f"No pending schedule, using AI extraction: {schedule_info}")
                else:
                    # 일반적인 일정 추가 요청
                    schedule_info = self.llm_service.extract_schedule_info(request.text)
                
                # AI_02 스타일 로그: Information Extraction
                self.logger.info(f"Information extracted: {schedule_info}")
                
                # 엄격한 일정 정보 검증
                validation_result = self._validate_schedule_info(schedule_info, request)
                if validation_result['valid']:
                    # AI_02 스타일 로그: Request Analysis
                    self.logger.info(f"Request analyzed: {request.text} -> {intent.category}")
                    # 성공 시 세션 정리
                    self._clear_pending_schedule(request.user_id)
                    return self._handle_schedule_add_with_info(request, schedule_info, start_time)
                else:
                    # 시간 누락된 경우 세션에 저장
                    error_type = validation_result.get('error_type')
                    if error_type in [ErrorTypes.SCHEDULE_VALIDATION_ERROR, ErrorTypes.MISSING_SCHEDULE_TIME, ErrorTypes.MISSING_SCHEDULE_TITLE, ErrorTypes.MISSING_SCHEDULE_DATE]:
                        self.logger.info(f"Saving pending schedule for error type: {error_type}")
                        self._save_pending_schedule(request.user_id, schedule_info)
                    
                    return self._create_error_result(
                        validation_result['error_message'], 
                        time.time() - start_time,
                        validation_result.get('error_type', ErrorTypes.SCHEDULE_VALIDATION_ERROR)
                    )
            elif intent.category == "schedule_read":
                # 일정 조회 정보 추출
                schedule_info = self.llm_service.extract_schedule_info(request.text)
                
                # AI_02 스타일 로그: Information Extraction
                self.logger.info(f"Information extracted: {schedule_info}")
                
                # intent.extracted_info 업데이트
                intent.extracted_info = schedule_info
                
                # AI_02 스타일 로그: Request Analysis
                self.logger.info(f"Request analyzed: {request.text} -> {intent.category}")
                return self._handle_schedule_read(request, intent, start_time)
            elif intent.category == "schedule_delete":
                # 일정 정보 추출
                schedule_info = self.llm_service.extract_schedule_info(request.text)
                
                # AI_02 스타일 로그: Information Extraction
                self.logger.info(f"Information extracted: {schedule_info}")
                
                # AI_02 스타일 로그: Request Analysis
                self.logger.info(f"Request analyzed: {request.text} -> {intent.category}")
                return self._handle_schedule_delete(request, schedule_info, start_time)
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
        """일정 조회 처리 (시각적 인터페이스 방식)"""
        try:
            # 1. 일정 조회 실행
            result = self.get_schedule_usecase.execute(request.user_id, intent.extracted_info)
            
            # 2. 조회된 일정이 있는 경우 시각적 인터페이스로 표시
            if result.schedules:
                # 검색 기준 추출
                search_info = intent.extracted_info
                title = (search_info.get('title') or '').strip()
                date_str = (search_info.get('date') or '').strip()
                keyword = (search_info.get('keyword') or '').strip()
                
                # 시각적 조회 인터페이스 응답 생성
                if title:
                    search_criteria = title
                elif date_str:
                    search_criteria = date_str
                elif keyword:
                    search_criteria = keyword
                else:
                    search_criteria = '검색 조건'
                
                response_text = f"'{search_criteria}'과 관련된 일정 {len(result.schedules)}개를 찾았습니다."
                
                return TextProcessingResult(
                    success=True,
                    action_type="schedule_read_visual",
                    action_data={
                        "search_criteria": {
                            "title": title,
                            "date": date_str,
                            "keyword": keyword
                        },
                        "found_schedules": [s.to_dict() for s in result.schedules],
                        "total_count": len(result.schedules),
                        "show_read_interface": True
                    },
                    response_text=response_text,
                    processing_time=time.time() - start_time
                )
            else:
                # 조회된 일정이 없는 경우 기존 방식으로 처리
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
    
    def _handle_schedule_delete(self, request: TextRequest, schedule_info: dict, start_time: float) -> TextProcessingResult:
        """일정 삭제 처리 (새로운 시각적 인터페이스 방식)"""
        try:
            title = (schedule_info.get('title') or '').strip()
            date_str = (schedule_info.get('date') or '').strip()
            
            # 1. 삭제 요청 검증: 제목이나 날짜 중 하나라도 있어야 함
            if not title and not date_str:
                return self._create_error_result(
                    "삭제할 일정의 제목이나 날짜를 알려주세요.", 
                    time.time() - start_time,
                    ErrorTypes.SCHEDULE_VALIDATION_ERROR
                )
            
            # 2. 관련 일정 검색
            result = self.delete_schedule_usecase.execute_search(request.user_id, schedule_info)
            
            if not result.success:
                return self._create_error_result(result.error_message, time.time() - start_time)
            
            # 3. 검색된 일정들을 시각적 인터페이스로 표시
            found_schedules = result.found_schedules
            if not found_schedules:
                return self._create_error_result(
                    "삭제할 일정을 찾을 수 없습니다.", 
                    time.time() - start_time,
                    ErrorTypes.SCHEDULE_NOT_FOUND
                )
            
            # 4. 시각적 삭제 인터페이스 응답 생성
            search_criteria = title if title else date_str
            response_text = f"'{search_criteria}'과 관련된 일정 {len(found_schedules)}개를 찾았습니다. 삭제하고 싶은 일정을 선택해주세요."
            
            return TextProcessingResult(
                success=True,
                action_type="schedule_delete_visual",
                action_data={
                    "search_criteria": {
                        "title": title,
                        "date": date_str
                    },
                    "found_schedules": found_schedules,
                    "total_count": len(found_schedules),
                    "show_delete_interface": True
                },
                response_text=response_text,
                processing_time=time.time() - start_time
            )
                
        except Exception as e:
            self.logger.error(f"Schedule delete failed: {e}")
            return self._create_error_result(
                "일정 삭제 중 오류가 발생했습니다.", 
                time.time() - start_time,
                ErrorTypes.AI_PROCESSING_ERROR
            )
    
    def _handle_schedule_selection(self, request: TextRequest, result, start_time: float) -> TextProcessingResult:
        """일정 선택 UI 처리"""
        try:
            similar_schedules = result.similar_schedules
            
            # 일정 목록 생성
            schedule_list = []
            for i, schedule in enumerate(similar_schedules, 1):
                schedule_info = f"{i}. {schedule['title']}"
                if schedule['datetime']:
                    from datetime import datetime
                    dt = datetime.fromisoformat(schedule['datetime'])
                    schedule_info += f" ({dt.strftime('%m월 %d일 %H시 %M분')})"
                if schedule['is_recurring']:
                    schedule_info += " (반복 일정)"
                schedule_list.append(schedule_info)
            
            schedule_list_text = "\n".join(schedule_list)
            
            # 선택 안내 메시지 생성 (원본 요청에서 제목 추출)
            search_title = request.text.split('삭제')[0].strip() if '삭제' in request.text else '일정'
            response_text = f"'{search_title}'과 관련된 일정이 {len(similar_schedules)}개 있습니다. 삭제하고 싶은 일정을 선택해주세요:\n\n{schedule_list_text}\n\n번호로 선택하거나 '모두'를 말씀하시면 됩니다."
            
            # 세션에 일정 목록 저장
            self._user_sessions[request.user_id] = {
                "similar_schedules": similar_schedules,
                "search_title": search_title,
                "timestamp": time.time()
            }
            
            return TextProcessingResult(
                success=False,
                action_type="schedule_selection",
                action_data={
                    "search_title": search_title,
                    "similar_schedules": similar_schedules,
                    "total_found": len(similar_schedules),
                    "requires_user_selection": True
                },
                response_text=response_text,
                processing_time=time.time() - start_time
            )
            
        except Exception as e:
            self.logger.error(f"Schedule selection failed: {e}")
            return self._create_error_result(
                "일정 선택 처리 중 오류가 발생했습니다.", 
                time.time() - start_time,
                ErrorTypes.AI_PROCESSING_ERROR
            )
    
    def _handle_schedule_selection_response(self, request: TextRequest, start_time: float) -> TextProcessingResult:
        """일정 선택 응답 처리"""
        try:
            # 세션에서 일정 목록 가져오기
            user_session = self._user_sessions.get(request.user_id)
            if not user_session:
                return self._create_error_result(
                    "선택할 일정이 없습니다. 다시 삭제 요청을 해주세요.", 
                    time.time() - start_time,
                    ErrorTypes.SCHEDULE_SELECTION_REQUIRED
                )
            
            # 세션 만료 확인 (5분)
            if time.time() - user_session["timestamp"] > 300:
                del self._user_sessions[request.user_id]
                return self._create_error_result(
                    "선택 시간이 만료되었습니다. 다시 삭제 요청을 해주세요.", 
                    time.time() - start_time,
                    ErrorTypes.SCHEDULE_SELECTION_REQUIRED
                )
            
            similar_schedules = user_session["similar_schedules"]
            search_title = user_session["search_title"]
            
            # 사용자 응답 파싱
            selection_result = self._parse_selection_response(request.text, similar_schedules)
            
            if not selection_result["is_valid"]:
                return self._create_error_result(
                    selection_result["error_message"], 
                    time.time() - start_time,
                    ErrorTypes.INVALID_SELECTION_RESPONSE
                )
            
            # 선택된 일정 삭제
            if selection_result["action"] == "cancel":
                # 세션 정리
                del self._user_sessions[request.user_id]
                return TextProcessingResult(
                    success=True,
                    action_type="schedule_delete_cancelled",
                    action_data={"message": "삭제가 취소되었습니다."},
                    response_text="삭제를 취소했습니다.",
                    processing_time=time.time() - start_time
                )
            
            # 실제 삭제 실행
            selected_schedule_ids = selection_result["selected_schedule_ids"]
            delete_result = self.delete_schedule_usecase.execute_selection(request.user_id, selected_schedule_ids)
            
            if delete_result.success:
                # 세션 정리
                del self._user_sessions[request.user_id]
                
                # 삭제 성공 응답 생성
                deleted_titles = [schedule["title"] for schedule in similar_schedules if schedule["id"] in selected_schedule_ids]
                response_text = self._generate_delete_multiple_response(deleted_titles, len(selected_schedule_ids))
                
                return TextProcessingResult(
                    success=True,
                    action_type="schedule_delete_multiple",
                    action_data={
                        "deleted_schedules": deleted_titles,
                        "deleted_count": len(selected_schedule_ids)
                    },
                    response_text=response_text,
                    processing_time=time.time() - start_time
                )
            else:
                return self._create_error_result(
                    delete_result.error_message, 
                    time.time() - start_time,
                    ErrorTypes.SCHEDULE_DELETE_ERROR
                )
            
        except Exception as e:
            self.logger.error(f"Schedule selection response failed: {e}")
            return self._create_error_result(
                "일정 선택 응답 처리 중 오류가 발생했습니다.", 
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
        """일정 조회 응답 메시지 생성 (상세 정보 포함)"""
        if not schedules:
            return "등록된 일정이 없습니다."
        
        count = len(schedules)
        
        # 일정이 1개인 경우
        if count == 1:
            schedule = schedules[0]
            title = schedule.title
            start_time = schedule.start_datetime
            
            # 시간 정보 포함
            if start_time:
                month = start_time.month
                day = start_time.day
                hour = start_time.hour
                minute = start_time.minute
                
                if minute == 0:
                    return f"{month}월 {day}일 {hour}시에 {title} 일정이 있습니다."
                else:
                    return f"{month}월 {day}일 {hour}시 {minute}분에 {title} 일정이 있습니다."
            else:
                return f"{title} 일정이 있습니다."
        
        # 일정이 여러 개인 경우
        elif count <= 3:
            # 상위 3개 일정의 제목만 나열
            titles = []
            for i, schedule in enumerate(schedules[:3]):
                title = schedule.title
                start_time = schedule.start_datetime
                
                if start_time:
                    month = start_time.month
                    day = start_time.day
                    titles.append(f"{month}월 {day}일 {title}")
                else:
                    titles.append(title)
            
            if len(titles) == 1:
                return f"{count}개의 일정이 있습니다. {titles[0]}입니다."
            elif len(titles) == 2:
                return f"{count}개의 일정이 있습니다. {titles[0]}와 {titles[1]}입니다."
            else:
                return f"{count}개의 일정이 있습니다. {titles[0]}, {titles[1]}, {titles[2]}입니다."
        
        # 일정이 4개 이상인 경우
        else:
            # 첫 번째 일정만 상세히, 나머지는 개수로
            first_schedule = schedules[0]
            title = first_schedule.title
            start_time = first_schedule.start_datetime
            
            if start_time:
                month = start_time.month
                day = start_time.day
                return f"{count}개의 일정이 있습니다. {month}월 {day}일 {title} 외 {count-1}개 일정이 있습니다."
            else:
                return f"{count}개의 일정이 있습니다. {title} 외 {count-1}개 일정이 있습니다."
    
    def _validate_schedule_info(self, schedule_info: Dict[str, Any], request: TextRequest = None) -> Dict[str, Any]:
        """일정 정보 엄격 검증"""
        
        # 1. 기본 정보 존재 확인 (None 값 안전 처리)
        title = (schedule_info.get('title') or '').strip()
        date = (schedule_info.get('date') or '').strip()
        time = (schedule_info.get('time') or '').strip()
        
        # 2. 제목 개선 로직: "일정을 추가해 줘" 같은 문구에서 실제 일정 내용 추출
        improved_title = self._extract_actual_schedule_title(title)
        if improved_title and improved_title != title:
            # 개선된 제목이 있으면 schedule_info 업데이트
            schedule_info['title'] = improved_title
            title = improved_title
        
        # 3. 반복 일정 자동 감지: "~마다" 표현이 있지만 반복 설정이 없는 경우
        is_recurring = schedule_info.get('is_recurring', False)
        recurrence = schedule_info.get('recurrence', {})
        
        # recurrence가 None인 경우 빈 딕셔너리로 처리
        if recurrence is None:
            recurrence = {}
            schedule_info['recurrence'] = recurrence
        
        if not is_recurring and request and self._has_recurrence_indicators(request.text) and not recurrence:
            self.logger.info("반복 일정 자동 감지: ~마다 표현 발견")
            is_recurring = True
            schedule_info['is_recurring'] = True
            
            # 기본 반복 패턴 설정 (매일)
            if 'recurrence' not in schedule_info:
                schedule_info['recurrence'] = {}
            
            # 시간 정보가 있는 경우 해당 시간 사용, 없으면 기본값
            current_time = time or '00:00'
            current_label = '기본'
            
            # 기존 시간 정보가 있으면 활용
            if time:
                # 시간에 따른 라벨 자동 설정
                try:
                    hour = int(time.split(':')[0])
                    if 5 <= hour < 12:
                        current_label = '아침'
                    elif 12 <= hour < 18:
                        current_label = '오후'
                    else:
                        current_label = '저녁'
                except (ValueError, IndexError):
                    current_label = '기본'
            
            schedule_info['recurrence']['type'] = 'daily'
            schedule_info['recurrence']['times'] = [{
                'time': current_time,
                'label': current_label
            }]
            schedule_info['recurrence']['end_date'] = None
            schedule_info['recurrence']['days_of_week'] = None
            
            recurrence = schedule_info['recurrence']
        
        # 3.5. 평일/주말 표현 파싱 및 days_of_week 설정
        if is_recurring and recurrence and request:
            self._parse_weekday_expressions(request.text, recurrence)
        
        # 3. 반복 일정 시작일 자동 설정
        if is_recurring and not date:
            from datetime import datetime
            today = datetime.now().strftime('%Y-%m-%d')
            schedule_info['date'] = today
            date = today
            self.logger.info(f"반복 일정 시작일을 오늘({today})로 설정")
        
        # 4. 누락된 정보에 따른 구체적인 안내 메시지 생성
        missing_info = []
        
        # 일정 내용 검증
        if not title or title.lower() in ['일정', '예약', '할 일', '미팅', '약속', '행사']:
            missing_info.append('일정 내용')
        
        # 날짜 검증 (반복 일정이 아닌 경우에만)
        if not date and not is_recurring:
            missing_info.append('일자')
        
        # 시간 검증
        if not time:
            missing_info.append('시간')
        
        # 누락된 정보가 있으면 구체적인 안내 메시지 반환
        if missing_info:
            if len(missing_info) == 1:
                if missing_info[0] == '일정 내용':
                    error_message = '상세한 일정을 말씀해 주시겠어요?'
                    error_type = ErrorTypes.MISSING_SCHEDULE_TITLE
                elif missing_info[0] == '일자':
                    error_message = '상세한 일자를 말씀해 주시겠어요?'
                    error_type = ErrorTypes.MISSING_SCHEDULE_DATE
                elif missing_info[0] == '시간':
                    error_message = '상세한 시간을 말씀해 주시겠어요?'
                    error_type = ErrorTypes.MISSING_SCHEDULE_TIME
            else:
                # 여러 정보가 누락된 경우
                missing_str = ', '.join(missing_info[:-1]) + f'와 {missing_info[-1]}'
                error_message = f'상세한 {missing_str}을 말씀해 주시겠어요?'
                error_type = ErrorTypes.MISSING_SCHEDULE_TITLE
            
            return {
                'valid': False,
                'error_message': error_message,
                'error_type': error_type
            }
        
        # 4. 날짜 형식 검증 (반복 일정이 아닌 경우에만)
        if date and not is_recurring:
            try:
                from datetime import datetime
                datetime.strptime(date, '%Y-%m-%d')
            except ValueError:
                return {
                    'valid': False,
                    'error_message': '상세한 일자를 말씀해 주시겠어요?',
                    'error_type': ErrorTypes.INVALID_DATE_FORMAT
                }
        
        # 5. 시간 형식 검증
        try:
            hour, minute = time.split(':')
            hour_int = int(hour)
            minute_int = int(minute)
            if not (0 <= hour_int <= 23 and 0 <= minute_int <= 59):
                raise ValueError()
        except (ValueError, AttributeError):
            return {
                'valid': False,
                'error_message': '상세한 시간을 말씀해 주시겠어요?',
                'error_type': ErrorTypes.INVALID_TIME_FORMAT
            }
        
        return {'valid': True}

    def _has_recurrence_indicators(self, text: str) -> bool:
        """반복 일정 감지 지표 확인"""
        if not text:
            return False
        
        import re
        
        # 반복 일정 감지 패턴들 (더 정확한 매칭을 위해 단어 경계 사용)
        recurrence_patterns = [
            r'\b마다\b',           # "7시마다", "아침마다" (단어 경계)
            r'\b매일\b',           # "매일" (단어 경계)
            r'\b매주\b',           # "매주" (단어 경계)
            r'\b매월\b',           # "매월" (단어 경계)
            r'\b정기\b',           # "정기적으로" (단어 경계)
            r'\b반복\b',           # "반복" (단어 경계)
            r'\b계속\b',           # "계속" (단어 경계)
            r'\b늘\b',             # "늘" (단어 경계)
            r'\b항상\b',           # "항상" (단어 경계)
        ]
        
        for pattern in recurrence_patterns:
            if re.search(pattern, text):
                return True
        
        return False

    def _parse_weekday_expressions(self, text: str, recurrence: Dict[str, Any]) -> None:
        """평일/주말 표현 파싱 및 days_of_week 설정"""
        if not text or not recurrence:
            return
        
        import re
        
        # 평일/주말 표현 패턴 (더 포괄적인 패턴 추가)
        weekday_patterns = [
            (r'\b평일\b', 'weekdays', [0, 1, 2, 3, 4]),  # 월~금
            (r'\b주말\b', 'weekends', [5, 6]),            # 토, 일
            (r'\b월\s*~\s*금\b', 'weekdays', [0, 1, 2, 3, 4]),  # 월~금
            (r'\b토\s*,\s*일\b', 'weekends', [5, 6]),    # 토, 일
            (r'\b토\s*일\b', 'weekends', [5, 6]),        # 토일
            (r'\b평일마다\b', 'weekdays', [0, 1, 2, 3, 4]),  # 평일마다
            (r'\b주말마다\b', 'weekends', [5, 6]),        # 주말마다
            (r'\b평일에\b', 'weekdays', [0, 1, 2, 3, 4]),  # 평일에
            (r'\b주말에\b', 'weekends', [5, 6]),          # 주말에
        ]
        
        for pattern, recurrence_type, days in weekday_patterns:
            if re.search(pattern, text):
                self.logger.info(f"평일/주말 표현 감지: {pattern} -> {recurrence_type}, days: {days}")
                recurrence['type'] = recurrence_type
                recurrence['days_of_week'] = days
                return
        
        # 디버깅: 어떤 패턴도 매칭되지 않은 경우
        self.logger.info(f"평일/주말 표현 감지 실패: '{text}'")
    
    def _generate_delete_multiple_response(self, deleted_titles: list, deleted_count: int) -> str:
        """다중 삭제 응답 메시지 생성"""
        if not deleted_titles:
            return "일정이 삭제되었습니다."
        
        if deleted_count == 1:
            return f"{deleted_titles[0]} 일정을 삭제했습니다."
        elif deleted_count == 2:
            return f"{deleted_titles[0]}와 {deleted_titles[1]} 일정을 삭제했습니다."
        else:
            # 3개 이상인 경우
            titles_str = ", ".join(deleted_titles[:-1]) + f"와 {deleted_titles[-1]}"
            return f"{titles_str} 일정을 삭제했습니다."
    
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
    
    def _is_schedule_selection_response(self, text: str) -> bool:
        """일정 선택 응답인지 감지"""
        if not text:
            return False
        
        text = text.strip()
        
        # 선택 응답 패턴들 (더 포괄적인 패턴)
        selection_patterns = [
            r'^\d+번$',  # "1번", "2번" 등
            r'^\d+번,\s*\d+번$',  # "1번, 2번" 등
            r'^\d+번\s*,\s*\d+번$',  # "1번 , 2번" 등
            r'^모두$',  # "모두"
            r'^전부$',  # "전부"
            r'^다$',  # "다"
            r'^취소$',  # "취소"
            r'^안할래요$',  # "안할래요"
            r'^그만$',  # "그만"
        ]
        
        # 정확한 매칭 먼저 시도
        import re
        for pattern in selection_patterns:
            if re.match(pattern, text):
                self.logger.info(f"Selection response detected (exact match): '{text}'")
                return True
        
        # 키워드 기반 감지 (더 유연한 매칭)
        selection_keywords = [
            '모두', '전부', '다', '취소', '안할래요', '그만', '안해', '싫어'
        ]
        
        for keyword in selection_keywords:
            if keyword in text:
                # 문맥 확인: 삭제 관련 키워드와 함께 사용되는지
                delete_keywords = ['삭제', '지워', '제거', '취소']
                for delete_keyword in delete_keywords:
                    if delete_keyword in text:
                        self.logger.info(f"Selection response detected (keyword match): '{text}' (keyword: {keyword}, delete: {delete_keyword})")
                        return True
        
        self.logger.info(f"Not a selection response: '{text}'")
        return False
    
    def _parse_selection_response(self, text: str, similar_schedules: list) -> dict:
        """선택 응답 파싱"""
        if not text or not similar_schedules:
            return {
                "is_valid": False,
                "error_message": "잘못된 선택입니다."
            }
        
        text = text.strip()
        
        # 취소 응답 (더 포괄적인 매칭)
        cancel_keywords = ["취소", "안할래요", "그만", "안해", "싫어"]
        for keyword in cancel_keywords:
            if keyword in text:
                return {
                    "is_valid": True,
                    "action": "cancel",
                    "selected_indices": [],
                    "selected_schedule_ids": []
                }
        
        # 모두 삭제 (더 포괄적인 매칭)
        delete_all_keywords = ["모두", "전부", "다"]
        for keyword in delete_all_keywords:
            if keyword in text:
                return {
                    "is_valid": True,
                    "action": "delete_all",
                    "selected_indices": list(range(len(similar_schedules))),
                    "selected_schedule_ids": [schedule["id"] for schedule in similar_schedules]
                }
        
        # 번호 선택 파싱
        import re
        
        # 단일 선택: "1번"
        single_match = re.match(r'^(\d+)번$', text)
        if single_match:
            index = int(single_match.group(1)) - 1  # 0-based index
            if 0 <= index < len(similar_schedules):
                return {
                    "is_valid": True,
                    "action": "delete_multiple",
                    "selected_indices": [index],
                    "selected_schedule_ids": [similar_schedules[index]["id"]]
                }
            else:
                return {
                    "is_valid": False,
                    "error_message": f"1부터 {len(similar_schedules)}까지의 번호를 선택해주세요."
                }
        
        # 다중 선택: "1번, 2번"
        multiple_match = re.match(r'^(\d+)번\s*,\s*(\d+)번$', text)
        if multiple_match:
            index1 = int(multiple_match.group(1)) - 1
            index2 = int(multiple_match.group(2)) - 1
            
            if (0 <= index1 < len(similar_schedules) and 
                0 <= index2 < len(similar_schedules) and 
                index1 != index2):
                return {
                    "is_valid": True,
                    "action": "delete_multiple",
                    "selected_indices": [index1, index2],
                    "selected_schedule_ids": [
                        similar_schedules[index1]["id"],
                        similar_schedules[index2]["id"]
                    ]
                }
            else:
                return {
                    "is_valid": False,
                    "error_message": f"1부터 {len(similar_schedules)}까지의 서로 다른 번호를 선택해주세요."
                }
        
        return {
            "is_valid": False,
            "error_message": "번호로 선택하거나 '모두', '취소'를 말씀해주세요."
        }

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
    
    def _correct_intent_classification(self, text: str, intent: IntentAnalysis) -> IntentAnalysis:
        """의도 분류 결과 보정 (LLM 분류 오류 수정)"""
        try:
            text_lower = text.lower()
            
            # 1. 시간 정보 제공 감지 (연속 대화 맥락)
            time_only_patterns = [
                r"^\s*\d+시\s*$",  # "5시", "3시"
                r"^\s*오후\s*\d+시\s*$",  # "오후 5시"
                r"^\s*오전\s*\d+시\s*$",  # "오전 9시"
                r"^\s*\d+시\s*야\s*$",  # "5시야", "3시야"
                r"^\s*\d+시\s*에\s*$",  # "5시에", "3시에"
                r"^\s*오후\s*\d+시\s*야\s*$",  # "오후 5시야"
                r"^\s*오전\s*\d+시\s*야\s*$",  # "오전 9시야"
                r"^\s*\d+시\s*란다\s*$",  # "5시란다", "3시란다"
                r"^\s*오후\s*\d+시\s*란다\s*$",  # "오후 5시란다"
                r"^\s*오전\s*\d+시\s*란다\s*$",  # "오전 9시란다"
                r"^\s*\d+시\s*다\s*$",  # "5시다", "3시다"
                r"^\s*오후\s*\d+시\s*다\s*$",  # "오후 5시다"
                r"^\s*오전\s*\d+시\s*다\s*$",  # "오전 9시다"
            ]
            
            is_time_only_response = any(re.search(pattern, text_lower) for pattern in time_only_patterns)
            
            # 디버깅 로그 추가
            self.logger.info(f"Time response check: text='{text}', is_time_only={is_time_only_response}, intent={intent.category}")
            
            # 시간 정보만 제공하는 경우 일정 추가로 보정
            if is_time_only_response and intent.category == "general_conversation":
                self.logger.info(f"Intent correction: general_conversation -> schedule_add (time response: {text})")
                return IntentAnalysis(
                    category="schedule_add",
                    confidence=0.9,
                    extracted_info={}
                )
            
            # 2. 간접적인 일정 추가 요청 감지 및 보정
            add_indicators = [
                "약속 있어", "해야 해", "있어", "예약해야", "잡아야",
                "친구랑", "랑", "와", "과"
            ]
            
            # 시간/날짜 표현과 함께 사용된 경우
            time_date_patterns = [
                r"다음\s*주", r"이번\s*주", r"내일", r"모레", r"오늘",
                r"\d+시", r"오전", r"오후", r"저녁", r"아침"
            ]
            
            has_time_date = any(re.search(pattern, text) for pattern in time_date_patterns)
            has_add_indicator = any(indicator in text_lower for indicator in add_indicators)
            
            # 구체적인 활동 키워드
            activity_keywords = [
                "점심", "식사", "영화", "만남", "회의", "진료", "검진",
                "약", "복용", "운동", "학원", "수업", "미팅"
            ]
            
            has_activity = any(keyword in text_lower for keyword in activity_keywords)
            
            # 일정 추가로 보정해야 하는 조건
            should_correct_to_add = (
                has_time_date and 
                has_add_indicator and 
                has_activity and
                intent.category == "schedule_read"
            )
            
            if should_correct_to_add:
                self.logger.info(f"Intent correction: schedule_read -> schedule_add (text: {text})")
                return IntentAnalysis(
                    category="schedule_add",
                    confidence=0.9,  # 높은 신뢰도로 보정
                    extracted_info={}
                )
            
            # 3. 명확한 조회 요청 감지
            read_indicators = [
                "뭐 있어", "일정 뭐야", "알려줘", "보여줘", "언제 있어",
                "일정이 언제", "일정 보여줘", "일정 알려줘"
            ]
            
            has_read_indicator = any(indicator in text_lower for indicator in read_indicators)
            
            # 조회로 보정해야 하는 조건
            should_correct_to_read = (
                has_read_indicator and
                intent.category == "schedule_add"
            )
            
            if should_correct_to_read:
                self.logger.info(f"Intent correction: schedule_add -> schedule_read (text: {text})")
                return IntentAnalysis(
                    category="schedule_read",
                    confidence=0.9,
                    extracted_info={}
                )
            
            return intent
            
        except Exception as e:
            self.logger.error(f"Intent correction failed: {e}")
            return intent
    
    def _save_pending_schedule(self, user_id: str, schedule_info: dict):
        """시간 누락된 일정 정보를 세션에 저장"""
        try:
            self._user_sessions[user_id] = {
                "pending_schedule": schedule_info,
                "last_intent": "schedule_add",
                "timestamp": time.time()
            }
            self.logger.info(f"Pending schedule saved for user {user_id}: {schedule_info}")
        except Exception as e:
            self.logger.error(f"Failed to save pending schedule: {e}")
    
    def _get_pending_schedule(self, user_id: str) -> dict:
        """세션에서 대기 중인 일정 정보 가져오기"""
        try:
            session = self._user_sessions.get(user_id)
            if session and time.time() - session["timestamp"] < 300:  # 5분 이내
                return session.get("pending_schedule", {})
            return {}
        except Exception as e:
            self.logger.error(f"Failed to get pending schedule: {e}")
            return {}
    
    def _clear_pending_schedule(self, user_id: str):
        """세션에서 대기 중인 일정 정보 삭제"""
        try:
            if user_id in self._user_sessions:
                del self._user_sessions[user_id]
                self.logger.info(f"Pending schedule cleared for user {user_id}")
        except Exception as e:
            self.logger.error(f"Failed to clear pending schedule: {e}")
    
    def _is_time_only_response(self, text: str) -> bool:
        """시간 정보만 제공하는 응답인지 확인"""
        time_only_patterns = [
            r"^\s*\d+시\s*$",  # "5시", "3시"
            r"^\s*오후\s*\d+시\s*$",  # "오후 5시"
            r"^\s*오전\s*\d+시\s*$",  # "오전 9시"
            r"^\s*\d+시\s*야\s*$",  # "5시야", "3시야"
            r"^\s*\d+시\s*에\s*$",  # "5시에", "3시에"
            r"^\s*오후\s*\d+시\s*야\s*$",  # "오후 5시야"
            r"^\s*오전\s*\d+시\s*야\s*$",  # "오전 9시야"
            r"^\s*\d+시\s*란다\s*$",  # "5시란다", "3시란다"
            r"^\s*오후\s*\d+시\s*란다\s*$",  # "오후 5시란다"
            r"^\s*오전\s*\d+시\s*란다\s*$",  # "오전 9시란다"
            r"^\s*\d+시\s*다\s*$",  # "5시다", "3시다"
            r"^\s*오후\s*\d+시\s*다\s*$",  # "오후 5시다"
            r"^\s*오전\s*\d+시\s*다\s*$",  # "오전 9시다"
        ]
        return any(re.search(pattern, text.lower()) for pattern in time_only_patterns)
    
    def _merge_time_with_pending_schedule(self, time_text: str, pending_schedule: dict) -> dict:
        """시간 정보를 대기 중인 일정 정보와 병합"""
        try:
            # 시간 정보 파싱
            time_match = re.search(r'(\d+)시', time_text)
            if not time_match:
                return pending_schedule
            
            hour = int(time_match.group(1))
            
            # 오전/오후 정보 확인
            if '오후' in time_text and hour < 12:
                hour += 12
            elif '오전' in time_text and hour == 12:
                hour = 0
            
            # 24시간 형식으로 변환
            time_str = f"{hour:02d}:00"
            
            # 병합된 일정 정보 생성
            merged_schedule = pending_schedule.copy()
            merged_schedule['time'] = time_str
            
            self.logger.info(f"Time merged: {time_text} -> {time_str}")
            return merged_schedule
            
        except Exception as e:
            self.logger.error(f"Failed to merge time: {e}")
            return pending_schedule
