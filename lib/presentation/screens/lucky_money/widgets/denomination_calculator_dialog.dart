import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/lucky_money_provider.dart';
import 'package:intl/intl.dart';

class DenominationCalculatorDialog extends StatelessWidget {
  const DenominationCalculatorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LuckyMoneyProvider>();
    final total = provider.totalBudget;
    final currencyFormat = NumberFormat('#,###', 'vi_VN');

    // Denominations to calculate
    final denominations = [500000, 200000, 100000, 50000, 20000, 10000, 5000, 2000, 1000];
    
    // Simple greedy calculation (can be improved if user wants specific counts, 
    // but here we just show a suggested breakdown of the total)
    Map<int, int> breakdown = {};
    int remaining = total.toInt();

    for (var d in denominations) {
      if (remaining >= d) {
        breakdown[d] = remaining ~/ d;
        remaining %= d;
      }
    }

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.calculate, color: Colors.red),
          const SizedBox(width: 10),
          const Text("Đổi tiền Lì xì"),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tổng cần: ${currencyFormat.format(total)}đ", 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            if (breakdown.isEmpty)
              const Text("Chưa có danh sách lì xì để tính toán.")
            else
              ...breakdown.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${currencyFormat.format(e.key)}đ", 
                      style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500)),
                    Text("x ${e.value} tờ", 
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
            if (remaining > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text("Dư: ${currencyFormat.format(remaining)}đ", 
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            const Divider(height: 32),
            const Text("💡 Gợi ý: Bạn nên chuẩn bị dư thêm các mệnh giá nhỏ để linh hoạt hơn.",
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng")),
      ],
    );
  }
}
