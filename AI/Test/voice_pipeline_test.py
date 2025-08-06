#!/usr/bin/env python3
"""
Voice Pipeline Test
음성 입력 → STT → LLM → TTS → 음성 출력 전체 파이프라인 테스트
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

from Models.STT import WhisperSTT
from Models.LLM import LLMFactory
from Models.TTS import TTS
from Config.settings import Settings

class VoicePipelineTest:
    """음성 파이프라인 테스트 클래스"""
    
    def __init__(self):
        self.setup_components()
        self.setup_audio()
        self.recording = False
        self.recorded_frames = []
        self.running = True
        
    def setup_components(self):
        """AI 컴포넌트 초기화"""
        print("🤖 AI 컴포넌트 초기화 중...")
        
        # STT 초기화
        try:
            # 메모리 사용량을 줄이기 위한 설정
            os.environ['PYTORCH_CUDA_ALLOC_CONF'] = 'max_split_size_mb:128'
            os.environ['OMP_NUM_THREADS'] = '1'
            
            # 메모리 정리
            import gc
            gc.collect()
            
            self.stt = WhisperSTT(
                model_name=Settings.STT_MODEL,  # 설정 파일의 모델 사용
                device="cpu"  # 안전한 CPU 사용
            )
            print(f"✅ STT 초기화 완료: {Settings.STT_MODEL} (CPU)")
            
            # 양자화 정보 출력
            quantization_info = self.stt.get_quantization_info()
            print(f"📊 양자화 정보: {quantization_info['precision']}, 메모리 절약: {quantization_info['memory_savings']}")
            
        except Exception as e:
            print(f"❌ STT 초기화 실패: {e}")
            self.stt = None
        
        # LLM 초기화
        try:
            self.llm = LLMFactory.create_llm(Settings.LLM_TYPE)
            print(f"✅ LLM 초기화 완료: {Settings.LLM_TYPE}")
        except Exception as e:
            print(f"⚠️  LLM 초기화 실패: {e}")
            self.llm = None
        
        # TTS 초기화
        try:
            self.tts = TTS()
            print("✅ TTS 초기화 완료")
        except Exception as e:
            print(f"❌ TTS 초기화 실패: {e}")
            self.tts = None
        
    def setup_audio(self):
        """오디오 설정"""
        try:
            import pyaudio
            self.audio = pyaudio.PyAudio()
            self.sample_rate = 16000
            self.chunk_size = 1024
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
        while self.recording:
            try:
                data = self.stream.read(self.chunk_size, exception_on_overflow=False)
                self.recorded_frames.append(data)
            except Exception as e:
                print(f"⚠️  녹음 중 오류: {e}")
                break
    
    def process_voice_pipeline(self, audio_path):
        """음성 파이프라인 처리: STT → LLM → TTS"""
        print("\n🔄 음성 파이프라인 처리 시작...")
        
        # 1. STT (음성 → 텍스트)
        if not self.stt:
            print("❌ STT가 초기화되지 않았습니다.")
            return None
            
        print("📝 STT 처리 중...")
        start_time = time.time()
        try:
            text = self.stt.transcribe(audio_path)
            if not text:
                print("⚠️  STT 결과가 비어있습니다.")
                return None
                
            stt_time = time.time() - start_time
            print(f"✅ STT 결과: {text}")
            print(f"⏱️  STT 처리 시간: {stt_time:.2f}초")
        except Exception as e:
            print(f"❌ STT 처리 실패: {e}")
            return None
        
        # 2. LLM (텍스트 → 응답)
        print("🤖 LLM 처리 중...")
        start_time = time.time()
        try:
            if self.llm:
                response = self.llm.generate_response(text)
            else:
                response = f"입력하신 내용은 '{text}'입니다. 고령자 친화적인 응답을 제공합니다."
            llm_time = time.time() - start_time
            print(f"✅ LLM 응답: {response}")
            print(f"⏱️  LLM 처리 시간: {llm_time:.2f}초")
        except Exception as e:
            print(f"❌ LLM 처리 실패: {e}")
            response = f"입력하신 내용은 '{text}'입니다."
            llm_time = time.time() - start_time
        
        # 3. TTS (텍스트 → 음성)
        if not self.tts:
            print("❌ TTS가 초기화되지 않았습니다.")
            return {
                'text': text,
                'response': response,
                'audio_data': None,
                'timing': {
                    'stt': stt_time,
                    'llm': llm_time,
                    'tts': 0,
                    'total': stt_time + llm_time
                }
            }
            
        print("🔊 TTS 처리 중...")
        start_time = time.time()
        try:
            audio_data = self.tts.generate_from_llm_response(response)
            tts_time = time.time() - start_time
            print(f"✅ TTS 처리 완료")
            print(f"⏱️  TTS 처리 시간: {tts_time:.2f}초")
        except Exception as e:
            print(f"❌ TTS 처리 실패: {e}")
            audio_data = None
            tts_time = time.time() - start_time
        
        total_time = stt_time + llm_time + tts_time
        print(f"⏱️  총 처리 시간: {total_time:.2f}초")
        
        return {
            'text': text,
            'response': response,
            'audio_data': audio_data,
            'timing': {
                'stt': stt_time,
                'llm': llm_time,
                'tts': tts_time,
                'total': total_time
            }
        }
    
    def play_audio(self, audio_data):
        """음성 재생"""
        if not audio_data or not self.audio:
            print("⚠️  재생할 오디오가 없습니다.")
            return
            
        print("🔊 음성 재생 중...")
        
        try:
            # 임시 MP3 파일로 저장
            temp_mp3 = tempfile.NamedTemporaryFile(delete=False, suffix='.mp3')
            temp_mp3.write(audio_data)
            temp_mp3.close()
            
            # 시스템 명령어로 MP3 재생 (macOS)
            import subprocess
            try:
                subprocess.run(['afplay', temp_mp3.name], check=True)
                print("✅ 음성 재생 완료")
            except subprocess.CalledProcessError:
                print("⚠️  afplay 명령어 실패, 다른 방법 시도...")
                # 대안: pydub 사용
                from pydub import AudioSegment
                audio = AudioSegment.from_mp3(temp_mp3.name)
                temp_wav = tempfile.NamedTemporaryFile(delete=False, suffix='.wav')
                audio.export(temp_wav.name, format="wav")
                temp_wav.close()
                
                # PyAudio로 재생
                stream = self.audio.open(
                    format=self.format,
                    channels=self.channels,
                    rate=self.sample_rate,
                    output=True
                )
                
                with wave.open(temp_wav.name, 'rb') as wf:
                    data = wf.readframes(wf.getnframes())
                    stream.write(data)
                
                stream.stop_stream()
                stream.close()
                
                # 임시 WAV 파일 삭제
                if os.path.exists(temp_wav.name):
                    os.unlink(temp_wav.name)
                print("✅ 음성 재생 완료")
            
            # 임시 MP3 파일 삭제
            if os.path.exists(temp_mp3.name):
                os.unlink(temp_mp3.name)
            
        except Exception as e:
            print(f"❌ 음성 재생 실패: {e}")
    
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
    
    print("🎯 음성 파이프라인 테스트 프로그램")
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
    test = VoicePipelineTest()
    
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