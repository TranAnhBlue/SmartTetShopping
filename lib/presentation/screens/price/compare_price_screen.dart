import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/market_total_cost.dart';
import '../../providers/price_provider.dart';

class ComparePriceScreen extends StatefulWidget {
  const ComparePriceScreen({super.key});

  @override
  State<ComparePriceScreen> createState() => _ComparePriceScreenState();
}

class _ComparePriceScreenState extends State<ComparePriceScreen> {

  bool sortAsc = true;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<PriceProvider>().loadMarketTotals();
    });
  }

  @override
  Widget build(BuildContext context) {

    final provider = context.watch<PriceProvider>();

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    /// ⭐ FIX: dùng totals đúng field provider
    final data = [...provider.totals];

    /// ⭐ FIX: dùng totalCost
    data.sort((a, b) =>
    sortAsc
        ? a.totalCost.compareTo(b.totalCost)
        : b.totalCost.compareTo(a.totalCost)
    );

    final cheapest = data.isEmpty ? null : data.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text("📊 So sánh giá theo chợ"),
        actions: [
          IconButton(
            icon: Icon(sortAsc
                ? Icons.arrow_upward
                : Icons.arrow_downward),
            onPressed: () {
              setState(() => sortAsc = !sortAsc);
            },
          )
        ],
      ),

      body: Column(
        children: [

          /// ===== CHART =====
          SizedBox(
            height: 220,
            child: _buildChart(data, cheapest?.marketName),
          ),

          /// ===== LIST =====
          Expanded(
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (_, i) {

                final item = data[i];
                final isCheapest =
                    item.marketName == cheapest?.marketName;

                return _buildMarketCard(item, isCheapest);
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CHART
  // =========================================================

  Widget _buildChart(
      List<MarketTotalCost> data,
      String? cheapestMarket,
      ) {

    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
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
                  width: 20,
                  color: isCheapest
                      ? Colors.green
                      : Colors.red,
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // =========================================================
  // CARD
  // =========================================================

  Widget _buildMarketCard(
      MarketTotalCost market,
      bool highlight,
      ) {

    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? Colors.yellow.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? Colors.orange : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Row(
            children: [
              Icon(
                highlight ? Icons.star : Icons.store,
                color: highlight ? Colors.orange : Colors.red,
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
}
