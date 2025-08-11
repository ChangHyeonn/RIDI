#!/usr/bin/env python3
"""
Schedule Repository Layer
MongoDB 및 In-Memory 저장소 구현
"""

from __future__ import annotations

from typing import Dict, Any, List, Optional
from datetime import datetime, date
import logging

try:
    from pymongo import MongoClient
    from bson import ObjectId
except Exception:  # pragma: no cover - optional at runtime
    MongoClient = None
    ObjectId = None


class BaseScheduleRepository:
    """일정 저장소 인터페이스"""

    def add_schedule(self, user_id: str, schedule_data: Dict[str, Any]) -> Dict[str, Any]:
        raise NotImplementedError

    def delete_schedule(self, user_id: str, schedule_id: str) -> Dict[str, Any]:
        raise NotImplementedError

    def get_schedules_by_date(self, user_id: str, target_date: str) -> List[Dict[str, Any]]:
        raise NotImplementedError

    def find_schedules(self, user_id: str, title: Optional[str] = None,
                        date_str: Optional[str] = None, time_str: Optional[str] = None) -> List[Dict[str, Any]]:
        raise NotImplementedError


class InMemoryScheduleRepository(BaseScheduleRepository):
    """메모리 기반 일정 저장소 (기본/개발용)"""

    def __init__(self) -> None:
        from collections import defaultdict
        self.logger = logging.getLogger(__name__)
        self.schedules = defaultdict(list)  # user_id -> List[schedule]

    def add_schedule(self, user_id: str, schedule_data: Dict[str, Any]) -> Dict[str, Any]:
        schedule_id = f"schedule_{datetime.now().timestamp()}"
        schedule = {
            'id': schedule_id,
            'user_id': user_id,
            'data': schedule_data,
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat()
        }
        self.schedules[user_id].append(schedule)
        return {
            'success': True,
            'schedule_id': schedule_id,
            'schedule': schedule_data,
            'message': '일정이 성공적으로 추가되었습니다.'
        }

    def delete_schedule(self, user_id: str, schedule_id: str) -> Dict[str, Any]:
        user_schedules = self.schedules[user_id]
        for s in list(user_schedules):
            if s.get('id') == schedule_id:
                user_schedules.remove(s)
                return {
                    'success': True,
                    'message': '일정이 성공적으로 삭제되었습니다.',
                    'deleted_schedule': s.get('data', {})
                }
        return {'success': False, 'error': '해당 일정을 찾을 수 없습니다.'}

    def get_schedules_by_date(self, user_id: str, target_date: str) -> List[Dict[str, Any]]:
        results: List[Dict[str, Any]] = []
        for s in self.schedules[user_id]:
            dt = (s.get('data', {}) or {}).get('datetime')
            if not dt:
                continue
            try:
                if dt.split(' ')[0] == target_date:
                    results.append(s)
            except Exception:
                continue
        return results

    def find_schedules(self, user_id: str, title: Optional[str] = None,
                        date_str: Optional[str] = None, time_str: Optional[str] = None) -> List[Dict[str, Any]]:
        results: List[Dict[str, Any]] = []
        for s in self.schedules[user_id]:
            data = s.get('data', {})
            t_ok = True if not title else (title in (data.get('title') or ''))
            dt = data.get('datetime') or ''
            parts = dt.split(' ')
            d_ok = True if not date_str else (len(parts) > 0 and parts[0] == date_str)
            tm_ok = True if not time_str else (len(parts) > 1 and parts[1] == time_str)
            if t_ok and d_ok and tm_ok:
                results.append(s)
        return results


