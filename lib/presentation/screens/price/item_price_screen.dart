import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/price_provider.dart';
import '../../widgets/price_card.dart';

class ItemPriceScreen extends StatefulWidget {
  final int itemId;
  final String itemName;

  const ItemPriceScreen({
    super.key,
    required this.itemId,
    required this.itemName,
  });

  @override
  State<ItemPriceScreen> createState() => _ItemPriceScreenState();
}

class _ItemPriceScreenState extends State<ItemPriceScreen> {

  @override
  void initState() {
    super.initState();

    /// ✅ screen tự load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PriceProvider>()
          .loadPrices(widget.itemId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PriceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Giá ${widget.itemName}"),
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(PriceProvider provider) {

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.prices.isEmpty) {
      return const Center(
        child: Text("Chưa có dữ liệu giá"),
      );
    }

    return Column(
      children: [

        /// ===============================
        /// ⭐ BUYING SUGGESTION
        /// ===============================
        if (provider.cheapestMarket != null)
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb,
                    color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    provider.buyingSuggestion,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),

        /// ===============================
        /// PRICE LIST
        /// ===============================
        Expanded(
          child: ListView.builder(
            itemCount: provider.prices.length,
            itemBuilder: (_, index) {

              final price = provider.prices[index];

              return PriceCard(
                price: price,
                isCheapest:
                provider.isCheapest(
                    price.marketName),
              );
            },
          ),
        ),
      ],
    );
  }
}