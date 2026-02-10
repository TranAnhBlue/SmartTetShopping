import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class TetOverlay extends StatefulWidget {
  const TetOverlay({super.key});

  @override
  State<TetOverlay> createState() => _TetOverlayState();
}

class _TetOverlayState extends State<TetOverlay>
    with SingleTickerProviderStateMixin {

  ConfettiController? confettiTop;
  ConfettiController? confettiLeft;
  ConfettiController? confettiRight;

  late AnimationController flowerController;

  final random = Random();

  @override
  void initState() {
    super.initState();

    confettiTop = ConfettiController(duration: const Duration(seconds: 10));
    confettiLeft = ConfettiController(duration: const Duration(seconds: 10));
    confettiRight = ConfettiController(duration: const Duration(seconds: 10));

    confettiTop!.play();
    confettiLeft!.play();
    confettiRight!.play();

    flowerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    confettiTop?.dispose();
    confettiLeft?.dispose();
    confettiRight?.dispose();
    flowerController.dispose();
    super.dispose();
  }

  Widget buildFallingFlower() {
    final startX = random.nextDouble();
    final speed = 0.5 + random.nextDouble();

    return AnimatedBuilder(
      animation: flowerController,
      builder: (_, __) {

        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;

        final progress = (flowerController.value * speed) % 1;

        return Positioned(
          top: progress * screenHeight,
          left: startX * screenWidth,
          child: const Text(
            "🌸",
            style: TextStyle(fontSize: 24),
          ),
        );
      },
    );
  }


  Widget buildLiXi() {
    final startX = random.nextDouble();
    final speed = 0.4 + random.nextDouble();

    return AnimatedBuilder(
      animation: flowerController,
      builder: (_, __) {

        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;

        final progress = (flowerController.value * speed) % 1;

        return Positioned(
          top: progress * screenHeight,
          right: startX * screenWidth,
          child: const Text(
            "🧧",
            style: TextStyle(fontSize: 22),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    /// Nếu controller chưa sẵn sàng -> không render confetti
    if (confettiTop == null) return const SizedBox();

    return IgnorePointer(
      child: Stack(
        children: [

          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.orange.withOpacity(0.15),
                  Colors.transparent,
                ],
                radius: 1.2,
              ),
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confettiTop!,
              blastDirection: pi / 2,
              emissionFrequency: 0.02,
              numberOfParticles: 15,
              gravity: 0.2,
            ),
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: ConfettiWidget(
              confettiController: confettiLeft!,
              blastDirection: 0,
              emissionFrequency: 0.015,
              numberOfParticles: 12,
              gravity: 0.2,
            ),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: ConfettiWidget(
              confettiController: confettiRight!,
              blastDirection: pi,
              emissionFrequency: 0.015,
              numberOfParticles: 12,
              gravity: 0.2,
            ),
          ),

          ...List.generate(8, (_) => buildFallingFlower()),
          ...List.generate(5, (_) => buildLiXi()),
        ],
      ),
    );
  }
}
