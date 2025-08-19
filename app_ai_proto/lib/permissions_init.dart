import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class PermissionsInit {
  /// 앱 시작 시 호출 - 필요한 권한들을 순서대로 요청
  static Future<void> requestNecessaryPermissions() async {
    print('=== 권한 초기화 시작 ===');
    print('🌐 Web 환경 여부: $kIsWeb');

    // Web 환경에서는 권한 처리가 다름
    if (kIsWeb) {
      print('🌐 Web 환경에서는 브라우저가 자동으로 권한을 요청합니다.');
      return;
    }

    try {
      // 1. 마이크 권한 (음성 인식 필수)
      print('🎤 마이크 권한 확인 중...');
      var micStatus = await Permission.microphone.status;
      print('현재 마이크 권한 상태: $micStatus');

      if (!micStatus.isGranted) {
        print('마이크 권한을 요청합니다...');

        // iOS에서 권한 팝업이 안 뜨는 문제 해결
        if (Platform.isIOS) {
          print('🍎 iOS 환경 - 실제 마이크 접근으로 권한 팝업 트리거');
          // 실제 마이크 접근을 먼저 시도하여 iOS가 권한 팝업을 띄우도록 함
          await _triggerIOSMicrophoneAccess();
          
          // 실제 마이크 접근 후 잠시 대기
          await Future.delayed(const Duration(milliseconds: 500));
        }

        micStatus = await Permission.microphone.request();
        print('마이크 권한 요청 결과: $micStatus');
        
        // iOS에서 권한이 거부된 경우 다시 한 번 시도
        if (Platform.isIOS && !micStatus.isGranted) {
          print('🔄 iOS에서 권한이 거부됨 - 다시 시도...');
          await Future.delayed(const Duration(milliseconds: 1000));
          micStatus = await Permission.microphone.request();
          print('마이크 권한 재요청 결과: $micStatus');
        }
      }

      if (!micStatus.isGranted) {
        print('❌ 마이크 권한이 거부되었습니다.');
        print('⚠️ 음성 인식 기능을 사용할 수 없습니다.');
        return;
      }

      print('✅ 마이크 권한 허용됨');

      // 2. Android 13+ (API 33+) 외부 오디오 읽기 권한
      if (Platform.isAndroid) {
        print('📱 Android 환경 확인 중...');
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdk = androidInfo.version.sdkInt ?? 0;
        print('Android SDK 버전: $sdk');

        if (sdk >= 33) {
          print('📂 외부 오디오 읽기 권한 확인 중... (Android 13+)');
          var audioStatus = await Permission.audio.status;
          print('현재 오디오 권한 상태: $audioStatus');

          if (!audioStatus.isGranted) {
            print('외부 오디오 읽기 권한을 요청합니다...');
            audioStatus = await Permission.audio.request();
            print('오디오 권한 요청 결과: $audioStatus');
          }

          if (!audioStatus.isGranted) {
            print('⚠️ 외부 오디오 읽기 권한이 거부되었습니다.');
            print('⚠️ 일부 오디오 기능이 제한될 수 있습니다.');
          } else {
            print('✅ 외부 오디오 읽기 권한 허용됨');
          }
        } else {
          print('📱 Android 13 미만이므로 외부 오디오 권한 불필요');
        }
      }

      print('✅ 필요한 권한 초기화 완료');
    } catch (e) {
      print('❌ 권한 초기화 중 오류: $e');
    }
  }

  /// iOS에서 실제 마이크 접근을 시도하여 권한 팝업을 트리거
  static Future<void> _triggerIOSMicrophoneAccess() async {
    if (!Platform.isIOS) return;

    print('🎤 iOS 마이크 접근 트리거 시작');

    try {
      // 실제 마이크 접근을 시도하여 iOS가 권한 팝업을 띄우도록 함
      // 사용자가 보여준 글의 방법을 적용
      print('🎤 실제 마이크 접근 시도 중...');
      
      // 방법 1: speech_to_text를 사용하여 실제 마이크 접근 시도
      final speechToText = stt.SpeechToText();
      final available = await speechToText.initialize();
      
      if (available) {
        print('🎤 SpeechToText 초기화 성공 - 실제 마이크 접근 시도');
        
        // 실제 마이크 접근을 위해 잠시 녹음 시도
        await speechToText.listen(
          onResult: (result) {
            // 결과는 무시 (권한 팝업 트리거용)
          },
          listenFor: const Duration(milliseconds: 100),
          pauseFor: const Duration(milliseconds: 100),
        );
        
        // 잠시 대기 후 중지
        await Future.delayed(const Duration(milliseconds: 200));
        await speechToText.stop();
        
        print('🎤 실제 마이크 접근 완료');
      } else {
        print('⚠️ SpeechToText 초기화 실패 - 대체 방법 사용');
        
        // 대체 방법: 권한 상태를 여러 번 확인하여 iOS가 반응하도록 함
        for (int i = 0; i < 5; i++) {
          final status = await Permission.microphone.status;
          print('🎤 마이크 권한 상태 확인 $i: $status');
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
      
      print('🎤 iOS 마이크 접근 트리거 완료');
    } catch (e) {
      print('❌ iOS 마이크 접근 트리거 중 오류: $e');
      // 오류는 무시하고 계속 진행
    }
  }

  /// 특정 권한 상태 확인
  static Future<bool> checkMicrophonePermission() async {
    if (kIsWeb) return true; // Web에서는 브라우저가 처리

    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// 권한이 거부된 경우 앱 설정으로 이동
  static Future<void> openAppSettingsIfNeeded() async {
    if (kIsWeb) return; // Web에서는 불필요

    final micStatus = await Permission.microphone.status;
    if (micStatus.isPermanentlyDenied) {
      print('🔧 앱 설정으로 이동합니다...');
      await openAppSettings();
    }
  }
}
