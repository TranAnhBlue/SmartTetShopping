import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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

    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade800, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TỔNG CHI PHÍ DỰ KIẾN",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currency.format(total),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 20),
          Row(
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
                    return _buildIndicator(
                      entry.key,
                      _getCategoryColor(entry.key),
                      (entry.value / total * 100).toStringAsFixed(0),
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

  Map<String, double> _calculateStats(ShoppingProvider provider) {
    final Map<String, double> totals = {};
    for (var item in provider.items) {
      final categoryName = provider.getCategoryName(item.categoryId);
      totals[categoryName] = (totals[categoryName] ?? 0) + (item.estimatedPrice * item.quantity);
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
