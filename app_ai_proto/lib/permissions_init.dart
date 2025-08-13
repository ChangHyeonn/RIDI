import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
        micStatus = await Permission.microphone.request();
        print('마이크 권한 요청 결과: $micStatus');
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
