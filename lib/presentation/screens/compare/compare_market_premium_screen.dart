import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/market_total_cost.dart';
import '../../providers/price_provider.dart';
import '../map/map_screen.dart';

class CompareMarketPremiumScreen extends StatefulWidget {
  const CompareMarketPremiumScreen({super.key});

  @override
  State<CompareMarketPremiumScreen> createState()
  => _CompareMarketPremiumScreenState();
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

    /// load data sau khi build xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PriceProvider>().loadMarketTotals();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {

    final provider = context.watch<PriceProvider>();

    if (provider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("📊 Compare Markets")),
        body: Stack(
          children: [
            _buildTetBackground(),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }

    final data = [...provider.totals];

    if (data.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("📊 Compare Markets")),
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
        : b.totalCost.compareTo(a.totalCost));

    // Always calculate cheapest and expensive by their actual values, not their current sorted position
    final sortedData = [...data]..sort((a, b) => a.totalCost.compareTo(b.totalCost));
    final cheapest = sortedData.first;
    final expensive = sortedData.last;

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

  // ================= INSIGHT =================

  Widget _buildInsight(
      MarketTotalCost cheapest,
      MarketTotalCost expensive,
      ) {

    final diff = expensive.totalCost - cheapest.totalCost;

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
      child: Text(
        "💡 Mua tại ${cheapest.marketName} tiết kiệm được ${currency.format(diff)}",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ================= CHART =================

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

  // ================= CARD =================

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

    final isBest =
        market.marketName == cheapest.marketName;

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBest ? Colors.yellow.shade200 : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Row(
            children: [
              Icon(
                index == 0
                    ? Icons.emoji_events
                    : Icons.store,
                color: Colors.orange,
              ),
              const SizedBox(width: 10),
              Text(
                market.marketName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          Row(
            children: [
              Text(
                currency.format(market.totalCost),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.directions, color: Colors.blue),
                tooltip: "Chỉ đường",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapScreen(
                        destination: market.marketName,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}