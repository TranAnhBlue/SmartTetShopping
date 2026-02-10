import 'package:flutter/material.dart';
import 'dart:math';

class LuckyMoneyAnimation extends StatefulWidget {
  const LuckyMoneyAnimation({super.key});

  @override
  State<LuckyMoneyAnimation> createState() => _LuckyMoneyAnimationState();
}

class _LuckyMoneyAnimationState extends State<LuckyMoneyAnimation>
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
      duration: Duration(seconds: 5 + random.nextInt(3)),
    )..repeat();

    animation = Tween(begin: -150.0, end: 800.0).animate(controller);

    startX = random.nextDouble() * 350;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return Positioned(
          top: animation.value,
          left: startX,
          child: Transform.rotate(
            angle: animation.value / 200,
            child: const Icon(
              Icons.card_giftcard,
              color: Colors.red,
              size: 24,
            ),
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
