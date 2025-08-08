#!/usr/bin/env python3
"""
Schedule Repository Layer
MySQL 및 In-Memory 저장소 구현
"""

from __future__ import annotations

from typing import Dict, Any, List, Optional
from datetime import datetime, date
import logging

try:
    import pymysql  # type: ignore
except Exception:  # pragma: no cover - optional at runtime
    pymysql = None


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


class MySQLScheduleRepository(BaseScheduleRepository):
    """MySQL 기반 일정 저장소 (운영용)"""

    def __init__(self, host: str, port: int, user: str, password: str, db: str, autoinit: bool = True) -> None:
        self.logger = logging.getLogger(__name__)
        if pymysql is None:
            raise RuntimeError("PyMySQL이 설치되어 있지 않습니다. requirements에 PyMySQL를 추가하세요.")
        self.conn_params = dict(host=host, port=port, user=user, password=password, database=db, charset='utf8mb4')
        if autoinit:
            self._ensure_tables()

    def _connect(self):
        return pymysql.connect(**self.conn_params, cursorclass=pymysql.cursors.DictCursor, autocommit=True)

    def _ensure_tables(self) -> None:
        sql_users = (
            """
            CREATE TABLE IF NOT EXISTS users (
              id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
              external_id VARCHAR(64) UNIQUE,
              name VARCHAR(100),
              locale VARCHAR(10) NOT NULL DEFAULT 'ko-KR',
              timezone VARCHAR(64) NOT NULL DEFAULT 'Asia/Seoul',
              created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
            """
        )
        sql_schedules = (
            """
            CREATE TABLE IF NOT EXISTS schedules (
              id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
              user_id BIGINT UNSIGNED NOT NULL,
              title VARCHAR(200) NOT NULL,
              start_dt DATETIME NOT NULL,
              end_dt DATETIME NULL,
              all_day TINYINT(1) NOT NULL DEFAULT 0,
              category VARCHAR(20) NOT NULL DEFAULT '일반',
              priority VARCHAR(20) NOT NULL DEFAULT 'not_important',
              location TEXT NULL,
              description TEXT NULL,
              source VARCHAR(30) DEFAULT 'voice',
              status VARCHAR(20) NOT NULL DEFAULT 'active',
              created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
              updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
              INDEX idx_user_date (user_id, start_dt)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
            """
        )
        with self._connect() as conn:
            with conn.cursor() as cur:
                cur.execute(sql_users)
                cur.execute(sql_schedules)

    def add_schedule(self, user_id: str, schedule_data: Dict[str, Any]) -> Dict[str, Any]:
        start_dt = schedule_data.get('datetime')  # 'YYYY-MM-DD HH:MM'
        title = schedule_data.get('title')
        category = schedule_data.get('category', '일반')
        priority = schedule_data.get('priority', 'not_important')
        location = schedule_data.get('location')
        description = schedule_data.get('description')
        source = 'voice'
        with self._connect() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO schedules (user_id, title, start_dt, category, priority, location, description, source)
                    VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
                    """,
                    (user_id, title, start_dt, category, priority, location, description, source)
                )
                schedule_id = cur.lastrowid
        return {
            'success': True,
            'schedule_id': str(schedule_id),
            'schedule': schedule_data,
            'message': '일정이 성공적으로 추가되었습니다.'
        }

    def delete_schedule(self, user_id: str, schedule_id: str) -> Dict[str, Any]:
        with self._connect() as conn:
            with conn.cursor() as cur:
                cur.execute("DELETE FROM schedules WHERE id=%s AND user_id=%s", (schedule_id, user_id))
                if cur.rowcount == 0:
                    return {'success': False, 'error': '해당 일정을 찾을 수 없습니다.'}
        return {'success': True, 'message': '일정이 성공적으로 삭제되었습니다.'}

    def get_schedules_by_date(self, user_id: str, target_date: str) -> List[Dict[str, Any]]:
        sql = (
            "SELECT id, title, DATE_FORMAT(start_dt, '%Y-%m-%d %H:%i') AS datetime, category, priority, location, description "
            "FROM schedules WHERE user_id=%s AND DATE(start_dt)=%s AND status='active' ORDER BY start_dt"
        )
        with self._connect() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, (user_id, target_date))
                rows = cur.fetchall()
                # 표준화된 구조로 변환
                results: List[Dict[str, Any]] = []
                for r in rows:
                    results.append({
                        'id': str(r['id']),
                        'user_id': user_id,
                        'data': {
                            'title': r['title'],
                            'datetime': r['datetime'],
                            'category': r['category'],
                            'priority': r['priority'],
                            'location': r['location'],
                            'description': r['description']
                        }
                    })
                return results

    def find_schedules(self, user_id: str, title: Optional[str] = None,
                        date_str: Optional[str] = None, time_str: Optional[str] = None) -> List[Dict[str, Any]]:
        where = ["user_id=%s", "status='active'"]
        params: List[Any] = [user_id]
        if title:
            where.append("title LIKE CONCAT('%', %s, '%')")
            params.append(title)
        if date_str:
            where.append("DATE(start_dt)=%s")
            params.append(date_str)
        if time_str:
            where.append("DATE_FORMAT(start_dt, '%H:%i')=%s")
            params.append(time_str)
        sql = (
            "SELECT id, title, DATE_FORMAT(start_dt, '%Y-%m-%d %H:%i') AS datetime "
            f"FROM schedules WHERE {' AND '.join(where)} ORDER BY start_dt DESC LIMIT 50"
        )
        with self._connect() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, params)
                rows = cur.fetchall()
                results: List[Dict[str, Any]] = []
                for r in rows:
                    results.append({
                        'id': str(r['id']),
                        'user_id': user_id,
                        'data': {
                            'title': r['title'],
                            'datetime': r['datetime']
                        }
                    })
                return results


