#!/usr/bin/env python3
"""
AI Server for Flutter App Integration
음성 기반 일정 관리 시스템의 AI 서버
"""

import os
import json
import logging
import tempfile
from datetime import datetime
from typing import Dict, Any
from flask import Flask, request, jsonify
from flask_cors import CORS

from Processor.voice_pipeline import VoicePipeline

class AIServer:
    def __init__(self, device: str = "auto", llm_type: str = "gemini"):
        self.device = self._get_device(device)
        self.llm_type = llm_type
        self._setup_logging()
        self._initialize_voice_pipeline()
        self.logger.info(f"AI Server initialized successfully on {self.device}")
    
    def _get_device(self, device: str) -> str:
        if device == "auto":
            import torch
            if torch.cuda.is_available():
                return "cuda"
            else:
                return "cpu"
        return device
    
    def _setup_logging(self):
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
    
    def _initialize_voice_pipeline(self):
        self.logger.info("Initializing Voice Pipeline...")
        
        llm_type = os.getenv('LLM_MODEL', self.llm_type)
        
        self.voice_pipeline = VoicePipeline(
            stt_model="small",
            llm_type=llm_type,  # "gpt" | "gemini"
            device=self.device
        )
        
        self.logger.info(f"Voice Pipeline initialized with LLM: {llm_type}")
    
    def process_voice_command(self, audio_file_path: str) -> Dict[str, Any]:
        """음성 명령 처리 파이프라인"""
        try:
            self.logger.info(f"Processing voice command from: {audio_file_path}")
            
            # Voice Pipeline을 통한 통합 처리
            result = self.voice_pipeline.process_voice_command(audio_file_path)
            
            self.logger.info(f"Pipeline processing completed: {result.get('success', False)}")
            return result
            
        except Exception as e:
            self.logger.error(f"Error processing voice command: {e}")
            return {
                "success": False,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }

app = Flask(__name__)
CORS(app) 

ai_server = None

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        "status": "healthy",
        "device": ai_server.device if ai_server else "not_initialized",
        "llm_type": ai_server.llm_type if ai_server else "not_initialized",
        "pipeline_info": ai_server.voice_pipeline.get_pipeline_info() if ai_server else None,
        "timestamp": datetime.now().isoformat()
    })

@app.route('/process_voice', methods=['POST'])
def process_voice():
    """음성 명령 처리 API"""
    try:
        if 'audio' not in request.files:
            return jsonify({"error": "No audio file provided"}), 400
        
        audio_file = request.files['audio']
        
        with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as tmp_file:
            audio_file.save(tmp_file.name)
            audio_path = tmp_file.name
        
        result = ai_server.process_voice_command(audio_path)
        
        os.unlink(audio_path)
        
        return jsonify(result)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/test', methods=['GET'])
def test_endpoint():
    """테스트용 엔드포인트"""
    return jsonify({
        "message": "AI Server is running!",
        "device": ai_server.device if ai_server else "not_initialized",
        "timestamp": datetime.now().isoformat()
    })

def main():
    """메인 함수"""
    global ai_server
    
    # AI 서버 초기화
    print("🚀 Initializing AI Server...")
    ai_server = AIServer(device="auto")
    
    # Flask 서버 시작
    print("🌐 Starting Flask server...")
    app.run(
        host='0.0.0.0',  # 모든 IP에서 접근 허용
        port=5000,        # 포트 5000
        debug=True        # 개발 모드
    )

if __name__ == "__main__":
    main() 