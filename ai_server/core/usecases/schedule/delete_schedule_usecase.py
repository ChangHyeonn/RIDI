#!/usr/bin/env python3
"""
Delete Schedule Use Case
일정 삭제 Use Case (스펙트럼 검색 지원)
"""

from dataclasses import dataclass
from typing import Dict, Any, Optional, List
import re

from shared.logging.logger import LoggerFactory
from core.interfaces.repositories.schedule_repository import IScheduleRepository


@dataclass
class DeleteScheduleResult:
    """일정 삭제 결과"""
    success: bool
    deleted_title: Optional[str] = None
    error_message: Optional[str] = None
    similar_schedules: Optional[List[Dict[str, Any]]] = None
    found_schedules: Optional[List[Dict[str, Any]]] = None  # 새로운 필드: 시각적 삭제용
    requires_selection: bool = False


class DeleteScheduleUseCase:
    """일정 삭제 Use Case"""
    
    def __init__(self, schedule_repository: IScheduleRepository):
        self.schedule_repository = schedule_repository
        self.logger = LoggerFactory.get_logger(__name__)
    
    def execute(self, user_id: str, delete_info: Dict[str, Any]) -> DeleteScheduleResult:
        """일정 삭제 실행 (스펙트럼 검색 + 시간대 지원)"""
        try:
            title = (delete_info.get('title') or '').strip()
            date_str = (delete_info.get('date') or '').strip()
            time_period = delete_info.get('time_period', '').strip()
            specific_time = delete_info.get('time', '').strip()
            
            if not title:
                return DeleteScheduleResult(False, error_message="삭제할 일정의 제목을 알려주세요.")
            
            # 1. 스펙트럼 검색으로 유사한 일정들 찾기 (시간대 필터링 포함)
            similar_schedules = self._find_similar_schedules(user_id, title, date_str, time_period, specific_time)
            
            # 2. 일치하는 일정이 없는 경우
            if not similar_schedules:
                time_info = ""
                if date_str and time_period:
                    time_info = f"{date_str} {time_period}에"
                elif date_str:
                    time_info = f"{date_str}에"
                elif time_period:
                    time_info = f"{time_period}에"
                
                if time_info:
                    return DeleteScheduleResult(False, error_message=f"{time_info} '{title}'과 관련된 일정을 찾을 수 없습니다.")
                else:
                    return DeleteScheduleResult(False, error_message=f"'{title}'과 관련된 일정을 찾을 수 없습니다.")
            
            # 3. 일치하는 일정이 1개인 경우 - 바로 삭제
            if len(similar_schedules) == 1:
                schedule_data = similar_schedules[0]
                schedule_id = schedule_data['id']
                success = self.schedule_repository.delete(schedule_id)
                if success:
                    self.logger.info(f"Schedule deleted: {schedule_data['title']} ({schedule_id})")
                    return DeleteScheduleResult(True, deleted_title=schedule_data['title'])
                else:
                    return DeleteScheduleResult(False, error_message="일정 삭제에 실패했습니다.")
            
            # 4. 일치하는 일정이 여러 개인 경우 - 선택 UI 제공
            else:
                return DeleteScheduleResult(
                    success=False,
                    similar_schedules=similar_schedules,
                    requires_selection=True,
                    error_message="여러 일정이 발견되었습니다. 선택해주세요."
                )
                
        except Exception as e:
            self.logger.error(f"Delete schedule failed: {e}")
            import traceback
            self.logger.error(f"Traceback: {traceback.format_exc()}")
            return DeleteScheduleResult(False, error_message=f"일정 삭제 실패: {str(e)}")
    
    def execute_direct(self, user_id: str, schedule_id: str) -> DeleteScheduleResult:
        """일정 직접 삭제 (ID로)"""
        try:
            # 일정 존재 확인
            schedule = self.schedule_repository.find_by_id(schedule_id)
            if not schedule:
                return DeleteScheduleResult(False, error_message="일정을 찾을 수 없습니다.")
            
            # 사용자 소유 확인
            if schedule.user_id != user_id:
                return DeleteScheduleResult(False, error_message="삭제 권한이 없습니다.")
            
            # 삭제 실행
            success = self.schedule_repository.delete(schedule_id)
            if success:
                self.logger.info(f"Schedule deleted directly: {schedule.title} ({schedule_id})")
                return DeleteScheduleResult(True, deleted_title=schedule.title)
            else:
                return DeleteScheduleResult(False, error_message="일정 삭제에 실패했습니다.")
                
        except Exception as e:
            self.logger.error(f"Direct delete schedule failed: {e}")
            import traceback
            self.logger.error(f"Traceback: {traceback.format_exc()}")
            return DeleteScheduleResult(False, error_message=f"일정 삭제 실패: {str(e)}")
    
    def execute_search(self, user_id: str, search_info: Dict[str, Any]) -> DeleteScheduleResult:
        """일정 검색 (삭제용)"""
        try:
            title = (search_info.get('title') or '').strip()
            date_str = (search_info.get('date') or '').strip()
            time_period = (search_info.get('time_period') or '').strip()
            specific_time = (search_info.get('time') or '').strip()
            
            # 유사한 일정들 찾기
            similar_schedules = self._find_similar_schedules(user_id, title, date_str, time_period, specific_time)
            
            return DeleteScheduleResult(
                success=True,
                found_schedules=similar_schedules
            )
                
        except Exception as e:
            self.logger.error(f"Search schedules failed: {e}")
            import traceback
            self.logger.error(f"Traceback: {traceback.format_exc()}")
            return DeleteScheduleResult(False, error_message=f"일정 검색 실패: {str(e)}")
    
    def _find_similar_schedules(self, user_id: str, search_title: str, date_str: str = None, time_period: str = None, specific_time: str = None) -> List[Dict[str, Any]]:
        """유사한 일정들을 찾는 함수 (스펙트럼 검색) - description + 시간대 포함"""
        try:
            # 1. 일정 조회
            if date_str:
                    from datetime import datetime
                    target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
                    user_schedules = self.schedule_repository.find_by_user_and_date(user_id, target_date)
            else:
                user_schedules = self.schedule_repository.find_by_user_id(user_id)
            
            # 2. 유사도 계산 및 필터링 (title + description + 시간대 고려)
            similar_schedules = []
            for schedule in user_schedules:
                # title이 None인 경우 건너뛰기
                if schedule.title is None:
                    self.logger.warning(f"Schedule {schedule.id} has None title, skipping")
                    continue
                
                # 시간대 필터링
                if not self._matches_time_filter(schedule, time_period, specific_time):
                    continue
                
                # title과 description 모두 고려한 유사도 계산
                title_similarity = self._calculate_similarity(search_title, schedule.title)
                description_similarity = 0.0
                
                # description이 있는 경우 description 유사도도 계산
                if schedule.description:
                    description_similarity = self._calculate_similarity(search_title, schedule.description)
                
                # 복합 검색어인 경우 (예: "친구랑 롯데시네마에서 영화 보기") description에 더 높은 가중치
                if len(search_title.split()) > 2:  # 3개 이상의 단어가 있는 경우
                    similarity = max(title_similarity, description_similarity * 1.2)  # description에 더 높은 가중치
                else:
                    similarity = max(title_similarity, description_similarity * 0.8)  # 기존 가중치
                
                self.logger.info(f"Similarity for '{search_title}' vs '{schedule.title}': title={title_similarity:.3f}, desc={description_similarity:.3f}, final={similarity:.3f}")
                
                # 정확한 제목 매칭 우선 확인
                exact_title_match = search_title.lower().strip() == schedule.title.lower().strip()
                
                # 유사도 임계값 (정확한 매칭이면 더 낮은 임계값도 허용)
                similarity_threshold = 0.1 if exact_title_match else 0.3
                
                if similarity >= similarity_threshold or exact_title_match:
                    similar_schedules.append({
                        'id': schedule.id,
                        'title': schedule.title,
                        'description': schedule.description,  # description 추가
                        'datetime': schedule.start_datetime.isoformat() if schedule.start_datetime else None,
                        'category': schedule.category,
                        'similarity': similarity,
                        'is_recurring': schedule.is_recurring,
                        'exact_match': exact_title_match
                    })
            
            # 3. 정확한 매칭 우선, 그 다음 유사도 순으로 정렬
            similar_schedules.sort(key=lambda x: (not x.get('exact_match', False), -x['similarity']))
            
            # 4. 상위 5개만 반환 (너무 많으면 선택이 어려움)
            self.logger.info(f"Found {len(similar_schedules)} similar schedules for '{search_title}': {[s['title'] for s in similar_schedules[:5]]}")
            return similar_schedules[:5]
            
        except Exception as e:
            self.logger.error(f"Find similar schedules failed: {e}")
            import traceback
            self.logger.error(f"Traceback: {traceback.format_exc()}")
            return []
    
    def _matches_time_filter(self, schedule, time_period: str = None, specific_time: str = None) -> bool:
        """시간대 필터링 함수"""
        if not schedule.start_datetime:
            return True  # 시간 정보가 없으면 통과
        
        hour = schedule.start_datetime.hour
        
        if time_period:
            if time_period == 'morning' and 6 <= hour < 12:
                return True
            elif time_period == 'afternoon' and 12 <= hour < 18:
                return True
            elif time_period == 'evening' and 18 <= hour < 22:
                return True
            elif time_period == 'night' and (hour >= 22 or hour < 6):
                return True
            else:
                return False
        
        elif specific_time:
            # 구체적 시간 검색 (30분 범위)
            target_hour, target_minute = map(int, specific_time.split(':'))
            target_datetime = schedule.start_datetime.replace(hour=target_hour, minute=target_minute)
            
            # 30분 범위 내 일정 찾기
            time_diff = abs((schedule.start_datetime - target_datetime).total_seconds() / 60)
            return time_diff <= 30
        
        return True  # 시간 필터가 없으면 통과
    
    def _calculate_similarity(self, text1: str, text2: str) -> float:
        """텍스트 유사도 계산 (의료 키워드 매칭 지원)"""
        try:
            # None 체크
            if text1 is None or text2 is None:
                return 0.0
            
            # 1. 텍스트 정규화
            text1_normalized = self._normalize_text(text1)
            text2_normalized = self._normalize_text(text2)
            
            # 2. 단어 분리
            words1 = set(text1_normalized.split())
            words2 = set(text2_normalized.split())
            
            # 3. Jaccard 유사도 계산
            intersection = words1.intersection(words2)
            union = words1.union(words2)
            
            if not union:
                return 0.0
            
            base_similarity = len(intersection) / len(union)
            
            # 4. 추가 가중치 적용
            # 완전 일치
            if text1_normalized == text2_normalized:
                return 1.0
            
            # 포함 관계
            if text1_normalized in text2_normalized or text2_normalized in text1_normalized:
                base_similarity += 0.3
            
            # 키워드 매칭
            keywords1 = set(re.findall(r'[가-힣]+', text1_normalized))
            keywords2 = set(re.findall(r'[가-힣]+', text2_normalized))
            keyword_intersection = keywords1.intersection(keywords2)
            if keyword_intersection:
                base_similarity += 0.15 * len(keyword_intersection)
            
            # 5. 의미적 관련성 체크 (의료 관련 키워드)
            medical_similarity = self._check_medical_similarity(text1_normalized, text2_normalized)
            if medical_similarity > 0:
                base_similarity += medical_similarity
            
            return min(base_similarity, 1.0)
            
        except Exception as e:
            self.logger.error(f"Calculate similarity failed: {e}")
            return 0.0
    
    def _check_medical_similarity(self, text1: str, text2: str) -> float:
        """의료 관련 키워드 유사도 체크"""
        # None 체크
        if text1 is None or text2 is None:
            return 0.0
            
        medical_groups = {
            '병원': ['병원', '의원', '클리닉', '치과', '한의원', '정형외과', '내과', '외과', '산부인과'],
            '검진': ['검진', '검사', '진료', '시술', '수술', '치료', '상담'],
            '약물': ['약', '처방', '복용', '투약', '주사'],
            '건강': ['건강', '체크업', '예방접종', '백신']
        }
        
        # 각 그룹에 대해 매칭 확인
        for group_name, keywords in medical_groups.items():
            text1_match = any(keyword in text1 for keyword in keywords)
            text2_match = any(keyword in text2 for keyword in keywords)
            
            if text1_match and text2_match:
                return 0.25  # 같은 의료 그룹에 속하면 유사도 증가
        
        return 0.0
    
    def _normalize_text(self, text: str) -> str:
        """텍스트 정규화"""
        if text is None:
            return ""
        
        if not text:
            return ""
        
        # 소문자 변환
        normalized = text.lower()
        
        # 불필요한 문자 제거
        normalized = re.sub(r'[^\w\s가-힣]', ' ', normalized)
        
        # 연속된 공백을 하나로
        normalized = re.sub(r'\s+', ' ', normalized)
        
        return normalized.strip()
    
    def execute_selection(self, user_id: str, selected_schedule_ids: List[str]) -> DeleteScheduleResult:
        """선택된 일정들 삭제 실행"""
        try:
            if not selected_schedule_ids:
                return DeleteScheduleResult(False, error_message="삭제할 일정을 선택해주세요.")
            
            deleted_titles = []
            failed_deletions = []
            
            for schedule_id in selected_schedule_ids:
                # 일정 정보 조회
                schedule = self.schedule_repository.find_by_id(schedule_id)
                if not schedule:
                    failed_deletions.append(f"ID {schedule_id}")
                    continue
                
                # 삭제 실행
                success = self.schedule_repository.delete(schedule_id)
                if success:
                    deleted_titles.append(schedule.title)
                    self.logger.info(f"Schedule deleted: {schedule.title} ({schedule_id})")
                else:
                    failed_deletions.append(schedule.title)
            
            # 결과 반환
            if deleted_titles and not failed_deletions:
                # 모두 성공
                if len(deleted_titles) == 1:
                    return DeleteScheduleResult(True, deleted_title=deleted_titles[0])
                else:
                    return DeleteScheduleResult(True, deleted_title=", ".join(deleted_titles))
            elif deleted_titles and failed_deletions:
                # 일부 성공
                success_msg = f"{', '.join(deleted_titles)} 일정을 삭제했습니다."
                error_msg = f"다음 일정 삭제에 실패했습니다: {', '.join(failed_deletions)}"
                return DeleteScheduleResult(False, error_message=f"{success_msg} {error_msg}")
            else:
                # 모두 실패
                return DeleteScheduleResult(False, error_message=f"일정 삭제에 실패했습니다: {', '.join(failed_deletions)}")
                
        except Exception as e:
            self.logger.error(f"Execute selection failed: {e}")
            return DeleteScheduleResult(False, error_message=f"일정 삭제 실패: {str(e)}")
    
    def execute_delete_by_id(self, user_id: str, schedule_id: str) -> DeleteScheduleResult:
        """특정 ID의 일정 삭제"""
        try:
            # 일정 존재 확인
            schedule = self.schedule_repository.find_by_id(schedule_id)
            if not schedule:
                return DeleteScheduleResult(False, error_message="일정을 찾을 수 없습니다.")
            
            # 삭제 실행
            success = self.schedule_repository.delete(schedule_id)
            if success:
                return DeleteScheduleResult(True, deleted_title=schedule.title)
            else:
                return DeleteScheduleResult(False, error_message="일정 삭제에 실패했습니다.")
                
        except Exception as e:
            self.logger.error(f"Execute delete by id failed: {e}")
            return DeleteScheduleResult(False, error_message=f"일정 삭제 실패: {str(e)}")
