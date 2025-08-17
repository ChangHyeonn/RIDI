#!/usr/bin/env python3
"""
Unified Request Processor
LLM 중심의 통합 요청 처리기
"""

import json
import logging
import os
from datetime import datetime
from typing import Dict, Any, Optional

from Config.prompts import PromptManager
from Models.LLM import LLMFactory
from Services.ScheduleManager import ScheduleManager
from Services.AccessibilityManager import AccessibilityManager
from Services.Memory import MemoryManager


class UnifiedRequestProcessor:
    """LLM 중심의 통합 요청 처리기"""
    
    def __init__(self, llm_type: str = "gemini"):
        self._setup_logging()
        self._initialize_components(llm_type)
        self.logger.info("Unified Request Processor initialized successfully")
    
    def _setup_logging(self):
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
    
    def _initialize_components(self, llm_type: str):
        """컴포넌트 초기화"""
        try:
            # LLM 초기화
            self.llm = LLMFactory.create_llm(llm_type)
            
            # 서비스 컴포넌트들 초기화
            self.schedule_manager = ScheduleManager()
            self.accessibility_manager = AccessibilityManager()
            self.memory_manager = MemoryManager()
            
        except Exception as e:
            self.logger.error(f"Failed to initialize components: {e}")
            raise
    
    def process_request(self, user_request: str, user_id: Optional[str] = None) -> Dict[str, Any]:
        """사용자 요청 처리 (메인 엔트리 포인트)"""
        try:
            # 1. LLM으로 요청 분석
            analysis = self._analyze_request_with_llm(user_request)
            
            # 2. 분석 결과 검증
            if not self._validate_analysis(analysis):
                return self._create_error_response("요청 분석에 실패했습니다.")
            
            # 3. 범주별 처리
            category = analysis.get('category', 'other')
            result = self._process_by_category(category, analysis, user_id)
            
            # 4. 메모리에 상호작용 저장
            if user_id:
                self.memory_manager.store_interaction(user_id, {
                    'request': user_request,
                    'analysis': analysis,
                    'result': result,
                    'timestamp': datetime.now().isoformat()
                })
            
            # 5. 응답 생성
            return self._create_success_response(analysis, result)
            
        except Exception as e:
            self.logger.error(f"Request processing failed: {e}")
            return self._create_error_response(f"요청 처리 중 오류가 발생했습니다: {str(e)}")
    
    def _analyze_request_with_llm(self, user_request: str) -> Dict[str, Any]:
        """단계별 LLM 요청 분석"""
        try:
            # 1단계: 의도 분류
            intent_prompt = PromptManager.get_intent_classification_prompt(user_request)
            intent_response = self.llm.generate(intent_prompt)
            intent_analysis = self._parse_llm_response(intent_response)
            
            self.logger.info(f"Intent classified: {user_request} -> {intent_analysis.get('intent', 'unknown')}")
            
            # 2단계: 정보 추출 (필요한 경우)
            extracted_info = {}
            if intent_analysis.get('requires_extraction', False):
                extraction_prompt = PromptManager.get_schedule_extraction_prompt(user_request)
                extraction_response = self.llm.generate(extraction_prompt)
                extracted_info = self._parse_llm_response(extraction_response)
                self.logger.info(f"Information extracted: {extracted_info}")
            
            # 3단계: 통합 분석 결과 생성
            analysis = {
                'category': intent_analysis.get('intent', 'other'),
                'confidence': intent_analysis.get('confidence', 0.0),
                'extracted_info': extracted_info,
                'intent_analysis': intent_analysis
            }
            
            self.logger.info(f"Request analyzed: {user_request} -> {analysis.get('category', 'unknown')}")
            return analysis
            
        except Exception as e:
            self.logger.error(f"LLM analysis failed: {e}")
            return {
                'category': 'other',
                'confidence': 0.0,
                'error': str(e)
            }
    
    def _parse_llm_response(self, response: str) -> Dict[str, Any]:
        """LLM 응답에서 JSON 파싱"""
        try:
            # 응답이 비어있는지 확인
            if not response or not response.strip():
                self.logger.warning("Empty LLM response received")
                return {
                    'category': 'other',
                    'confidence': 0.0,
                    'error': '빈 응답을 받았습니다'
                }
            
            # JSON 블록 추출
            response = response.strip()
            if response.startswith("```json"):
                response = response[7:]
            if response.endswith("```"):
                response = response[:-3]
            response = response.strip()
            
            # JSON 파싱 시도
            try:
                return json.loads(response)
            except json.JSONDecodeError as json_error:
                self.logger.error(f"JSON parsing failed: {json_error}")
                self.logger.error(f"Raw response: {response}")
                
                # JSON 파싱 실패 시 기본 응답 반환
                return {
                    'category': 'other',
                    'confidence': 0.0,
                    'error': f'JSON 파싱 실패: {str(json_error)}',
                    'raw_response': response
                }
            
        except Exception as e:
            self.logger.error(f"Failed to parse LLM response: {e}")
            self.logger.error(f"Raw response: {response}")
            return {
                'category': 'other',
                'confidence': 0.0,
                'error': f"응답 파싱 실패: {str(e)}",
                'raw_response': response
            }
    
    def _validate_analysis(self, analysis: Dict[str, Any]) -> bool:
        """분석 결과 검증"""
        required_fields = ['category', 'confidence']
        
        for field in required_fields:
            if field not in analysis:
                return False
        
        if analysis.get('confidence', 0.0) < 0.3:
            return False
        
        return True
    
    def _process_by_category(self, category: str, analysis: Dict[str, Any], user_id: Optional[str]) -> Dict[str, Any]:
        """범주별 처리"""
        try:
            if category == 'schedule_add':
                return self._handle_schedule_add(analysis, user_id)
            elif category == 'schedule_modify':
                return self._handle_schedule_modify(analysis, user_id)
            elif category == 'schedule_delete':
                return self._handle_schedule_delete(analysis, user_id)
            elif category == 'schedule_read':
                return self._handle_schedule_read(analysis, user_id)
            elif category == 'accessibility':
                return self._handle_accessibility(analysis)
            else:
                return self._handle_other_request(analysis)
                
        except Exception as e:
            self.logger.error(f"Category processing failed for {category}: {e}")
            return {
                'success': False,
                'error': f"{category} 처리 중 오류가 발생했습니다."
            }
    
    def _handle_schedule_add(self, analysis: Dict[str, Any], user_id: Optional[str]) -> Dict[str, Any]:
        """일정 추가 처리"""
        extracted_info = analysis.get('extracted_info', {})
        
        # 필수 정보 검증
        if not extracted_info.get('title'):
            return {
                'success': False,
                'requires_clarification': True,
                'missing_fields': ['title'],
                'message': '일정 내용을 말씀해 주시겠어요?'
            }
        
        if not extracted_info.get('date'):
            return {
                'success': False,
                'requires_clarification': True,
                'missing_fields': ['date'],
                'message': '언제 일정을 잡으시겠어요? 날짜를 말씀해 주세요.'
            }

        # 시간 정보 누락 시 질문 (기본값 사용 대신 명확화 요구)
        if not extracted_info.get('time'):
            return {
                'success': False,
                'requires_clarification': True,
                'missing_fields': ['time'],
                'message': '몇 시로 설정할까요? 오전/오후와 함께 말씀해 주세요.'
            }
        
        # 일정 추가
        schedule_data = {
            'title': extracted_info.get('title', ''),
            'datetime': f"{extracted_info.get('date', '')} {extracted_info.get('time', '')}",
            'category': extracted_info.get('category', '일반'),
            'is_important': self._convert_priority_to_boolean(extracted_info.get('priority', '')),
            'location': extracted_info.get('location', ''),
            'description': extracted_info.get('description', '')
        }
        # 음성 출력용 한국어 메시지 ("~월 ~일 ~시에 ~ 일정을 추가하였습니다.")
        try:
            message = self._format_added_schedule_message(
                title=schedule_data.get('title', ''),
                date=extracted_info.get('date'),
                time=extracted_info.get('time')
            )
        except Exception:
            message = '일정이 성공적으로 추가되었습니다.'
        
        if user_id:
            add_result = self.schedule_manager.add_schedule(user_id, schedule_data)
            schedule_id = add_result.get('schedule_id')
            return {
                'success': True,
                'action': 'schedule_added',
                'schedule_id': schedule_id,
                'schedule': schedule_data,
                'message': message
            }
        else:
            return {
                'success': True,
                'action': 'schedule_added',
                'schedule': schedule_data,
                'message': message
            }

    def _format_added_schedule_message(self, title: str, date: Optional[str], time: Optional[str]) -> str:
        """추가된 일정에 대한 한국어 음성 안내 메시지 생성
        - 형식: "{M}월 {D}일 {H}시{MM분}에 {title} 일정을 추가하였습니다."
        - date: YYYY-MM-DD, time: HH:MM (옵션)
        """
        try:
            month_day = ""
            if date and len(date) == 10:
                # YYYY-MM-DD
                _, m, d = date.split('-')
                month_day = f"{int(m)}월 {int(d)}일 "
            hour_min = ""
            if time and len(time) >= 4:
                # HH:MM
                h, mm = time.split(':')
                h_i = int(h)
                mm_i = int(mm) if mm.isdigit() else 0
                if mm_i == 0:
                    hour_min = f"{h_i}시에 "
                else:
                    hour_min = f"{h_i}시 {mm_i}분에 "
            phrase = f"{month_day}{hour_min}{title} 일정을 추가하였습니다."
            return phrase.strip()
        except Exception:
            return "일정이 성공적으로 추가되었습니다."

    def _convert_priority_to_boolean(self, priority_str: str) -> bool:
        """LLM에서 추출된 priority 문자열을 boolean으로 변환
        - 중요한 경우: True
        - 중요하지 않은 경우: False
        """
        if not priority_str:
            return False
        
        priority_lower = priority_str.lower().strip()
        important_keywords = ['high', 'important', '중요', '긴급', 'urgent', 'critical', '높음']
        
        return any(keyword in priority_lower for keyword in important_keywords)
    
    def _handle_schedule_modify(self, analysis: Dict[str, Any], user_id: Optional[str]) -> Dict[str, Any]:
        """일정 수정 처리"""
        extracted_info = analysis.get('extracted_info', {})
        
        # 수정할 일정 식별 필요
        if not extracted_info.get('title'):
            return {
                'success': False,
                'requires_clarification': True,
                'message': '어떤 일정을 수정하시겠어요?'
            }
        
        return {
            'success': True,
            'action': 'schedule_modify',
            'modify_info': extracted_info,
            'message': '일정 수정을 진행하겠습니다.'
        }
    
    def _handle_schedule_delete(self, analysis: Dict[str, Any], user_id: Optional[str]) -> Dict[str, Any]:
        """일정 삭제 처리 (단일/일괄 삭제 지원)"""
        extracted_info = analysis.get('extracted_info', {})
        delete_scope = analysis.get('delete_scope', 'single')
        delete_criteria = analysis.get('delete_criteria', {})
        
        # 삭제할 일정 식별 정보
        title = extracted_info.get('title')
        date = extracted_info.get('date') or delete_criteria.get('date')
        time = extracted_info.get('time')

        # 사용자 식별 필요
        if not user_id:
            return {
                'success': False,
                'requires_clarification': True,
                'message': '삭제할 일정을 찾기 위해 사용자를 식별할 수 없어 확인이 필요합니다.'
            }

        # 일괄 삭제 처리
        if delete_scope == 'bulk':
            if not date:
                return {
                    'success': False,
                    'requires_clarification': True,
                    'missing_fields': ['date'],
                    'message': '어느 날짜의 일정을 삭제하시겠어요? 날짜를 말씀해 주세요.'
                }
            
            # 날짜 기반 일괄 삭제 후보 검색
            candidates = self.schedule_manager.get_schedules_by_date(user_id, date)
            
            if len(candidates) == 0:
                return {
                    'success': False,
                    'requires_clarification': True,
                    'message': f'{date}에 등록된 일정이 없습니다.'
                }
            
            if len(candidates) == 1:
                # 단일 일정인 경우 바로 삭제
                schedule = candidates[0]
                return {
                    'success': True,
                    'action': 'schedule_delete',
                    'delete_info': {
                        'id': schedule.get('id'),
                        'title': schedule.get('data', {}).get('title'),
                        'datetime': schedule.get('data', {}).get('datetime')
                    },
                    'message': f'{date}의 일정을 삭제하겠습니다.'
                }
            else:
                # 여러 일정인 경우 확인 요청
                brief = [
                    {
                        'id': s.get('id'),
                        'title': s.get('data', {}).get('title'),
                        'datetime': s.get('data', {}).get('datetime')
                    }
                    for s in candidates
                ]
                return {
                    'success': False,
                    'requires_clarification': True,
                    'candidates': brief,
                    'message': f'{date}에 {len(candidates)}개의 일정이 있습니다. 모두 삭제하시겠어요?'
                }

        # 단일 삭제 처리
        else:
            if not title:
                return {
                    'success': False,
                    'requires_clarification': True,
                    'missing_fields': ['title'],
                    'message': '어떤 일정을 삭제하시겠어요? 일정 제목을 말씀해 주세요.'
                }

            # 후보 검색 및 모호성 해소
            candidates = self.schedule_manager.find_schedules(user_id, title=title, date=date, time=time)

            if len(candidates) == 0:
                return {
                    'success': False,
                    'requires_clarification': True,
                    'message': f"'{title}' 일정이 보이지 않습니다. 날짜나 시간을 함께 말씀해 주세요."
                }

            if len(candidates) > 1:
                brief = [
                    {
                        'id': s.get('id'),
                        'title': s.get('data', {}).get('title'),
                        'datetime': s.get('data', {}).get('datetime')
                    }
                    for s in candidates
                ]
                return {
                    'success': False,
                    'requires_clarification': True,
                    'candidates': brief,
                    'message': f"'{title}' 일정이 여러 개 있습니다. 삭제할 일정의 날짜/시간을 말씀해 주세요."
                }

            only = candidates[0]
            return {
                'success': True,
                'action': 'schedule_delete',
                'delete_info': {
                    'id': only.get('id'),
                    'title': only.get('data', {}).get('title'),
                    'datetime': only.get('data', {}).get('datetime')
                },
                'message': '일정 삭제를 진행하겠습니다.'
            }
    
    def _handle_schedule_read(self, analysis: Dict[str, Any], user_id: Optional[str]) -> Dict[str, Any]:
        """일정 조회 처리"""
        extracted_info = analysis.get('extracted_info', {})
        date = extracted_info.get('date')

        # 날짜 정보 누락 시 질문
        if not date:
            return {
                'success': False,
                'requires_clarification': True,
                'missing_fields': ['date'],
                'message': '언제 일정을 조회할까요? 날짜를 말씀해 주세요.'
            }
        
        if user_id:
            schedules = self.schedule_manager.get_schedules_by_date(user_id, date)
            return {
                'success': True,
                'action': 'schedule_read',
                'schedules': schedules,
                'date': date,
                'message': f'{date} 일정을 조회합니다.'
            }
        else:
            return {
                'success': True,
                'action': 'schedule_read',
                'date': date,
                'message': f'{date} 일정을 조회합니다.'
            }
    
    def _handle_accessibility(self, analysis: Dict[str, Any]) -> Dict[str, Any]:
        """접근성 설정 처리"""
        extracted_info = analysis.get('extracted_info', {})
        
        setting_type = extracted_info.get('setting_type', '')
        action = extracted_info.get('action', '')
        
        return {
            'success': True,
            'action': 'accessibility_change',
            'setting_type': setting_type,
            'action': action,
            'message': '접근성 설정을 변경하겠습니다.'
        }
    
    def _handle_other_request(self, analysis: Dict[str, Any]) -> Dict[str, Any]:
        """기타 요청 처리"""
        return {
            'success': False,
            'action': 'unsupported',
            'message': '죄송합니다. 지원하지 않는 요청입니다.'
        }
    
    def _create_success_response(self, analysis: Dict[str, Any], result: Dict[str, Any]) -> Dict[str, Any]:
        """성공 응답 생성"""
        return {
            'success': True,
            'analysis': analysis,
            'result': result,
            'timestamp': datetime.now().isoformat()
        }
    
    def _create_error_response(self, error_message: str) -> Dict[str, Any]:
        """에러 응답 생성"""
        return {
            'success': False,
            'error': error_message,
            'timestamp': datetime.now().isoformat()
        }
    
    def get_processor_info(self) -> Dict[str, Any]:
        """처리기 정보"""
        return {
            'processor_type': 'Unified Request Processor',
            'llm_model': self.llm.get_model_info(),
            'supported_categories': [
                'schedule_add',
                'schedule_modify', 
                'schedule_delete',
                'schedule_read',
                'accessibility',
                'other'
            ],
            'features': {
                'llm_analysis': True,
                'unified_processing': True,
                'memory_integration': True,
                'error_handling': True
            }
        }
