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
              colors: [Color(0xFF8B0000), Color(0xFFD32F2F), Color(0xFFFFC107)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(top: -120, left: -80, child: _buildGlow()),
        Positioned(bottom: -120, right: -80, child: _buildGlow()),
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
              Colors.orange.withOpacity(0.5),
              Colors.transparent,
            ],
          ),
        ),
      );

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
