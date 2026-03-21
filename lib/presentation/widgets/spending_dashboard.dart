import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../core/utils/currency_utils.dart';
import '../providers/shopping_provider.dart';

class SpendingDashboard extends StatelessWidget {
  const SpendingDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingProvider>();
    final stats = _calculateStats(provider);
    final total = provider.getTotalEstimatedCost();

    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      // ...
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "NGÂN SÁCH TẾT DỰ KIẾN",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              GestureDetector(
                onTap: () => _showBudgetDialog(context, provider),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                  child: const Icon(Icons.edit, size: 14, color: Colors.white),
                ),
              ),
              const Spacer(),
              // ⭐ SHARE BUTTON
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white70, size: 20),
                tooltip: "Chia sẻ danh sách",
                onPressed: () {
                  final text = provider.generateShareText();
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("📋 Đã sao chép danh sách vào bộ nhớ tạm!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyUtils.format(provider.tetBudget),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (provider.tetBudget > 0 && total > provider.tetBudget)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.yellowAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "⚠️ VƯỢT NGÂN SÁCH",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 12),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: provider.tetBudget <= 0 ? 0 : (total / provider.tetBudget).clamp(0, 1),
              backgroundColor: Colors.white24,
              color: total > provider.tetBudget ? Colors.yellowAccent : Colors.white,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Đã dùng: ${(provider.tetBudget <= 0 ? 0 : (total / provider.tetBudget * 100)).toStringAsFixed(1)}%",
                style: TextStyle(
                  color: total > provider.tetBudget ? Colors.yellowAccent : Colors.white70,
                  fontSize: 11,
                  fontWeight: total > provider.tetBudget ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                total > provider.tetBudget
                    ? "Vượt: ${CurrencyUtils.format(total - provider.tetBudget)}"
                    : "Còn lại: ${CurrencyUtils.format((provider.tetBudget - total).clamp(0, double.infinity))}",
                style: TextStyle(
                  color: total > provider.tetBudget ? Colors.yellowAccent : Colors.white70,
                  fontSize: 11,
                  fontWeight: total > provider.tetBudget ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 10),
          // ─── TIẾN ĐỘ MUA ───
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "TIẾN ĐỘ MUA",
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${provider.boughtCount}/${provider.totalCount} món",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "ĐÃ CHI",
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      CurrencyUtils.format(provider.getTotalBoughtCost()),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: provider.totalCount == 0 ? 0 : provider.boughtCount / provider.totalCount,
              backgroundColor: Colors.white24,
              color: Colors.greenAccent,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "CHI PHÍ TỐI ƯU (CHỌN MUA NƠI RẺ NHẤT)",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            CurrencyUtils.format(total),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          // ...\n          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 35,
                    sections: _buildSections(stats, total),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: stats.entries.map((entry) {
                    final percentage = total == 0 ? 0 : (entry.value / total * 100);
                    return _buildIndicator(
                      entry.key,
                      _getCategoryColor(entry.key),
                      percentage.toStringAsFixed(0),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, ShoppingProvider provider) {
    final controller = TextEditingController(
        text: CurrencyUtils.formatNumber(provider.tetBudget.toInt()));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Đặt Ngân Sách Tết"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyTextInputFormatter(),
          ],
          decoration: const InputDecoration(
            labelText: "Số tiền (VND)",
            hintText: "Ví dụ: 10.000.000",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              // Parse the raw number by removing formatting
              final digitsOnly = controller.text.replaceAll(RegExp(r'[^\d]'), '');
              final amount = double.tryParse(digitsOnly) ?? 0;
              provider.setBudget(amount);
              Navigator.pop(context);
            },
            child: const Text("Lưu lại"),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateStats(ShoppingProvider provider) {
    final Map<String, double> totals = {};
    for (var item in provider.filteredItems) {
      if (item.id == null) continue;
      
      final categoryName = provider.getCategoryName(item.categoryId);
      final cheapest = provider.cheapestMarkets[item.id!];
      final price = cheapest?['price'] ?? item.estimatedPrice;
      
      totals[categoryName] = (totals[categoryName] ?? 0) + (price * item.quantity);
    }
    return totals;
  }

  List<PieChartSectionData> _buildSections(Map<String, double> stats, double total) {
    return stats.entries.map((entry) {
      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value,
        title: '', // Don't show text inside to keep it clean
        radius: 35,
        badgeWidget: null,
      );
    }).toList();
  }

  Widget _buildIndicator(String label, Color color, String percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            "$percent%",
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'thực phẩm': return const Color(0xFFFFD54F); // Amber
      case 'trang trí': return const Color(0xFF81C784); // Light Green
      case 'đồ uống': return const Color(0xFF64B5F6); // Light Blue
      case 'bánh kẹo': return const Color(0xFFBA68C8); // Purple
      case 'đồ cúng': return const Color(0xFFFF8A65); // Deep Orange
      default: return Colors.white60;
    }
  }
}
