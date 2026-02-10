import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class FireworkLayer extends StatefulWidget {
  const FireworkLayer({super.key});

  @override
  State<FireworkLayer> createState() => _FireworkLayerState();
}

class _FireworkLayerState extends State<FireworkLayer> {

  late ConfettiController controller;

  @override
  void initState() {
    super.initState();

    controller = ConfettiController(
      duration: const Duration(seconds: 10),
    );

    controller.play();
  }

  @override
  Widget build(BuildContext context) {

    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: controller,
        blastDirection: pi / 2,
        emissionFrequency: 0.02,
        numberOfParticles: 20,
        gravity: 0.15,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
