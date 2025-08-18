#!/usr/bin/env python3
"""
Text Processing API Controller
텍스트 처리 API 컨트롤러
"""

from flask import Blueprint, request, jsonify
from typing import Dict, Any

from shared.logging.logger import LoggerFactory
from shared.container import container
from core.entities.text_request import TextRequest
from core.usecases.text_processing.process_text_usecase import ProcessTextUseCase
from presentation.dto.requests import ProcessTextRequestDTO
from presentation.dto.responses import ProcessTextResponseDTO, APIResponseDTO


text_bp = Blueprint('text', __name__)
logger = LoggerFactory.get_logger(__name__)


@text_bp.route('/process_text', methods=['POST'])
def process_text():
    """텍스트 처리 엔드포인트"""
    try:
        # 1. 요청 데이터 검증
        if not request.is_json:
            return jsonify(APIResponseDTO(
                success=False,
                error="Content-Type must be application/json"
            ).to_dict()), 400
        
        data = request.get_json() or {}
        request_dto = ProcessTextRequestDTO.from_dict(data)
        
        if not request_dto.is_valid():
            return jsonify(APIResponseDTO(
                success=False,
                error="텍스트와 사용자 ID가 필요합니다."
            ).to_dict()), 400
        
        # 2. Use Case 실행
        use_case = container.get(ProcessTextUseCase)
        text_request = TextRequest(
            text=request_dto.text,
            user_id=request_dto.user_id
        )
        
        result = use_case.execute(text_request)
        
        # 3. 응답 생성
        response_dto = ProcessTextResponseDTO.from_processing_result(result)
        
        if result.success:
            return jsonify(response_dto.to_dict()), 200
        else:
            return jsonify(response_dto.to_dict()), 400
            
    except Exception as e:
        logger.error(f"Text processing API error: {e}")
        return jsonify(APIResponseDTO(
            success=False,
            error="서버 내부 오류가 발생했습니다."
        ).to_dict()), 500


@text_bp.route('/health', methods=['GET'])
def health_check():
    """헬스체크 엔드포인트"""
    try:
        from datetime import datetime
        import time
        
        # 간단한 헬스체크
        details = {}
        if request.args.get('details') == 'true':
            # LLM 서비스 상태 확인
            try:
                from core.interfaces.services.llm_service import ILLMService
                llm_service = container.get(ILLMService)
                model_info = llm_service.get_model_info()
                details['llm'] = {
                    'status': 'available',
                    'provider': model_info.get('provider')
                }
            except Exception as e:
                details['llm'] = {
                    'status': 'error',
                    'error': str(e)
                }
        
        response = {
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'service': 'AI Text Processing Server',
            'version': '2.0.0'
        }
        
        if details:
            response['details'] = details
        
        return jsonify(response), 200
        
    except Exception as e:
        logger.error(f"Health check error: {e}")
        return jsonify({
            'status': 'error',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500


# 에러 핸들러
@text_bp.errorhandler(400)
def bad_request(error):
    """잘못된 요청 에러 핸들러"""
    return jsonify(APIResponseDTO(
        success=False,
        error="잘못된 요청입니다."
    ).to_dict()), 400


@text_bp.errorhandler(404)
def not_found(error):
    """찾을 수 없음 에러 핸들러"""
    return jsonify(APIResponseDTO(
        success=False,
        error="요청한 리소스를 찾을 수 없습니다."
    ).to_dict()), 404


@text_bp.errorhandler(500)
def internal_error(error):
    """내부 서버 에러 핸들러"""
    logger.error(f"Internal server error: {error}")
    return jsonify(APIResponseDTO(
        success=False,
        error="서버 내부 오류가 발생했습니다."
    ).to_dict()), 500
