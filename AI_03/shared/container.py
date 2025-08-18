#!/usr/bin/env python3
"""
Dependency Injection Container
의존성 주입 컨테이너 - Clean Architecture의 핵심
"""

from typing import Dict, Any, Type, TypeVar, Callable, Optional
import inspect

T = TypeVar('T')


class DIContainer:
    """간단한 의존성 주입 컨테이너"""
    
    def __init__(self):
        self._services: Dict[str, Any] = {}
        self._factories: Dict[str, Callable] = {}
        self._singletons: Dict[str, Any] = {}
    
    def register_singleton(self, interface: Type[T], implementation: Type[T], name: Optional[str] = None):
        """싱글톤으로 서비스 등록"""
        key = name or interface.__name__
        self._factories[key] = implementation
    
    def register_transient(self, interface: Type[T], implementation: Type[T], name: Optional[str] = None):
        """일시적 인스턴스로 서비스 등록"""
        key = name or interface.__name__
        self._services[key] = implementation
    
    def register_instance(self, interface: Type[T], instance: T, name: Optional[str] = None):
        """인스턴스 직접 등록"""
        key = name or interface.__name__
        self._singletons[key] = instance
    
    def get(self, interface: Type[T], name: Optional[str] = None) -> T:
        """서비스 인스턴스 반환"""
        key = name or interface.__name__
        
        # 싱글톤 인스턴스 확인
        if key in self._singletons:
            return self._singletons[key]
        
        # 싱글톤 팩토리 확인
        if key in self._factories:
            instance = self._create_instance(self._factories[key])
            self._singletons[key] = instance
            return instance
        
        # 일시적 인스턴스 확인
        if key in self._services:
            return self._create_instance(self._services[key])
        
        raise ValueError(f"Service not registered: {key}")
    
    def _create_instance(self, cls: Type[T]) -> T:
        """인스턴스 생성 (의존성 자동 주입)"""
        signature = inspect.signature(cls.__init__)
        dependencies = {}
        
        for param_name, param in signature.parameters.items():
            if param_name == 'self':
                continue
                
            if param.annotation != inspect.Parameter.empty:
                dependencies[param_name] = self.get(param.annotation)
        
        return cls(**dependencies)


# 전역 컨테이너 인스턴스
container = DIContainer()
