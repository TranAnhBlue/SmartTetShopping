import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = true;

  bool get soundEnabled => _soundEnabled;
  void toggleSound() => _soundEnabled = !_soundEnabled;

  /// Phát tiếng tạch tạch khi vòng quay xoay
  Future<void> playSpin() async {
    if (!_soundEnabled) return;
    try {
      await _player.play(AssetSource('audio/sfx_spin.mp3'), volume: 0.5);
    } catch (e) {
      debugPrint("SoundService: Missing sfx_spin.mp3");
    }
  }

  /// Phát tiếng nhạc cực lớn/vỗ tay khi trúng Jackpot
  Future<void> playJackpot() async {
    if (!_soundEnabled) return;
    try {
      await _player.play(AssetSource('audio/sfx_jackpot.mp3'), volume: 1.0);
    } catch (e) {
      debugPrint("SoundService: Missing sfx_jackpot.mp3");
    }
  }

  /// Phát tiếng chuông reo nhẹ khi trúng mệnh giá nhỏ
  Future<void> playWin() async {
    if (!_soundEnabled) return;
    try {
      await _player.play(AssetSource('audio/sfx_win.mp3'), volume: 0.7);
    } catch (e) {
      debugPrint("SoundService: Missing sfx_win.mp3");
    }
  }

  /// Phát tiếng "tiếc nuối" hoặc hài hước khi hụt quà
  Future<void> playFail() async {
    if (!_soundEnabled) return;
    try {
      await _player.play(AssetSource('audio/sfx_fail.mp3'), volume: 0.6);
    } catch (e) {
      debugPrint("SoundService: Missing sfx_fail.mp3");
    }
  }

  /// Phát tiếng Ping "công nghệ" khi AI xuất hiện/nhắc nhở
  Future<void> playAIPing() async {
    if (!_soundEnabled) return;
    try {
      await _player.play(AssetSource('audio/sfx_ai_ping.mp3'), volume: 0.4);
    } catch (e) {
      debugPrint("SoundService: Missing sfx_ai_ping.mp3");
    }
  }

  /// Phát tiếng ting nhẹ khi hoàn thành tác vụ
  Future<void> playSuccess() async {
    if (!_soundEnabled) return;
    try {
      await _player.play(AssetSource('audio/sfx_success.mp3'), volume: 0.4);
    } catch (e) {
      debugPrint("SoundService: Missing sfx_success.mp3");
    }
  }

  void dispose() {
    _player.dispose();
  }
}
