import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/market_total_cost.dart';
import '../../providers/price_provider.dart';
import '../../providers/shopping_provider.dart';

class ComparePriceScreen extends StatefulWidget {
  final int itemId;
  final String itemName;

  const ComparePriceScreen({
    super.key,
    required this.itemId,
    required this.itemName,
  });

  @override
  State<ComparePriceScreen> createState() => _ComparePriceScreenState();
}

class _ComparePriceScreenState extends State<ComparePriceScreen> {

  bool sortAsc = true;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final priceProvider = context.read<PriceProvider>();

      /// load compare data
      await priceProvider.loadMarketTotals();

      /// ⭐ generate smart products
      // await priceProvider.generateSuggestedItems();
    });
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {

    final priceProvider = context.watch<PriceProvider>();

    if (priceProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = [...priceProvider.totals];

    data.sort((a, b) =>
    sortAsc
        ? a.totalCost.compareTo(b.totalCost)
        : b.totalCost.compareTo(a.totalCost));

    final cheapest = data.isEmpty ? null : data.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text("🛒 Smart Market"),
        actions: [
          IconButton(
            icon: Icon(
                sortAsc
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

          /// ================= SMART SUGGESTIONS =================
          // _buildSuggestedSection(priceProvider),

          /// ================= CHART =================
          SizedBox(
            height: 220,
            child: _buildChart(data, cheapest?.marketName),
          ),

          /// ================= MARKET LIST =================
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
  // ⭐ SMART MARKET SECTION
  // =========================================================

  // Widget _buildSuggestedSection(PriceProvider provider) {
  //
  //   final shoppingProvider = context.read<ShoppingProvider>();
  //
  //   final currency = NumberFormat.currency(
  //     locale: 'vi_VN',
  //     symbol: '₫',
  //     decimalDigits: 0,
  //   );
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //
  //       const Padding(
  //         padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
  //         child: Text(
  //           "🔥 Gợi ý hôm nay",
  //           style: TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //       ),
  //
  //       // SizedBox(
  //       //   height: 110,
  //       //   child: ListView.builder(
  //       //     scrollDirection: Axis.horizontal,
  //       //     itemCount: provider.suggestedItems.length,
  //       //     itemBuilder: (_, index) {
  //       //
  //       //       final item = provider.suggestedItems[index];
  //       //
  //       //       return GestureDetector(
  //       //         onTap: () async {
  //       //
  //       //           /// ⭐ ADD AUTO TO SHOPPING LIST
  //       //           await shoppingProvider.addItem(
  //       //             item.name,
  //       //             item.price,
  //       //             1,
  //       //             1, // default category
  //       //           );
  //       //
  //       //           if (!mounted) return;
  //       //
  //       //           ScaffoldMessenger.of(context).showSnackBar(
  //       //             SnackBar(
  //       //               content: Text(
  //       //                   "Đã thêm ${item.name} vào danh sách 🛒"),
  //       //             ),
  //       //           );
  //       //         },
  //       //         child: Container(
  //       //           width: 160,
  //       //           margin: const EdgeInsets.only(left: 12),
  //       //           padding: const EdgeInsets.all(12),
  //       //           decoration: BoxDecoration(
  //       //             color: Colors.orange.shade50,
  //       //             borderRadius: BorderRadius.circular(16),
  //       //             border: Border.all(color: Colors.orange),
  //       //           ),
  //       //           child: Column(
  //       //             crossAxisAlignment: CrossAxisAlignment.start,
  //       //             children: [
  //       //
  //       //               Text(
  //       //                 item.name,
  //       //                 style: const TextStyle(
  //       //                   fontWeight: FontWeight.bold,
  //       //                 ),
  //       //               ),
  //       //
  //       //               const Spacer(),
  //       //
  //       //               Text(
  //       //                 item.market,
  //       //                 style: const TextStyle(
  //       //                   fontSize: 12,
  //       //                   color: Colors.grey,
  //       //                 ),
  //       //               ),
  //       //
  //       //               Text(
  //       //                 currency.format(item.price),
  //       //                 style: const TextStyle(
  //       //                   fontWeight: FontWeight.bold,
  //       //                   color: Colors.red,
  //       //                 ),
  //       //               ),
  //       //             ],
  //       //           ),
  //       //         ),
  //       //       );
  //       //     },
  //       //   ),
  //       // ),
  //
  //       const SizedBox(height: 10),
  //     ],
  //   );
  // }

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
          titlesData: const FlTitlesData(show: false),
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
                  color:
                  isCheapest ? Colors.green : Colors.red,
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
        color: highlight
            ? Colors.yellow.shade100
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? Colors.orange
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [

          Row(
            children: [
              Icon(
                highlight
                    ? Icons.star
                    : Icons.store,
                color: highlight
                    ? Colors.orange
                    : Colors.red,
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
