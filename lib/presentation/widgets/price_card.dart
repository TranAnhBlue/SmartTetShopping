import 'package:flutter/material.dart';
import '../../domain/entities/market_price.dart';

class PriceCard extends StatelessWidget {

  final MarketPrice price;
  final bool isCheapest;

  const PriceCard({
    super.key,
    required this.price,
    required this.isCheapest,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      color: isCheapest ? Colors.green.shade100 : null,
      child: ListTile(
        title: Text(price.marketName),
        subtitle: Text("Giá: ${price.price} đ"),
        trailing: isCheapest
            ? const Icon(Icons.star, color: Colors.green)
            : null,
      ),
    );
  }
}
