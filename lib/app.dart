import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'presentation/widgets/festival/tet_overlay.dart';
import 'presentation/widgets/confetti_overlay.dart';
import 'core/utils/auth_service.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/auth/login_screen.dart';

import 'presentation/providers/music_provider.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Smart Tet Shopping",
      debugShowCheckedModeBanner: false,

      /// ⭐ Localization (Hỗ trợ tiếng Việt)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', ''),
        Locale('en', ''),
      ],
      locale: const Locale('vi', ''),

      /// ⭐ Theme Tết
      theme: AppTheme.lightTheme,

      home: StreamBuilder<User?>(
        stream: AuthService().user,
        initialData: AuthService().currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;
          
          if (user != null) {
            debugPrint("Auth State: Login SUCCESS - User: ${user.uid}");
            return const HomeScreen(key: ValueKey('home'));
          }
          
          debugPrint("Auth State: GOING TO LOGIN (Current data: $user, State: ${snapshot.connectionState})");
          return const LoginScreen(key: ValueKey('login'));
        },
      ),
      onGenerateRoute: AppRouter.generateRoute,

      /// ⭐ Overlay Tết toàn app
      builder: (context, child) {
        return ConfettiOverlay(
          child: Stack(
            children: [
              child!,
              const TetOverlay(),
              
              /// 🎵 Zing MP3 Style Draggable Mini Player
              Consumer<MusicProvider>(
                builder: (context, music, _) {
                  if (!music.isVisible) {
                    // Nút nhỏ nép vào mép phải để hiện lại
                    return Positioned(
                      top: 100,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => music.toggleVisibility(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.7),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)
                            ],
                          ),
                          child: const Icon(Icons.music_note, color: Color(0xFFFFD700), size: 18),
                        ),
                      ),
                    );
                  }
                  return _DraggableMusicOverlay(
                    music: music,
                    initialBottom: 130,
                    onPlaylistTap: () => _showPlaylist(context, music),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlaylist(BuildContext context, MusicProvider music) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final titles = music.songTitles;
        return Container(
          decoration: BoxDecoration(
            color: Colors.red.shade900,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: const Color(0xFFFFD700), width: 2),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              const Text("🧧 DANH SÁCH NHẠC TẾT 🧧", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD700), letterSpacing: 1.2)),
              const SizedBox(height: 15),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: titles.length,
                  itemBuilder: (context, index) {
                    final isCurrent = music.currentIndex == index;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(isCurrent ? Icons.play_arrow : Icons.music_note, color: isCurrent ? Colors.red.shade900 : Colors.white),
                      ),
                      title: Text(titles[index], style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: isCurrent ? const Color(0xFFFFD700) : Colors.white)),
                      subtitle: Text(music.currentArtist, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      trailing: isCurrent ? Icon(Icons.bar_chart, color: const Color(0xFFFFD700)) : null,
                      onTap: () {
                        music.playAtIndex(index);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}

class _DraggableMusicOverlay extends StatefulWidget {
  final MusicProvider music;
  final double initialBottom;
  final VoidCallback onPlaylistTap;

  const _DraggableMusicOverlay({
    required this.music,
    required this.initialBottom,
    required this.onPlaylistTap,
  });

  @override
  State<_DraggableMusicOverlay> createState() => _DraggableMusicOverlayState();
}

class _DraggableMusicOverlayState extends State<_DraggableMusicOverlay> {
  late double _yOffset;
  late double _xOffset;

  @override
  void initState() {
    super.initState();
    _yOffset = widget.initialBottom;
    _xOffset = 24.0;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: _yOffset,
      left: _xOffset,
      right: _xOffset,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _yOffset -= details.delta.dy;
            // Giới hạn để không kéo ra ngoài màn hình
            if (_yOffset < 80) _yOffset = 80;
            if (_yOffset > MediaQuery.of(context).size.height - 150) {
              _yOffset = MediaQuery.of(context).size.height - 150;
            }
          });
        },
        child: _ZingMiniPlayer(
          music: widget.music,
          onPlaylistTap: widget.onPlaylistTap,
        ),
      ),
    );
  }
}

class _ZingMiniPlayer extends StatefulWidget {
  final MusicProvider music;
  final VoidCallback onPlaylistTap;

  const _ZingMiniPlayer({required this.music, required this.onPlaylistTap});

  @override
  State<_ZingMiniPlayer> createState() => _ZingMiniPlayerState();
}

class _ZingMiniPlayerState extends State<_ZingMiniPlayer> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    if (widget.music.isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(_ZingMiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.music.isPlaying) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPlaylistTap,
      child: Container(
        height: 56, // Thon gọn hơn nữa
        decoration: BoxDecoration(
          color: Colors.red.shade900.withOpacity(0.98),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFFFD700), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 4, right: 12),
          child: Row(
            children: [
              // 💿 Đĩa nhạc xoay (Cố định quay/dừng)
              RotationTransition(
                turns: _rotationController,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                    gradient: const SweepGradient(
                      colors: [Colors.black, Colors.grey, Colors.black],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 📝 Thông tin bài hát
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.music.currentTitle,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.music.currentArtist,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // ⏯️ Điều khiển
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.skip_previous, color: Colors.white, size: 24),
                onPressed: () => widget.music.previous(),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(widget.music.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: const Color(0xFFFFD700), size: 36),
                onPressed: () => widget.music.toggleMute(),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
                onPressed: () => widget.music.next(),
              ),
              const VerticalDivider(color: Colors.white24, width: 1, indent: 15, endIndent: 15),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                onPressed: () => widget.music.toggleVisibility(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

