import whisper
import torch
import numpy as np
import logging
import os
import re
import tempfile
import soundfile as sf
from typing import Optional, Union, List
from pathlib import Path
import librosa
import noisereduce as nr

class WhisperSTT:
    def __init__(self, model_name="small", device: Optional[str] = None):
        self.model_name = model_name
        self.device = self._get_device(device)
        
        self._setup_logging()
        self._load_model()
        self._setup_korean_optimization()
        self._setup_audio_preprocessing()
        
        self.logger.info(f"Whisper STT initialized successfully on {self.device}")
    
    def _get_device(self, device: Optional[str] = None) -> str:
        """사용 가능한 최적의 device 선택"""
        if device:
            return device
        
        # CUDA 확인 (가장 빠름)
        if torch.cuda.is_available():
            return "cuda"
        # CPU (MPS 호환성 문제로 인해 기본값)
        else:
            return "cpu"
    
    def _setup_logging(self):
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
    
    def _load_model(self):
        self.logger.info(f"Loading Whisper model: {self.model_name} on {self.device}")
        self.model = whisper.load_model(self.model_name, device=self.device)
        self.logger.info("Model loaded successfully")
    
    def _setup_korean_optimization(self):
        self.default_language = "ko"
        self.korean_optimization = True
    
    def _setup_audio_preprocessing(self):
        """음성 전처리 설정 (속도 최적화)"""
        self.preprocessing_config = {
            "noise_reduction": True,      # 잡음 제거
            "normalize_audio": True,      # 음성 정규화
            "remove_silence": True,       # 무음 구간 제거
            "sample_rate": 16000,         # 샘플링 레이트
            "noise_reduction_strength": 0.1,  # 잡음 제거 강도
        }
    
    def preprocess_audio(self, audio_path: Union[str, Path]) -> str:
        """
        음성 파일 전처리 (속도 최적화)
        
        Args:
            audio_path: 원본 음성 파일 경로
            
        Returns:
            str: 전처리된 음성 파일 경로
        """
        try:
            self.logger.info("음성 전처리 시작...")
            
            # 오디오 로드
            audio, sr = librosa.load(audio_path, sr=self.preprocessing_config["sample_rate"])
            
            # 1. 무음 구간 제거
            if self.preprocessing_config["remove_silence"]:
                audio = self._remove_silence(audio, sr)
            
            # 2. 잡음 제거
            if self.preprocessing_config["noise_reduction"]:
                audio = self._reduce_noise(audio, sr)
            
            # 3. 음성 정규화
            if self.preprocessing_config["normalize_audio"]:
                audio = self._normalize_audio(audio)
            
            # 전처리된 오디오를 임시 파일로 저장
            temp_path = tempfile.mktemp(suffix=".wav")
            sf.write(temp_path, audio, sr)
            
            self.logger.info("음성 전처리 완료")
            return temp_path
            
        except Exception as e:
            self.logger.error(f"음성 전처리 실패: {str(e)}")
            return audio_path  # 실패시 원본 파일 반환
    
    def _remove_silence(self, audio: np.ndarray, sr: int) -> np.ndarray:
        """무음 구간 제거"""
        try:
            # 무음 구간 감지 (임계값: -40dB)
            non_silent_intervals = librosa.effects.split(
                audio, 
                top_db=40,  # 40dB 이상의 소리만 유지
                frame_length=2048,
                hop_length=512
            )
            
            # 무음이 아닌 구간만 추출
            audio_parts = []
            for interval in non_silent_intervals:
                audio_parts.append(audio[interval[0]:interval[1]])
            
            if audio_parts:
                return np.concatenate(audio_parts)
            else:
                return audio  # 모든 구간이 무음인 경우 원본 반환
                
        except Exception as e:
            self.logger.warning(f"무음 제거 실패: {e}")
            return audio
    
    def _reduce_noise(self, audio: np.ndarray, sr: int) -> np.ndarray:
        """잡음 제거"""
        try:
            # noisereduce를 사용한 잡음 제거
            reduced_noise = nr.reduce_noise(
                y=audio,
                sr=sr,
                stationary=False,
                prop_decrease=self.preprocessing_config["noise_reduction_strength"]
            )
            return reduced_noise
        except Exception as e:
            self.logger.warning(f"잡음 제거 실패: {e}")
            return audio
    
    def _normalize_audio(self, audio: np.ndarray) -> np.ndarray:
        """음성 정규화"""
        try:
            # RMS 정규화
            rms = np.sqrt(np.mean(audio**2))
            if rms > 0:
                target_rms = 0.1
                audio = audio * (target_rms / rms)
            
            # 클리핑 방지
            audio = np.clip(audio, -1.0, 1.0)
            return audio
        except Exception as e:
            self.logger.warning(f"음성 정규화 실패: {e}")
            return audio
    
    def transcribe(self, audio_path: Union[str, Path], 
                   language: Optional[str] = None,
                   task: str = "transcribe",
                   use_preprocessing: bool = True) -> str:
        """
        음성 파일을 텍스트로 변환
        
        Args:
            audio_path: 음성 파일 경로
            language: 언어 코드 (기본값: 한국어)
            task: 작업 유형 (transcribe/translate)
            use_preprocessing: 전처리 사용 여부
            
        Returns:
            str: 변환된 텍스트
        """
        try:
            self._validate_audio_file(audio_path)
            
            # 전처리 적용
            processed_audio_path = audio_path
            if use_preprocessing:
                processed_audio_path = self.preprocess_audio(audio_path)
            
            # 언어 설정
            language = language or self.default_language
            
            # Whisper 모델로 변환
            result = self.model.transcribe(
                processed_audio_path,
                language=language,
                task=task,
                fp16=False if self.device == "cpu" else True,
                condition_on_previous_text=True,
                temperature=0.0
            )
            
            text = result["text"].strip()
            
            # 한국어 최적화 후처리
            if self.korean_optimization:
                text = self._post_process_korean(text)
            
            # 임시 파일 정리
            if use_preprocessing and processed_audio_path != audio_path:
                try:
                    os.remove(processed_audio_path)
                except:
                    pass
            
            return text
            
        except Exception as e:
            self.logger.error(f"Transcription failed: {str(e)}")
            raise
    
    def _validate_audio_file(self, audio_path: Union[str, Path]):
        """음성 파일 유효성 검사"""
        if not os.path.exists(audio_path):
            raise FileNotFoundError(f"Audio file not found: {audio_path}")
        
        # 지원하는 파일 형식 확인
        supported_formats = ['.wav', '.mp3', '.m4a', '.flac', '.ogg']
        file_ext = Path(audio_path).suffix.lower()
        
        if file_ext not in supported_formats:
            self.logger.warning(f"Unsupported audio format: {file_ext}")
    
    def transcribe_streaming(self, audio_chunks: List[np.ndarray], 
                           sample_rate: int = 16000,
                           language: Optional[str] = None) -> str:
        """
        실시간 스트리밍 음성 변환 (현재 미사용)
        """
        try:
            # 오디오 청크들을 하나로 합치기
            combined_audio = np.concatenate(audio_chunks)
            
            # 임시 파일로 저장
            temp_path = tempfile.mktemp(suffix=".wav")
            sf.write(temp_path, combined_audio, sample_rate)
            
            # 변환 실행
            result = self.transcribe(temp_path, language=language)
            
            # 임시 파일 정리
            try:
                os.remove(temp_path)
            except:
                pass
            
            return result
            
        except Exception as e:
            self.logger.error(f"Streaming transcription failed: {str(e)}")
            raise
    
    def _post_process_korean(self, text: str) -> str:
        """한국어 텍스트 후처리"""
        if not text:
            return text
        
        # 불필요한 공백 제거
        text = re.sub(r'\s+', ' ', text)
        text = text.strip()
        
        # 문장 끝 정리
        if text and not text.endswith(('.', '!', '?')):
            text += '.'
        
        return text
    
    def configure_preprocessing(self, **kwargs):
        """전처리 설정 변경"""
        self.preprocessing_config.update(kwargs)
        self.logger.info(f"Preprocessing configuration updated: {kwargs}")
    
    def get_preprocessing_info(self) -> dict:
        """전처리 설정 정보 반환"""
        return self.preprocessing_config.copy()
    
    def get_available_models(self) -> List[str]:
        """사용 가능한 모델 목록"""
        return ["tiny", "base", "small", "medium", "large"]
    
    def optimize_for_korean(self, enable: bool = True):
        """한국어 최적화 설정"""
        self.korean_optimization = enable
        self.logger.info(f"Korean optimization: {enable}")
    
    def change_model(self, model_name: str):
        """모델 변경"""
        if model_name in self.get_available_models():
            self.model_name = model_name
            self._load_model()
            self.logger.info(f"Model changed to: {model_name}")
        else:
            self.logger.error(f"Invalid model name: {model_name}")
    
    def get_model_info(self) -> dict:
        """모델 정보 반환"""
        return {
            "model_name": self.model_name,
            "device": self.device,
            "korean_optimization": self.korean_optimization,
            "preprocessing_enabled": True,
            "supported_languages": ["ko", "en", "ja", "zh", "es", "fr", "de", "it", "pt", "ru", "ar", "hi"],
            "features": {
                "real_time": True,
                "streaming": True,
                "noise_reduction": True,
                "silence_removal": True,
                "audio_normalization": True
            }
        }
    
    def __del__(self):
        """리소스 정리"""
        if hasattr(self, 'model'):
            del self.model