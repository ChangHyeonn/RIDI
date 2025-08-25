#!/usr/bin/env python3
"""
MongoDB Schedule Repository Implementation
MongoDB 일정 저장소 구현 (어댑터)
"""

from typing import List, Optional
from datetime import date, datetime
import uuid

from shared.logging.logger import LoggerFactory
from shared.config.settings import DatabaseConfig
from core.entities.schedule import Schedule
from core.interfaces.repositories.schedule_repository import IScheduleRepository

try:
    from pymongo import MongoClient
    from bson import ObjectId
    PYMONGO_AVAILABLE = True
except ImportError:
    MongoClient = None
    ObjectId = None
    PYMONGO_AVAILABLE = False


class MongoDBScheduleRepository(IScheduleRepository):
    """MongoDB 일정 저장소 구현"""
    
    def __init__(self, config: DatabaseConfig):
        self.config = config
        self.logger = LoggerFactory.get_logger(__name__)
        
        if not PYMONGO_AVAILABLE:
            raise RuntimeError("PyMongo is not installed. Please install it: pip install pymongo")
        
        self.client = MongoClient(config.mongo_uri)
        self.db = self.client[config.mongo_db]
        self.collection = self.db.schedules
        
        self._ensure_indexes()
    
    def _ensure_indexes(self):
        """인덱스 생성"""
        try:
            self.collection.create_index([("user_id", 1), ("start_datetime", 1)])
            self.collection.create_index([("user_id", 1), ("status", 1)])
            self.collection.create_index([("user_id", 1), ("is_important", 1)])
            self.logger.info("MongoDB indexes created successfully")
        except Exception as e:
            self.logger.warning(f"Failed to create indexes: {e}")
    
    def save(self, schedule: Schedule) -> Schedule:
        """일정 저장"""
        try:
            # 새 일정인 경우 ID 생성
            if schedule.id is None:
                schedule.id = str(uuid.uuid4())
            
            # MongoDB 문서 생성
            doc = {
                '_id': ObjectId() if not self._is_valid_object_id(schedule.id) else ObjectId(schedule.id),
                'schedule_id': schedule.id,
                'user_id': schedule.user_id,
                'title': schedule.title,
                'start_datetime': schedule.start_datetime,
                'category': schedule.category,
                'is_important': schedule.is_important,
                'location': schedule.location,
                'description': schedule.description,
                'status': schedule.status,
                'created_at': schedule.created_at,
                'updated_at': schedule.updated_at
            }
            
            # Upsert 수행
            self.collection.replace_one(
                {'schedule_id': schedule.id},
                doc,
                upsert=True
            )
            
            self.logger.info(f"Schedule saved: {schedule.title}")
            return schedule
            
        except Exception as e:
            self.logger.error(f"Failed to save schedule: {e}")
            raise
    
    def find_by_id(self, schedule_id: str) -> Optional[Schedule]:
        """ID로 일정 조회"""
        try:
            doc = self.collection.find_one({'schedule_id': schedule_id})
            if doc:
                return self._doc_to_schedule(doc)
            return None
        except Exception as e:
            self.logger.error(f"Failed to find schedule by ID: {e}")
            return None
    
    def find_by_user_id(self, user_id: str) -> List[Schedule]:
        """사용자별 일정 조회"""
        try:
            cursor = self.collection.find(
                {'user_id': user_id, 'status': 'active'}
            ).sort('start_datetime', 1)
            
            return [self._doc_to_schedule(doc) for doc in cursor]
        except Exception as e:
            self.logger.error(f"Failed to find schedules by user: {e}")
            return []
    
    def find_by_user_and_date(self, user_id: str, target_date: date) -> List[Schedule]:
        """사용자별 특정 날짜 일정 조회"""
        try:
            start_datetime = datetime.combine(target_date, datetime.min.time())
            end_datetime = datetime.combine(target_date, datetime.max.time())
            
            cursor = self.collection.find({
                'user_id': user_id,
                'status': 'active',
                'start_datetime': {'$gte': start_datetime, '$lte': end_datetime}
            }).sort('start_datetime', 1)
            
            return [self._doc_to_schedule(doc) for doc in cursor]
        except Exception as e:
            self.logger.error(f"Failed to find schedules by date: {e}")
            return []
    
    def find_important_by_user(self, user_id: str) -> List[Schedule]:
        """사용자별 중요 일정 조회"""
        try:
            cursor = self.collection.find({
                'user_id': user_id,
                'status': 'active',
                'is_important': True
            }).sort('start_datetime', 1)
            
            return [self._doc_to_schedule(doc) for doc in cursor]
        except Exception as e:
            self.logger.error(f"Failed to find important schedules: {e}")
            return []
    
    def find_by_user_and_keyword(self, user_id: str, keyword: str) -> List[Schedule]:
        """사용자별 키워드로 일정 검색"""
        try:
            # MongoDB 텍스트 검색을 위한 정규식 패턴 생성
            regex_pattern = f".*{keyword}.*"
            
            # 제목, 설명, 카테고리에서 키워드 검색
            cursor = self.collection.find({
                'user_id': user_id,
                'status': 'active',
                '$or': [
                    {'title': {'$regex': regex_pattern, '$options': 'i'}},
                    {'description': {'$regex': regex_pattern, '$options': 'i'}},
                    {'category': {'$regex': regex_pattern, '$options': 'i'}}
                ]
            }).sort('start_datetime', 1)
            
            schedules = [self._doc_to_schedule(doc) for doc in cursor]
            self.logger.info(f"Found {len(schedules)} schedules for keyword '{keyword}'")
            return schedules
            
        except Exception as e:
            self.logger.error(f"Failed to find schedules by keyword: {e}")
            return []
    
    def update(self, schedule: Schedule) -> Schedule:
        """일정 수정"""
        schedule.updated_at = datetime.now()
        return self.save(schedule)
    
    def delete(self, schedule_id: str) -> bool:
        """일정 삭제"""
        try:
            result = self.collection.delete_one({'schedule_id': schedule_id})
            return result.deleted_count > 0
        except Exception as e:
            self.logger.error(f"Failed to delete schedule: {e}")
            return False
    
    def delete_by_user_and_title(self, user_id: str, title: str) -> bool:
        """사용자별 제목으로 일정 삭제"""
        try:
            result = self.collection.delete_one({
                'user_id': user_id,
                'title': {'$regex': title, '$options': 'i'},
                'status': 'active'
            })
            return result.deleted_count > 0
        except Exception as e:
            self.logger.error(f"Failed to delete schedule by title: {e}")
            return False
    
    def _doc_to_schedule(self, doc: dict) -> Schedule:
        """MongoDB 문서를 Schedule 엔티티로 변환"""
        return Schedule(
            id=doc.get('schedule_id'),
            user_id=doc['user_id'],
            title=doc['title'],
            start_datetime=doc['start_datetime'],
            category=doc.get('category', '일반'),
            is_important=doc.get('is_important', False),
            location=doc.get('location'),
            description=doc.get('description'),
            status=doc.get('status', 'active'),
            created_at=doc.get('created_at'),
            updated_at=doc.get('updated_at')
        )
    
    def _is_valid_object_id(self, id_str: str) -> bool:
        """ObjectId 유효성 검사"""
        try:
            ObjectId(id_str)
            return True
        except:
            return False
