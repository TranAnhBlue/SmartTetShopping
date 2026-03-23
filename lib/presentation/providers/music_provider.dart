import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class _Song {
  final String title;
  final String artist;
  final Source source;
  _Song({required this.title, required this.artist, required this.source});
}

class MusicProvider with ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  bool _isMuted = false;
  bool _isPlaying = false;
  int _currentIndex = 0;
  bool _isVisible = true; // Thêm trạng thái hiển thị

  final List<_Song> _playlist = [
    _Song(title: 'Một Năm Mới Bình An', artist: 'Sơn Tùng M-TP', source: AssetSource('audio/Một Năm Mới Bình An.mp3')),
    _Song(title: 'Ngày Tết Quê Em', artist: 'Beeboss', source: AssetSource('audio/Ngày Tết Quê Em.mp3')), 
    _Song(title: 'Xuân Đã Về', artist: 'Châu Đăng Khoa, Sofia', source: AssetSource('audio/Xuân Đã Về.mp3')),
    _Song(title: 'Ngày Xuân Long Phụng Sum Vầy', artist: 'Beeboss', source: AssetSource('audio/Ngày Xuân Long Phụng Sum Vầy.mp3')),
    _Song(title: 'Tết Này Con Sẽ Về', artist: 'Bùi Công Nam', source: AssetSource('audio/Tết Này Con Sẽ Về.mp3')),
    _Song(title: 'Đi Về Nhà', artist: 'Nhiều ca sĩ', source: AssetSource('audio/ĐI VỀ NHÀ.mp3')),
  ];

  bool get isMuted => _isMuted;
  bool get isPlaying => _isPlaying;
  int get currentIndex => _currentIndex;
  String get currentTitle => _playlist[_currentIndex].title;
  String get currentArtist => _playlist[_currentIndex].artist;
  List<String> get songTitles => _playlist.map((s) => s.title).toList();
  bool get isVisible => _isVisible;

  int _retryCount = 0;

  MusicProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(1.0);
      
      _player.onPlayerStateChanged.listen((state) {
        _isPlaying = state == PlayerState.playing;
        notifyListeners();
      });

      _player.onPlayerComplete.listen((event) {
        next();
      });
    } catch (e) {
      debugPrint("❌ Lỗi init AudioPlayer: $e");
    }
  }

  /// Phát nhạc với cơ chế retry và delay ổn định
  Future<void> playMusic({bool resetRetry = true}) async {
    if (resetRetry) _retryCount = 0;
    
    try {
      // Đợi 1 chút để app ổn định (tránh lỗi audio focus)
      await Future.delayed(const Duration(milliseconds: 1000));
      
      final song = _playlist[_currentIndex];
      debugPrint("🎵 Đang thử phát (Lần ${_retryCount + 1}): ${song.title}");
      
      await _player.play(song.source);
      _isMuted = false;
      notifyListeners();
      
    } catch (e) {
      debugPrint("⚠️ Lỗi phát nhạc: $e");
      if (_retryCount < 3) {
        _retryCount++;
        await playMusic(resetRetry: false);
      }
    }
  }

  Future<void> next() async {
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    await playMusic();
  }

  Future<void> previous() async {
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    await playMusic();
  }

  Future<void> playAtIndex(int index) async {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      await playMusic();
    }
  }

  /// Điều khiển Play/Pause chuẩn style âm nhạc
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_player.state == PlayerState.paused) {
        await _player.resume();
      } else {
        await playMusic();
      }
    }
    notifyListeners();
  }

  // Giữ lại tên hàm cũ để app.dart không lỗi, nhưng đổi logic sang Play/Pause
  Future<void> toggleMute() => togglePlayPause();

  void toggleVisibility() {
    _isVisible = !_isVisible;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
