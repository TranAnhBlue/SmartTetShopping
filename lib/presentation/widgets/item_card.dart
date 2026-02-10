import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/shopping_item.dart';

class ItemCard extends StatelessWidget {
  final ShoppingItem item;
  final Map<String, dynamic>? cheapestMarket;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String categoryName;

  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.cheapestMarket,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    final price = (cheapestMarket?['price'] as num?)?.toDouble()
        ?? item.estimatedPrice;


    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),

        leading: CircleAvatar(
          backgroundColor: Colors.red.shade100,
          child: const Icon(Icons.shopping_basket, color: Colors.red),
        ),

        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: Text(
          "Giá: ${currency.format(price)}\n"
              "Số lượng: ${item.quantity}",
        ),

        /// ⭐ trailing có edit + delete
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              currency.format(price * item.quantity),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onEdit,
                  child: const Icon(Icons.edit, size: 20),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete, size: 20, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
