import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class AudioPlayerService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> playAudioFromBase64(String audioUrl) async {
    try {
      if (audioUrl.startsWith('data:audio/mp3;base64,')) {
        String base64Data = audioUrl.replaceFirst('data:audio/mp3;base64,', '');
        Uint8List audioBytes = base64Decode(base64Data);

        // 임시 파일로 저장
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_audio.mp3');
        await tempFile.writeAsBytes(audioBytes);

        // 재생
        await _audioPlayer.play(DeviceFileSource(tempFile.path));
      }
    } catch (e) {
      print('음성 재생 오류: $e');
    }
  }

  static Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('음성 중지 오류: $e');
    }
  }

  static Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
    } catch (e) {
      print('오디오 플레이어 해제 오류: $e');
    }
  }
}
