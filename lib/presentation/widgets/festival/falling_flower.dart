import 'package:flutter/material.dart';
import 'dart:math';

class FallingFlower extends StatefulWidget {
  const FallingFlower({super.key});

  @override
  State<FallingFlower> createState() => _FallingFlowerState();
}

class _FallingFlowerState extends State<FallingFlower>
    with SingleTickerProviderStateMixin {

  late AnimationController controller;
  late Animation<double> animation;
  final random = Random();

  double startX = 0;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 6 + random.nextInt(4)),
    )..repeat();

    animation = Tween(begin: -100.0, end: 900.0).animate(controller);

    startX = random.nextDouble() * 400;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return Positioned(
          top: animation.value,
          left: startX + sin(animation.value / 50) * 20,
          child: const Icon(
            Icons.local_florist,
            color: Colors.yellow,
            size: 18,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
