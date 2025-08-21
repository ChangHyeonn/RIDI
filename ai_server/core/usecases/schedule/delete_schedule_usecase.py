#!/usr/bin/env python3
"""
Delete Schedule Use Case
일정 삭제 Use Case
"""

from dataclasses import dataclass
from typing import Dict, Any, Optional

from shared.logging.logger import LoggerFactory
from core.interfaces.repositories.schedule_repository import IScheduleRepository


@dataclass
class DeleteScheduleResult:
    """일정 삭제 결과"""
    success: bool
    deleted_title: Optional[str] = None
    error_message: Optional[str] = None


class DeleteScheduleUseCase:
    """일정 삭제 Use Case"""
    
    def __init__(self, schedule_repository: IScheduleRepository):
        self.schedule_repository = schedule_repository
        self.logger = LoggerFactory.get_logger(__name__)
    
    def execute(self, user_id: str, delete_info: Dict[str, Any]) -> DeleteScheduleResult:
        """일정 삭제 실행"""
        try:
            # ID로 삭제
            if delete_info.get('id'):
                schedule = self.schedule_repository.find_by_id(delete_info['id'])
                if schedule and schedule.user_id == user_id:
                    success = self.schedule_repository.delete(delete_info['id'])
                    if success:
                        self.logger.info(f"Schedule deleted by ID: {delete_info['id']}")
                        return DeleteScheduleResult(True, deleted_title=schedule.title)
                    else:
                        return DeleteScheduleResult(False, error_message="일정 삭제에 실패했습니다.")
                else:
                    return DeleteScheduleResult(False, error_message="일정을 찾을 수 없습니다.")
            
            # 제목으로 삭제
            elif delete_info.get('title'):
                title = delete_info['title']
                success = self.schedule_repository.delete_by_user_and_title(user_id, title)
                if success:
                    self.logger.info(f"Schedule deleted by title: {title}")
                    return DeleteScheduleResult(True, deleted_title=title)
                else:
                    return DeleteScheduleResult(False, error_message=f"'{title}' 일정을 찾을 수 없습니다.")
            
            else:
                return DeleteScheduleResult(False, error_message="삭제할 일정 정보가 부족합니다.")
                
        except Exception as e:
            self.logger.error(f"Delete schedule failed: {e}")
            return DeleteScheduleResult(False, error_message=f"일정 삭제 실패: {str(e)}")
