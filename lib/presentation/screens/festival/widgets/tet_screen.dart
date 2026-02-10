import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';

import '../../home/home_screen.dart';


class TetScreen extends StatefulWidget {
  const TetScreen({super.key});

  @override
  State<TetScreen> createState() => _TetScreenState();
}

class _TetScreenState extends State<TetScreen> {

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));

    _confettiController.play();

    /// ⭐ Auto chuyển Home
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xffb71c1c),

      body: Stack(
        children: [

          /// 🎆 Lottie pháo hoa
          Center(
            child: Lottie.asset(
              "assets/animation/fireworks.json",
              repeat: true,
            ),
          ),

          /// 🧧 Confetti lì xì
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
            ),
          ),

          /// Text chúc tết
          const Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "🎊 Chúc Mừng Năm Mới 2026 🎊",
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Xuân An Khang - Thịnh Vượng",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
