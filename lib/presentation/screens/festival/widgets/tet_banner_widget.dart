import 'package:flutter/material.dart';

class TetBannerWidget extends StatelessWidget {
  const TetBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffd32f2f), Color(0xffffb300)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.card_giftcard, color: Colors.white, size: 40),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Chúc mừng năm mới 2026\nĐi chợ thông minh - Tiết kiệm hơn 🎉",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }
}
