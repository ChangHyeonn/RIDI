#!/usr/bin/env python3
"""
Unified Request Processor
LLM 중심의 통합 요청 처리기
"""

import json
import logging
import sys
import os
from datetime import datetime
from typing import Dict, Any, Optional

# 프로젝트 루트를 Python 경로에 추가
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

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
        """LLM을 사용한 요청 분석"""
        try:
            # 프롬프트 매니저에서 통합 분석 프롬프트 가져오기
            prompt = PromptManager.get_unified_request_analysis_prompt(user_request)
            
            # LLM에 분석 요청
            response = self.llm.generate_response(prompt)
            
            # JSON 파싱
            analysis = self._parse_llm_response(response)
            
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
            # JSON 블록 추출
            response = response.strip()
            if response.startswith("```json"):
                response = response[7:]
            if response.endswith("```"):
                response = response[:-3]
            response = response.strip()
            
            # JSON 파싱
            return json.loads(response)
            
        except Exception as e:
            self.logger.error(f"Failed to parse LLM response: {e}")
            return {
                'category': 'other',
                'confidence': 0.0,
                'error': f"응답 파싱 실패: {str(e)}"
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
            'priority': extracted_info.get('priority', 'normal'),
            'location': extracted_info.get('location', ''),
            'description': extracted_info.get('description', '')
        }
        
        if user_id:
            add_result = self.schedule_manager.add_schedule(user_id, schedule_data)
            schedule_id = add_result.get('schedule_id')
            return {
                'success': True,
                'action': 'schedule_added',
                'schedule_id': schedule_id,
                'schedule': schedule_data,
                'message': '일정이 성공적으로 추가되었습니다.'
            }
        else:
            return {
                'success': True,
                'action': 'schedule_added',
                'schedule': schedule_data,
                'message': '일정이 추가되었습니다.'
            }
    
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
