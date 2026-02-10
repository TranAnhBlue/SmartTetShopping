import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../../domain/entities/market_total_cost.dart';
import '../../providers/price_provider.dart';

class CompareMarketPremiumScreen extends StatefulWidget {
  const CompareMarketPremiumScreen({super.key});

  @override
  State<CompareMarketPremiumScreen> createState() =>
      _CompareMarketPremiumScreenState();
}

class _CompareMarketPremiumScreenState
    extends State<CompareMarketPremiumScreen>
    with SingleTickerProviderStateMixin {

  bool sortAsc = true;
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    Future.microtask(() {
      context.read<PriceProvider>().loadMarketTotals();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ======================================================
  // 🎆 TẾT BACKGROUND
  // ======================================================

  Widget _buildTetBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF8B0000),
            Color(0xFFD32F2F),
            Color(0xFFFFC107),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  // ======================================================
  // BUILD
  // ======================================================

  @override
  Widget build(BuildContext context) {

    final provider = context.watch<PriceProvider>();

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = [...provider.totals];

    if (data.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Compare Markets")),
        body: Stack(
          children: [
            _buildTetBackground(),
            const Center(
              child: Text(
                "Chưa có dữ liệu so sánh",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    data.sort((a, b) =>
    sortAsc
        ? a.totalCost.compareTo(b.totalCost)
        : b.totalCost.compareTo(a.totalCost)
    );

    final cheapest = data.first;
    final expensive = data.last;

    return Scaffold(
      appBar: AppBar(
        title: const Text("📊 Compare Markets"),
        actions: [
          IconButton(
            icon: Icon(sortAsc
                ? Icons.arrow_upward
                : Icons.arrow_downward),
            onPressed: () => setState(() => sortAsc = !sortAsc),
          )
        ],
      ),

      body: Stack(
        children: [

          _buildTetBackground(),

          FadeTransition(
            opacity: controller,
            child: Column(
              children: [

                _buildInsight(cheapest, expensive),

                SizedBox(
                  height: 240,
                  child: _buildChart(data, cheapest.marketName),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (_, i) =>
                        _buildMarketCard(data[i], i, cheapest),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // 💡 INSIGHT
  // ======================================================

  Widget _buildInsight(
      MarketTotalCost cheapest,
      MarketTotalCost expensive,
      ) {

    final diff = expensive.totalCost - cheapest.totalCost;
    final percent = (diff / expensive.totalCost) * 100;

    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.teal],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "💡 Best Saving Opportunity",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Buy at ${cheapest.marketName} saves "
                "${currency.format(diff)} (${percent.toStringAsFixed(1)}%)",
            style: const TextStyle(color: Colors.white),
          )
        ],
      ),
    );
  }

  // ======================================================
  // 📊 CHART
  // ======================================================

  Widget _buildChart(
      List<MarketTotalCost> data,
      String cheapestMarket,
      ) {

    final maxValue =
    data.map((e) => e.totalCost).reduce(max);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          maxY: maxValue * 1.2,
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(show: false),

          barGroups: data.asMap().entries.map((entry) {

            final index = entry.key;
            final item = entry.value;

            final isCheapest =
                item.marketName == cheapestMarket;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.totalCost,
                  width: 22,
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    colors: isCheapest
                        ? [Colors.green, Colors.lightGreen]
                        : [Colors.red, Colors.orange],
                  ),
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ======================================================
  // 🏪 MARKET CARD
  // ======================================================

  Widget _buildMarketCard(
      MarketTotalCost market,
      int index,
      MarketTotalCost cheapest,
      ) {

    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    final isBest = market.marketName == cheapest.marketName;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        gradient: isBest
            ? const LinearGradient(
          colors: [Colors.yellow, Colors.orange],
        )
            : const LinearGradient(
          colors: [Colors.white, Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.08),
          )
        ],
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Row(
            children: [
              _buildRankIcon(index),
              const SizedBox(width: 10),

              Text(
                market.marketName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          Text(
            currency.format(market.totalCost),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankIcon(int index) {

    switch (index) {
      case 0:
        return const Icon(Icons.emoji_events, color: Colors.amber);
      case 1:
        return const Icon(Icons.emoji_events, color: Colors.grey);
      case 2:
        return const Icon(Icons.emoji_events, color: Colors.brown);
      default:
        return const Icon(Icons.store, color: Colors.red);
    }
  }
}
