import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import '../../../../domain/entities/lucky_money.dart';
import '../../../providers/lucky_money_provider.dart';

class LuckyDrawDialog extends StatefulWidget {
  const LuckyDrawDialog({super.key});

  @override
  State<LuckyDrawDialog> createState() => _LuckyDrawDialogState();
}

class _LuckyDrawDialogState extends State<LuckyDrawDialog> {
  late ConfettiController _confettiController;
  LuckyMoney? _winner;
  bool _isDrawing = false;
  bool _revealed = false;

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

  void _startDraw() async {
    final provider = context.read<LuckyMoneyProvider>();
    final winner = provider.getRandomRecipient();

    if (winner == null) {
      return; // Handled in UI now
    }

    setState(() {
      _isDrawing = true;
      _winner = winner;
    });

    // Simulating "drawing" time
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isDrawing = false;
        _revealed = true;
      });
      _confettiController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: -pi / 2,
                  colors: const [Colors.red, Colors.yellow, Colors.orange],
                ),
                if (!_revealed)
                  Lottie.network(
                    'https://lottie.host/82df09e2-63bc-4523-8cda-174895067208/XGIsO09vI5.json', // Festive Red Envelope
                    height: 200,
                    animate: _isDrawing,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.volunteer_activism, size: 100, color: Colors.red),
                  )
                else
                  _buildWinnerDisplay(),
              ],
            ),
            const SizedBox(height: 24),
            if (!_revealed && !_isDrawing)
              Consumer<LuckyMoneyProvider>(
                builder: (context, provider, child) {
                  final hasCandidates = provider.luckyMoneyList.any((e) => e.isGave == 0);
                  
                  if (!hasCandidates) {
                    return Column(
                      children: [
                        const Text("🧧 Danh sách trống", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Đóng"),
                        ),
                      ],
                    );
                  }

                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _startDraw,
                    child: const Text("Bốc thăm ngay!", style: TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              )
            else if (_revealed)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Đóng"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerDisplay() {
    return Column(
      children: [
        const Text("🧧 Chúc mừng!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
        const SizedBox(height: 12),
        Text(
          _winner?.recipient ?? "",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "${_winner?.amount.toInt()}đ",
          style: const TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "Nhóm: ${_winner?.group}",
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
