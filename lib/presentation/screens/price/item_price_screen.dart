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

    /// ⭐ Delay 1 frame để context chắc chắn có Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PriceProvider>().loadPrices(widget.itemId);
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
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.prices.isEmpty) {
      return const Center(
        child: Text("Chưa có dữ liệu giá"),
      );
    }

    return ListView.builder(
      itemCount: provider.prices.length,
      itemBuilder: (_, index) {

        final price = provider.prices[index];

        final isCheapest =
            provider.cheapestMarket?.marketName ==
                price.marketName;

        return PriceCard(
          price: price,
          isCheapest: isCheapest,
        );
      },
    );
  }
}
