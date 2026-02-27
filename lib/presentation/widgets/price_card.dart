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
      child: ListTile(
        title: Text(
          price.marketName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("Giá: ${price.price.toStringAsFixed(0)} đ"),
        trailing: isCheapest
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }
}
