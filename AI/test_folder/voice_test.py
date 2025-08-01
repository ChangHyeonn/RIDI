#!/usr/bin/env python3
"""
Voice Chat Test - 음성 대화 파이프라인 테스트
음성 녹음 → AI 대화 → 음성 재생
"""

import os
import time
import wave
import pyaudio
import tempfile
from dotenv import load_dotenv
from voice_chat_pipeline import VoiceChatPipeline

class VoiceChatTest:
    """음성 대화 테스트 클래스"""
    
    def __init__(self, llm_type: str = None):
        # .env 파일 로드
        load_dotenv()
        
        self.pipeline = VoiceChatPipeline(llm_type=llm_type)
        self.audio_format = pyaudio.paInt16
        self.channels = 1
        self.rate = 16000
        self.chunk = 1024
        self.record_seconds = 5
        
        self.p = pyaudio.PyAudio()
    
    def record_audio(self, filename: str = "test_audio.wav"):
        """음성 녹음"""
        print(f"🎤 {self.record_seconds}초간 음성을 녹음합니다...")
        print("말씀해주세요!")
        
        stream = self.p.open(
            format=self.audio_format,
            channels=self.channels,
            rate=self.rate,
            input=True,
            frames_per_buffer=self.chunk
        )
        
        frames = []
        
        for i in range(0, int(self.rate / self.chunk * self.record_seconds)):
            data = stream.read(self.chunk)
            frames.append(data)
        
        print("✅ 녹음 완료!")
        
        stream.stop_stream()
        stream.close()
        
        # WAV 파일로 저장
        with wave.open(filename, 'wb') as wf:
            wf.setnchannels(self.channels)
            wf.setsampwidth(self.p.get_sample_size(self.audio_format))
            wf.setframerate(self.rate)
            wf.writeframes(b''.join(frames))
        
        return filename
    
    def play_audio(self, audio_data: bytes):
        """음성 재생"""
        print("🔊 AI 응답을 재생합니다...")
        
        # 임시 파일로 저장
        with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as tmp_file:
            tmp_file.write(audio_data)
            tmp_filename = tmp_file.name
        
        # WAV 파일 재생
        with wave.open(tmp_filename, 'rb') as wf:
            stream = self.p.open(
                format=self.p.get_format_from_width(wf.getsampwidth()),
                channels=wf.getnchannels(),
                rate=wf.getframerate(),
                output=True
            )
            
            data = wf.readframes(self.chunk)
            while data:
                stream.write(data)
                data = wf.readframes(self.chunk)
            
            stream.stop_stream()
            stream.close()
        
        # 임시 파일 삭제
        os.unlink(tmp_filename)
        print("✅ 재생 완료!")
    
    def chat_loop(self):
        """대화 루프"""
        print("🎤 음성 대화 시스템을 시작합니다!")
        print("종료하려면 '종료'라고 말씀하세요.")
        print("-" * 50)
        
        while True:
            try:
                # 음성 녹음
                audio_file = self.record_audio()
                
                # AI와 대화
                result = self.pipeline.chat_with_voice(audio_file)
                
                if result['success']:
                    print(f"\n👤 사용자: {result['user_message']}")
                    print(f"🤖 AI: {result['ai_response']}")
                    print(f"⏱️ 처리 시간: {result['processing_time']:.2f}초")
                    
                    # AI 응답 음성 재생
                    self.play_audio(result['audio_response'])
                    
                    # 종료 확인
                    if "종료" in result['user_message'] or "끝" in result['user_message']:
                        print("\n👋 대화를 종료합니다!")
                        break
                else:
                    print(f"❌ 오류: {result['error']}")
                
                print("-" * 50)
                
            except KeyboardInterrupt:
                print("\n👋 사용자가 중단했습니다!")
                break
            except Exception as e:
                print(f"❌ 예상치 못한 오류: {e}")
    
    def __del__(self):
        """리소스 정리"""
        if hasattr(self, 'p'):
            self.p.terminate()

def main():
    """메인 함수"""
    print("🎤 Voice Chat Test 시작!")
    
    # .env 파일에서 자동으로 모델 선택
    load_dotenv()
    llm_type = os.getenv('LLM_MODEL', 'gemini')
    print(f"📋 .env 파일에서 선택된 모델: {llm_type}")
    
    # 테스트 시작
    test = VoiceChatTest(llm_type=None)  # .env에서 자동으로 가져옴
    
    # 파이프라인 정보 출력
    info = test.pipeline.get_pipeline_info()
    print(f"\n📊 파이프라인 정보:")
    print(f"Device: {info['device']}")
    print(f"LLM Type: {info['llm_type']}")
    print(f"STT Model: {info['components']['stt']['model_name']}")
    print(f"TTS Model: {info['components']['tts']['model_name']}")
    print()
    
    # 대화 시작
    test.chat_loop()

if __name__ == "__main__":
    main() 