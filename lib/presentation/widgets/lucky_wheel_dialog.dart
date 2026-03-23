import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'lucky_wheel.dart';
import 'shimmer_text.dart';
import 'dart:math';

class LuckyWheelDialog extends StatefulWidget {
  const LuckyWheelDialog({super.key});

  @override
  State<LuckyWheelDialog> createState() => _LuckyWheelDialogState();
}

class _LuckyWheelDialogState extends State<LuckyWheelDialog> {
  late ConfettiController _confettiController;
  final List<String> _items = [
    "20k 🧧",
    "50k 🧧",
    "100k 🧧",
    "Chúc Tết 🌸",
    "200k 🧧",
    "Phát Tài 🏮",
    "500k 💎",
    "Hẹn May ☘️"
  ];
  final GlobalKey<LuckyWheelState> _wheelKey = GlobalKey<LuckyWheelState>();
  String _result = "";
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFFFD700), width: 3),
          image: const DecorationImage(
            image: AssetImage('assets/images/tet_pattern.png'),
            opacity: 0.1,
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "🏮 VÒNG QUAY LÌ XÌ 🏮",
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Nhấn vào vòng quay để thử vận may!",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 40),
            Stack(
              alignment: Alignment.center,
              children: [
                ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive, // Bắn tung tóe hơn
                  colors: const [Colors.red, Colors.yellow, Colors.orange, Colors.white],
                  shouldLoop: false,
                ),
                LuckyWheel(
                  key: _wheelKey,
                  items: _items,
                  onStart: () {
                    setState(() {
                      _isSpinning = true;
                      _result = "";
                    });
                  },
                  onResult: (index) {
                    setState(() {
                      _isSpinning = false;
                      _result = _items[index];
                    });
                    _confettiController.play();
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
            if (_result.isNotEmpty)
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _result.contains("500k") 
                                  ? Colors.white.withOpacity(0.8) 
                                  : Colors.black.withOpacity(0.3), 
                                blurRadius: 20,
                                spreadRadius: _result.contains("500k") ? 5 : 0,
                              )
                            ],
                            border: _result.contains("500k") 
                              ? Border.all(color: Colors.white, width: 2) 
                              : null,
                          ),
                          child: Column(
                            children: [
                              ShimmerText(
                                text: "CHÚC MỪNG!",
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                _result,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _wheelKey.currentState?.spin(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            elevation: 5,
                          ),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text("QUAY TIẾP", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              const SizedBox(height: 110), // Increased to match new result block height
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isSpinning ? null : () => Navigator.pop(context),
              child: const Text(
                "ĐÓNG",
                style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
