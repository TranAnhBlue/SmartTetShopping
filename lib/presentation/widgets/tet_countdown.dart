import 'dart:async';
import 'package:flutter/material.dart';

class TetCountdown extends StatefulWidget {
  const TetCountdown({super.key});

  @override
  State<TetCountdown> createState() => _TetCountdownState();
}

class _TetCountdownState extends State<TetCountdown> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  // Tet 2026 (Lunar New Year - Feb 17, 2026)
  final DateTime _tetDate = DateTime(2026, 2, 17, 0, 0, 0);

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
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
              Text("🧨", style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                "ĐẾM NGƯỢC TẾT BÍNH NGỌ 2026",
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Text("🧨", style: const TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimePart(_timeLeft.inDays, "Ngày"),
              _buildDivider(),
              _buildTimePart(_timeLeft.inHours.remainder(24), "Giờ"),
              _buildDivider(),
              _buildTimePart(_timeLeft.inMinutes.remainder(60), "Phút"),
              _buildDivider(),
              _buildTimePart(_timeLeft.inSeconds.remainder(60), "Giây"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePart(int value, String label) {
    return Column(
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.red.shade300,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

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
