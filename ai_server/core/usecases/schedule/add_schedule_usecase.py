#!/usr/bin/env python3
"""
Add Schedule Use Case
일정 추가 Use Case
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Dict, Any, Optional

from shared.logging.logger import LoggerFactory
from core.entities.schedule import Schedule
from core.interfaces.repositories.schedule_repository import IScheduleRepository


@dataclass
class AddScheduleResult:
    """일정 추가 결과"""
    success: bool
    schedule_data: Optional[Dict[str, Any]] = None
    error_message: Optional[str] = None


class AddScheduleUseCase:
    """일정 추가 Use Case"""
    
    def __init__(self, schedule_repository: IScheduleRepository):
        self.schedule_repository = schedule_repository
        self.logger = LoggerFactory.get_logger(__name__)
    
    def execute(self, user_id: str, schedule_info: Dict[str, Any]) -> AddScheduleResult:
        """일정 추가 실행"""
        try:
            # AI_02 스타일 로그: 입력 정보 로깅
            self.logger.info(f"Schedule add request: user={user_id}, info={schedule_info}")
            
            # 1. 필수 정보 검증
            if not schedule_info.get('title'):
                self.logger.warning("Schedule add failed: missing title")
                return AddScheduleResult(False, error_message="일정 제목이 필요합니다.")
            
            if not schedule_info.get('date') or not schedule_info.get('time'):
                self.logger.warning("Schedule add failed: missing date/time")
                return AddScheduleResult(False, error_message="일정 날짜와 시간이 필요합니다.")
            
            # 2. 날짜/시간 파싱
            try:
                date_str = schedule_info['date']
                time_str = schedule_info['time']
                datetime_str = f"{date_str} {time_str}"
                start_datetime = datetime.fromisoformat(datetime_str)
            except (ValueError, KeyError) as e:
                self.logger.error(f"DateTime parsing failed: {e}")
                return AddScheduleResult(False, error_message="날짜 형식이 올바르지 않습니다.")
            
            # 3. 일정 엔티티 생성 (반복 일정 지원)
            is_recurring = schedule_info.get('is_recurring', False)
            recurrence_pattern = None
            
            if is_recurring and 'recurrence' in schedule_info:
                # 반복 패턴 생성
                from core.entities.schedule import RecurrencePattern, RecurrenceTime
                
                recurrence_data = schedule_info['recurrence']
                times = []
                for time_info in recurrence_data.get('times', []):
                    times.append(RecurrenceTime(
                        time=time_info.get('time', ''),
                        label=time_info.get('label')
                    ))
                
                recurrence_pattern = RecurrencePattern(
                    type=recurrence_data.get('type', 'daily'),
                    times=times,
                    end_date=recurrence_data.get('end_date'),
                    days_of_week=recurrence_data.get('days_of_week')
                )
            
            schedule = Schedule(
                id=None,  # Repository에서 생성
                user_id=user_id,
                title=schedule_info['title'],
                start_datetime=start_datetime,
                category=schedule_info.get('category', '일반'),
                is_important=schedule_info.get('is_important', False),
                location=schedule_info.get('location'),
                description=schedule_info.get('description'),
                is_recurring=is_recurring,
                recurrence_pattern=recurrence_pattern
            )
            
            # AI_02 스타일 로그: 일정 생성 완료
            self.logger.info(f"Schedule entity created: {schedule.title} at {start_datetime}")
            
            # 4. 저장
            saved_schedule = self.schedule_repository.save(schedule)
            
            # AI_02 스타일 로그: 저장 완료
            self.logger.info(f"Schedule saved to repository: {saved_schedule.title} (ID: {saved_schedule.id})")
            
            # 5. 결과 반환 (반복 일정 정보 포함)
            schedule_data = {
                'id': saved_schedule.id,
                'title': saved_schedule.title,
                'datetime': saved_schedule.start_datetime.isoformat(),
                'category': saved_schedule.category,
                'is_important': saved_schedule.is_important,
                'location': saved_schedule.location,
                'description': saved_schedule.description,
                'is_recurring': saved_schedule.is_recurring
            }
            
            # 반복 일정 정보 추가
            if saved_schedule.is_recurring and saved_schedule.recurrence_pattern:
                schedule_data['recurrence'] = {
                    'type': saved_schedule.recurrence_pattern.type,
                    'times': [{
                        'time': rt.time,
                        'label': rt.label
                    } for rt in saved_schedule.recurrence_pattern.times],
                    'end_date': saved_schedule.recurrence_pattern.end_date,
                    'days_of_week': saved_schedule.recurrence_pattern.days_of_week
                }
            
            # AI_02 스타일 로그: 최종 성공
            self.logger.info(f"Schedule added successfully: {saved_schedule.title}")
            return AddScheduleResult(True, schedule_data=schedule_data)
            
        except Exception as e:
            self.logger.error(f"Add schedule failed: {e}")
            return AddScheduleResult(False, error_message=f"일정 추가 실패: {str(e)}")
