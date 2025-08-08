#!/usr/bin/env python3
"""
Unified Voice Pipeline Test
LLM 중심 통합 음성 파이프라인 테스트
"""

import os
import sys
import time
import tempfile
import wave
import threading
import signal
from pathlib import Path

# 프로젝트 루트를 Python 경로에 추가
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from Processor.unified_voice_pipeline import UnifiedVoicePipeline
from Config.settings import Settings

class UnifiedVoicePipelineTest:
    """LLM 중심 통합 음성 파이프라인 테스트 클래스"""
    
    def __init__(self):
        self.setup_components()
        self.setup_audio()
        self.recording = False
        self.recorded_frames = []
        self.running = True
        
    def setup_components(self):
        """통합 음성 파이프라인 초기화"""
        print("🤖 LLM 중심 통합 음성 파이프라인 초기화 중...")
        
        try:
            # 통합 파이프라인 초기화
            self.pipeline = UnifiedVoicePipeline(
                stt_model=Settings.STT_MODEL,
                llm_type=Settings.LLM_TYPE,
                device=Settings.get_device()
            )
            print("✅ 통합 음성 파이프라인 초기화 완료")
            
            # 파이프라인 정보 출력
            pipeline_info = self.pipeline.get_pipeline_info()
            print(f"📊 파이프라인 정보: {pipeline_info['pipeline_type']}")
            print(f"🔧 컴포넌트: STT={pipeline_info['components']['stt']['model_name']}, "
                  f"LLM={pipeline_info['components']['request_processor']['llm_model']['model_name']}, "
                  f"TTS={pipeline_info['components']['tts']['model_name']}")
            
        except Exception as e:
            print(f"❌ 통합 파이프라인 초기화 실패: {e}")
            self.pipeline = None
        
    def setup_audio(self):
        """오디오 설정"""
        try:
            import pyaudio
            self.audio = pyaudio.PyAudio()
            self.sample_rate = 16000
            self.chunk_size = 512  # 1024에서 512로 줄여서 메모리 사용량 감소
            self.channels = 1
            self.format = pyaudio.paInt16
            print("✅ 오디오 시스템 초기화 완료")
        except Exception as e:
            print(f"❌ 오디오 시스템 초기화 실패: {e}")
            self.audio = None
        
    def start_recording(self):
        """녹음 시작"""
        if self.recording or not self.audio:
            return
            
        try:
            self.recording = True
            self.recorded_frames = []
            
            print("🎤 녹음 시작! (Enter를 누르면 녹음 종료)")
            
            # 오디오 스트림 시작
            self.stream = self.audio.open(
                format=self.format,
                channels=self.channels,
                rate=self.sample_rate,
                input=True,
                frames_per_buffer=self.chunk_size
            )
            
            # 녹음 스레드 시작
            self.record_thread = threading.Thread(target=self._record_audio_thread)
            self.record_thread.daemon = True
            self.record_thread.start()
            
        except Exception as e:
            print(f"❌ 녹음 시작 실패: {e}")
            self.recording = False
        
    def stop_recording(self):
        """녹음 종료"""
        if not self.recording or not self.audio:
            return None
            
        try:
            self.recording = False
            
            # 스트림 종료
            if hasattr(self, 'stream'):
                self.stream.stop_stream()
                self.stream.close()
            
            # 스레드 대기
            if hasattr(self, 'record_thread'):
                self.record_thread.join(timeout=2.0)
            
            # 녹음된 데이터가 있는지 확인
            if not self.recorded_frames:
                print("⚠️  녹음된 데이터가 없습니다.")
                return None
            
            # 임시 파일로 저장
            temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.wav')
            with wave.open(temp_file.name, 'wb') as wf:
                wf.setnchannels(self.channels)
                wf.setsampwidth(self.audio.get_sample_size(self.format))
                wf.setframerate(self.sample_rate)
                wf.writeframes(b''.join(self.recorded_frames))
            
            print(f"✅ 녹음 완료! (총 {len(self.recorded_frames)} 프레임)")
            return temp_file.name
            
        except Exception as e:
            print(f"❌ 녹음 종료 실패: {e}")
            return None
    
    def _record_audio_thread(self):
        """녹음 스레드"""
        start_time = time.time()
        max_recording_time = 15  # 최대 15초 녹음 제한
        
        while self.recording:
            try:
                # 녹음 시간 제한 확인
                if time.time() - start_time > max_recording_time:
                    print("⏰ 최대 녹음 시간(15초)에 도달했습니다.")
                    self.recording = False
                    break
                
                data = self.stream.read(self.chunk_size, exception_on_overflow=False)
                self.recorded_frames.append(data)
            except Exception as e:
                print(f"⚠️  녹음 중 오류: {e}")
                break
    
    def process_voice_pipeline(self, audio_path):
        """LLM 중심 통합 음성 파이프라인 처리"""
        print("\n🔄 LLM 중심 통합 음성 파이프라인 처리 시작...")
        
        if not self.pipeline:
            print("❌ 통합 파이프라인이 초기화되지 않았습니다.")
            return None
        
        try:
            print("🎤 LLM 중심 음성 처리 중...")
            start_time = time.time()
            
            # 통합 파이프라인으로 처리
            result = self.pipeline.process_voice(audio_path)
            
            if not result.get('success'):
                print(f"❌ 처리 실패: {result.get('error', '알 수 없는 오류')}")
                return None
            
            processing_time = time.time() - start_time
            print(f"✅ LLM 중심 처리 완료 (소요시간: {processing_time:.2f}초)")
            
            # 결과 분석
            processing_result = result.get('processing_result', {})
            analysis = processing_result.get('analysis', {})
            result_data = processing_result.get('result', {})
            
            print(f"📊 분석 결과:")
            print(f"  - 카테고리: {analysis.get('category', 'unknown')}")
            print(f"  - 신뢰도: {analysis.get('confidence', 0.0):.2f}")
            print(f"  - 액션: {result_data.get('action', 'unknown')}")
            print(f"  - 메시지: {result_data.get('message', 'N/A')}")
            
            return {
                'user_text': result.get('user_text', ''),
                'analysis': analysis,
                'result': result_data,
                'audio_data': result.get('audio_response'),
                'timing': {
                    'total': processing_time
                }
            }
            
        except Exception as e:
            print(f"❌ 음성 처리 중 오류: {e}")
            return None
    
    def play_audio(self, audio_data):
        """음성 재생"""
        if not audio_data or not self.audio:
            print("⚠️  재생할 오디오가 없습니다.")
            return
            
        print("🔊 음성 재생 중...")
        
        try:
            # 메모리 정리
            import gc
            gc.collect()
            
            # 임시 MP3 파일로 저장
            temp_mp3 = tempfile.NamedTemporaryFile(delete=False, suffix='.mp3')
            temp_mp3.write(audio_data)
            temp_mp3.close()
            
            # 시스템 명령어로 MP3 재생 (macOS) - 더 안전한 방법
            import subprocess
            try:
                # timeout 설정으로 안전하게 재생
                subprocess.run(['afplay', temp_mp3.name], check=True, timeout=30)
                print("✅ 음성 재생 완료")
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
                print(f"⚠️  afplay 명령어 실패: {e}")
                print("ℹ️  오디오 파일은 생성되었지만 재생할 수 없습니다.")
            
            # 임시 MP3 파일 삭제
            if os.path.exists(temp_mp3.name):
                os.unlink(temp_mp3.name)
            
            # 재생 후 메모리 정리
            gc.collect()
            
        except Exception as e:
            print(f"❌ 음성 재생 실패: {e}")
            # 임시 파일 정리
            if 'temp_mp3' in locals() and os.path.exists(temp_mp3.name):
                os.unlink(temp_mp3.name)
    
    def run_interactive_test(self):
        """대화형 테스트 실행"""
        print("🎯 음성 파이프라인 테스트 시작")
        print("=" * 50)
        print("📋 사용법:")
        print("  - Enter를 누르면 녹음 시작")
        print("  - 다시 Enter를 누르면 녹음 종료 및 처리")
        print("  - 'q'를 입력하면 프로그램 종료")
        print("=" * 50)
        
        if not self.audio:
            print("⚠️  오디오 시스템을 사용할 수 없습니다.")
            return
        
        print("🎤 대화형 테스트 시작!")
        
        try:
            # 메인 루프
            while self.running:
                print("\n🎤 Enter를 눌러 녹음을 시작하세요...")
                input()  # Enter 대기
                
                if not self.recording:
                    # 녹음 시작
                    self.start_recording()
                    print("⏸️  Enter를 눌러 녹음을 종료하세요...")
                    input()  # Enter 대기
                    
                    # 녹음 종료
                    audio_path = self.stop_recording()
                    if audio_path:
                        # 파이프라인 처리
                        result = self.process_voice_pipeline(audio_path)
                        if result and result['audio_data']:
                            self.play_audio(result['audio_data'])
                        
                        # 임시 파일 정리
                        if os.path.exists(audio_path):
                            os.unlink(audio_path)
                else:
                    print("⚠️  이미 녹음 중입니다.")
                
                # 종료 확인
                print("\n계속하려면 Enter, 종료하려면 'q'를 입력하세요: ", end="")
                choice = input().strip().lower()
                if choice == 'q':
                    print("🛑 프로그램을 종료합니다.")
                    break
                
        except KeyboardInterrupt:
            print("\n🛑 프로그램이 중단되었습니다.")
        except Exception as e:
            print(f"❌ 대화형 테스트 실패: {e}")
    
    def run_batch_test(self, test_phrases):
        """배치 테스트 실행"""
        print("🎯 배치 테스트 시작")
        print("=" * 50)
        
        if not self.tts:
            print("❌ TTS가 초기화되지 않아 배치 테스트를 실행할 수 없습니다.")
            return
        
        results = []
        
        for i, phrase in enumerate(test_phrases, 1):
            print(f"\n📝 테스트 {i}/{len(test_phrases)}: {phrase}")
            
            try:
                # LLM 처리
                if self.llm:
                    response = self.llm.generate_response(phrase)
                else:
                    response = f"입력하신 내용은 '{phrase}'입니다."
                
                print(f"🤖 LLM 응답: {response}")
                
                # TTS 처리
                audio_data = self.tts.generate_from_llm_response(response)
                
                # 음성 재생
                self.play_audio(audio_data)
                
                results.append({
                    'input': phrase,
                    'response': response
                })
                
                print(f"✅ 테스트 {i} 완료")
                
            except Exception as e:
                print(f"❌ 테스트 {i} 실패: {e}")
        
        # 결과 요약
        if results:
            print("\n📊 테스트 결과 요약")
            print("=" * 50)
            for i, result in enumerate(results, 1):
                print(f"테스트 {i}:")
                print(f"  입력: {result['input']}")
                print(f"  응답: {result['response']}")
                print()
    
    def cleanup(self):
        """리소스 정리"""
        try:
            if hasattr(self, 'stream') and self.stream:
                self.stream.stop_stream()
                self.stream.close()
            if hasattr(self, 'audio') and self.audio:
                self.audio.terminate()
        except Exception as e:
            print(f"⚠️  정리 중 오류: {e}")