class MongoDBScheduleRepository(BaseScheduleRepository):
    """MongoDB 기반 일정 저장소 (NoSQL)"""

    def __init__(self, connection_string: str = "mongodb://localhost:27017/", 
                 db_name: str = "ridi_ai") -> None:
        self.logger = logging.getLogger(__name__)
        if MongoClient is None:
            raise RuntimeError("PyMongo가 설치되어 있지 않습니다. requirements에 pymongo를 추가하세요.")
        
        self.client = MongoClient(connection_string)
        self.db = self.client[db_name]
        self.schedules = self.db.schedules
        self.users = self.db.users
        
        # 인덱스 생성
        self._ensure_indexes()
    
    def _ensure_indexes(self) -> None:
        """MongoDB 인덱스 생성"""
        try:
            # 사용자별 일정 조회를 위한 인덱스
            self.schedules.create_index([("user_id", 1), ("start_dt", 1)])
            # 제목 검색을 위한 인덱스
            self.schedules.create_index([("user_id", 1), ("title", "text")])
            # 카테고리별 조회를 위한 인덱스
            self.schedules.create_index([("user_id", 1), ("category", 1)])
            # 상태별 조회를 위한 인덱스
            self.schedules.create_index([("status", 1)])
        except Exception as e:
            self.logger.warning(f"인덱스 생성 중 오류: {e}")

    def add_schedule(self, user_id: str, schedule_data: Dict[str, Any]) -> Dict[str, Any]:
        """일정 추가"""
        try:
            # datetime 문자열을 datetime 객체로 변환
            datetime_str = schedule_data.get('datetime')
            if datetime_str:
                try:
                    if 'T' in datetime_str:
                        # ISO 형식: "2024-01-20T14:00"
                        start_dt = datetime.fromisoformat(datetime_str.replace('T', ' '))
                    else:
                        # 일반 형식: "2024-01-20 14:00"
                        start_dt = datetime.strptime(datetime_str, "%Y-%m-%d %H:%M")
                except ValueError:
                    # 변환 실패 시 문자열 그대로 저장
                    start_dt = datetime_str
            else:
                start_dt = None
            
            # MongoDB 문서 구조
            schedule_doc = {
                'user_id': user_id,
                'title': schedule_data.get('title'),
                'start_dt': start_dt,
                'category': schedule_data.get('category', '일반'),
                'priority': schedule_data.get('priority', 'not_important'),
                'location': schedule_data.get('location'),
                'description': schedule_data.get('description'),
                'source': 'voice',
                'status': 'active',
                'created_at': datetime.now(),
                'updated_at': datetime.now()
            }
            
            result = self.schedules.insert_one(schedule_doc)
            schedule_id = str(result.inserted_id)
            
            return {
                'success': True,
                'schedule_id': schedule_id,
                'schedule': schedule_data,
                'message': '일정이 성공적으로 추가되었습니다.'
            }
        except Exception as e:
            self.logger.error(f"일정 추가 실패: {e}")
            return {
                'success': False,
                'error': f'일정 추가 중 오류가 발생했습니다: {str(e)}'
            }

    def delete_schedule(self, user_id: str, schedule_id: str) -> Dict[str, Any]:
        """일정 삭제"""
        try:
            # ObjectId로 변환
            if not ObjectId.is_valid(schedule_id):
                return {'success': False, 'error': '잘못된 일정 ID입니다.'}
            
            object_id = ObjectId(schedule_id)
            result = self.schedules.delete_one({
                '_id': object_id,
                'user_id': user_id
            })
            
            if result.deleted_count == 0:
                return {'success': False, 'error': '해당 일정을 찾을 수 없습니다.'}
            
            return {'success': True, 'message': '일정이 성공적으로 삭제되었습니다.'}
        except Exception as e:
            self.logger.error(f"일정 삭제 실패: {e}")
            return {
                'success': False,
                'error': f'일정 삭제 중 오류가 발생했습니다: {str(e)}'
            }

    def get_schedules_by_date(self, user_id: str, target_date: str) -> List[Dict[str, Any]]:
        """특정 날짜 일정 조회"""
        try:
            # 날짜 범위 쿼리 (target_date의 00:00:00 ~ 23:59:59)
            start_datetime = datetime.strptime(f"{target_date} 00:00:00", "%Y-%m-%d %H:%M:%S")
            end_datetime = datetime.strptime(f"{target_date} 23:59:59", "%Y-%m-%d %H:%M:%S")
            
            cursor = self.schedules.find({
                'user_id': user_id,
                'start_dt': {'$gte': start_datetime, '$lte': end_datetime},
                'status': 'active'
            }).sort('start_dt', 1)
            
            results = []
            for doc in cursor:
                # 표준화된 구조로 변환
                results.append({
                    'id': str(doc['_id']),
                    'user_id': doc['user_id'],
                    'data': {
                        'title': doc['title'],
                        'datetime': doc['start_dt'].strftime('%Y-%m-%d %H:%M'),
                        'category': doc.get('category', '일반'),
                        'priority': doc.get('priority', 'not_important'),
                        'location': doc.get('location'),
                        'description': doc.get('description')
                    }
                })
            
            return results
        except Exception as e:
            self.logger.error(f"날짜별 일정 조회 실패: {e}")
            return []

    def find_schedules(self, user_id: str, title: Optional[str] = None,
                        date_str: Optional[str] = None, time_str: Optional[str] = None) -> List[Dict[str, Any]]:
        """일정 검색 (제목/날짜/시간)"""
        try:
            query = {'user_id': user_id, 'status': 'active'}
            
            # 제목 검색
            if title:
                query['title'] = {'$regex': title, '$options': 'i'}
            
            # 날짜 검색
            if date_str:
                try:
                    start_datetime = datetime.strptime(f"{date_str} 00:00:00", "%Y-%m-%d %H:%M:%S")
                    end_datetime = datetime.strptime(f"{date_str} 23:59:59", "%Y-%m-%d %H:%M:%S")
                    query['start_dt'] = {'$gte': start_datetime, '$lte': end_datetime}
                except ValueError:
                    # 날짜 형식 오류 시 제목으로만 검색
                    pass
            
            # 시간 검색
            if time_str and date_str:
                try:
                    start_time = datetime.strptime(f"{date_str} {time_str}:00", "%Y-%m-%d %H:%M:%S")
                    end_time = datetime.strptime(f"{date_str} {time_str}:59", "%Y-%m-%d %H:%M:%S")
                    query['start_dt'] = {'$gte': start_time, '$lte': end_time}
                except ValueError:
                    # 시간 형식 오류 시 날짜로만 검색
                    pass
            
            cursor = self.schedules.find(query).sort('start_dt', -1).limit(50)
            
            results = []
            for doc in cursor:
                results.append({
                    'id': str(doc['_id']),
                    'user_id': doc['user_id'],
                    'data': {
                        'title': doc['title'],
                        'datetime': doc['start_dt'].strftime('%Y-%m-%d %H:%M')
                    }
                })
            
            return results
        except Exception as e:
            self.logger.error(f"일정 검색 실패: {e}")
            return []