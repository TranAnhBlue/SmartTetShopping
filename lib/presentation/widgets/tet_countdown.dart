import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class TetCountdown extends StatefulWidget {
  const TetCountdown({super.key});

  @override
  State<TetCountdown> createState() => _TetCountdownState();
}

class _TetCountdownState extends State<TetCountdown> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  // Tet 2027 (Lunar New Year - Feb 6, 2027)
  final DateTime _tetDate = DateTime(2027, 2, 6, 0, 0, 0);

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    setState(() {
      _timeLeft = _tetDate.difference(now);
      if (_timeLeft.isNegative) _timeLeft = Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft == Duration.zero) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95), // Solider background for visibility
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("🧧", style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Text(
                      "ĐẾM NGƯỢC TẾT 2027",
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay', // If available, otherwise default
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text("🧧", style: TextStyle(fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTimePart(_timeLeft.inDays, "NGÀY"),
                    _buildTimePart(_timeLeft.inHours.remainder(24), "GIỜ"),
                    _buildTimePart(_timeLeft.inMinutes.remainder(60), "PHÚT"),
                    _buildTimePart(_timeLeft.inSeconds.remainder(60), "GIÂY"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePart(int value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade700, Colors.red.shade900],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
            ],
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white, // High contrast
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.red.shade400,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  // Removed _buildDivider as we use styled containers now

  Widget _buildDivider() {
    return Text(
      ":",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.red.shade100,
      ),
    );
  }
}
