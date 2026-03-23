import 'dart:math';
import 'package:flutter/material.dart';

class TetBackground extends StatelessWidget {
  final Animation<double> animation;
  final List<double> petalPositions;

  const TetBackground({
    super.key,
    required this.animation,
    required this.petalPositions,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8B0000), Color(0xFFD32F2F), Color(0xFFB71C1C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // Magical Firefly effect
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) => _buildFireflies(context),
        ),
        
        Positioned(top: -120, left: -80, child: _buildGlow()),
        Positioned(bottom: -120, right: -80, child: _buildGlow()),
        
        // Swinging Lanterns
        const Positioned(top: -20, left: 10, child: _SwingingLantern()),
        const Positioned(top: 0, right: 20, child: _SwingingLantern(scale: 0.8)),
        
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) => _buildPetals(context),
        ),
      ],
    );
  }

  Widget _buildGlow() => Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.orange.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
      );

  Widget _buildFireflies(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: List.generate(10, (index) {
        final progress = (animation.value + index * 0.2) % 1;
        return Positioned(
          top: (1 - progress) * screenHeight,
          left: (petalPositions[index % petalPositions.length] + cos(progress * pi)) * screenWidth,
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD700).withOpacity(0.4 * (1 - progress)),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.5), blurRadius: 4, spreadRadius: 1)
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPetals(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: List.generate(petalPositions.length, (index) {
        final progress = (animation.value + index * 0.12) % 1;
        return Positioned(
          top: progress * screenHeight,
          left: (petalPositions[index] + sin(progress * 2 * pi) * 0.05) * screenWidth,
          child: Transform.rotate(
            angle: progress * 2 * pi,
            child: Transform.scale(
              scale: 0.8 + progress * 0.4,
              child: Text(
                "🌸",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
class _SwingingLantern extends StatefulWidget {
  final double scale;
  const _SwingingLantern({this.scale = 1.0});

  @override
  State<_SwingingLantern> createState() => _SwingingLanternState();
}

class _SwingingLanternState extends State<_SwingingLantern> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.scale,
          child: Transform.rotate(
            angle: _animation.value,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 2, height: 40, color: Colors.black54),
                const Text("🏮", style: TextStyle(fontSize: 40)),
              ],
            ),
          ),
        );
      },
    );
  }
}