def signal_handler(signum, frame):
    """시그널 핸들러"""
    print("\n🛑 프로그램이 중단되었습니다.")
    sys.exit(0)

def main():
    """메인 함수"""
    # 시그널 핸들러 등록
    signal.signal(signal.SIGINT, signal_handler)
    
    print("🎯 LLM 중심 통합 음성 파이프라인 테스트 프로그램")
    print("=" * 50)
    
    # 시스템 메모리 상태 확인
    try:
        import psutil
        memory = psutil.virtual_memory()
        print(f"💾 시스템 메모리: {memory.available / (1024**3):.1f}GB 사용 가능 / {memory.total / (1024**3):.1f}GB 전체")
        if memory.available < 2 * (1024**3):  # 2GB 미만
            print("⚠️  사용 가능한 메모리가 부족합니다. small 모델 사용에 주의하세요.")
    except ImportError:
        print("ℹ️  psutil이 설치되지 않아 메모리 상태를 확인할 수 없습니다.")
    print("=" * 50)
    
    # 테스트 모드 선택
    print("테스트 모드를 선택하세요:")
    print("1. 대화형 테스트 (Enter키로 녹음 시작/종료)")
    print("2. 배치 테스트 (미리 정의된 문장들)")
    
    while True:
        choice = input("선택 (1/2): ").strip()
        if choice in ['1', '2']:
            break
        print("1 또는 2를 입력하세요.")
    
    # 테스트 실행
    test = UnifiedVoicePipelineTest()
    
    try:
        if choice == '1':
            test.run_interactive_test()
        else:
            # 테스트 문장들
            test_phrases = [
                "안녕하세요",
                "오늘 날씨가 어때요?",
                "내일 오전 9시에 병원 예약을 잡아주세요",
                "오늘 저녁 7시에 가족과 저녁 식사",
                "다음 주 월요일 오후 2시에 회의가 있습니다"
            ]
            test.run_batch_test(test_phrases)
    
    except KeyboardInterrupt:
        print("\n🛑 프로그램이 중단되었습니다.")
    except Exception as e:
        print(f"❌ 예상치 못한 오류: {e}")
    finally:
        test.cleanup()
        print("✅ 테스트 완료")

if __name__ == "__main__":
    main() 