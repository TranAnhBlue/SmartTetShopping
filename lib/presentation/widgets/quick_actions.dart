import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback onLuckyMoney;
  final VoidCallback onGreetings;
  final VoidCallback onScanner;
  final VoidCallback onRitual;

  const QuickActions({
    super.key,
    required this.onLuckyMoney,
    required this.onGreetings,
    required this.onScanner,
    required this.onRitual,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildActionItem("Lì xì 💸", Colors.orange, onLuckyMoney),
          const SizedBox(width: 8),
          _buildActionItem("Lời chúc 💌", Colors.blue, onGreetings),
          const SizedBox(width: 8),
          _buildActionItem("Mâm cỗ 🍱", Colors.purple, onRitual),
          const SizedBox(width: 8),
          _buildActionItem("Quét đơn 📸", Colors.green, onScanner),
        ],
      ),
    );
  }

  Widget _buildActionItem(String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
