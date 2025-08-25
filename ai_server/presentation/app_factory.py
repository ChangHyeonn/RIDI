#!/usr/bin/env python3
"""
Flask Application Factory
Flask 애플리케이션 팩토리 (Clean Architecture)
"""

from flask import Flask
from flask_cors import CORS

from shared.logging.logger import LoggerFactory
from shared.config.settings import AppSettings
from shared.container import container
from presentation.api.v1.text_controller import text_bp
from presentation.api.v1.sync_controller import sync_bp, init_sync_controller
from presentation.middleware.request_logging import RequestLoggingMiddleware


def create_app(settings: AppSettings = None) -> Flask:
    """Flask 애플리케이션 생성"""
    
    # 설정 로드
    if settings is None:
        settings = AppSettings()
    
    # 로깅 초기화
    LoggerFactory.setup_logging()
    logger = LoggerFactory.get_logger(__name__)
    
    # Flask 앱 생성
    app = Flask(__name__)
    app.config['SECRET_KEY'] = 'your-secret-key-here'  # 프로덕션에서는 환경변수 사용
    
    # CORS 설정
    CORS(app, 
         origins=settings.server.allowed_origins,
         methods=['GET', 'POST', 'PUT', 'DELETE'],
         allow_headers=['Content-Type', 'Authorization'])
    
    # 의존성 컨테이너 설정
    _configure_dependencies(settings)
    
    # 요청 로깅 미들웨어 등록
    request_logging = RequestLoggingMiddleware()
    request_logging.init_app(app)
    
    # 블루프린트 등록
    app.register_blueprint(text_bp, url_prefix='/api/v1')
    app.register_blueprint(sync_bp, url_prefix='/api/v1')
    
    # 글로벌 에러 핸들러
    @app.errorhandler(Exception)
    def handle_exception(e):
        logger.error(f"Unhandled exception: {e}")
        return {'error': 'Internal server error'}, 500
    
    logger.info("Flask application created successfully")
    return app


def _configure_dependencies(settings: AppSettings):
    """의존성 주입 설정"""
    
    # LLM Service 등록
    from infrastructure.external.llm.openai_llm_service import OpenAILLMService
    from core.interfaces.services.llm_service import ILLMService
    
    llm_service = OpenAILLMService(settings.llm)
    container.register_instance(ILLMService, llm_service)
    
    # Repository 등록
    from core.interfaces.repositories.schedule_repository import IScheduleRepository
    
    if settings.database.engine == 'mongodb':
        from infrastructure.repositories.mongodb_schedule_repository import MongoDBScheduleRepository
        repository = MongoDBScheduleRepository(settings.database)
    else:
        from infrastructure.repositories.memory_schedule_repository import MemoryScheduleRepository
        repository = MemoryScheduleRepository()
    
    container.register_instance(IScheduleRepository, repository)
    
    # Use Cases 등록
    from core.usecases.schedule.add_schedule_usecase import AddScheduleUseCase
    from core.usecases.schedule.get_schedule_usecase import GetScheduleUseCase
    from core.usecases.schedule.delete_schedule_usecase import DeleteScheduleUseCase
    from core.usecases.text_processing.process_text_usecase import ProcessTextUseCase
    
    container.register_singleton(AddScheduleUseCase, AddScheduleUseCase)
    container.register_singleton(GetScheduleUseCase, GetScheduleUseCase)
    container.register_singleton(DeleteScheduleUseCase, DeleteScheduleUseCase)
    container.register_singleton(ProcessTextUseCase, ProcessTextUseCase)
    
    # 동기화 컨트롤러 초기화
    add_schedule_usecase = container.get(AddScheduleUseCase)
    get_schedule_usecase = container.get(GetScheduleUseCase)
    delete_schedule_usecase = container.get(DeleteScheduleUseCase)
    init_sync_controller(get_schedule_usecase, add_schedule_usecase, delete_schedule_usecase)
