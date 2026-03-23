import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/utils/currency_utils.dart';
import '../../domain/entities/shopping_item.dart';

class ItemCard extends StatelessWidget {
  final ShoppingItem item;
  final Map<String, dynamic>? cheapestMarket;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleBought;
  final String categoryName;

  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleBought,
    this.cheapestMarket,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final price =
        (cheapestMarket?['price'] as num?)?.toDouble()
            ?? item.estimatedPrice;

    final cheapestMarketName = cheapestMarket?['market_name'];
    final bought = item.isBought;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: bought ? 0.6 : 1.0,
      child: Card(
        elevation: bought ? 0 : 3,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: bought ? Colors.green.shade50 : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: bought
              ? BorderSide(color: Colors.green.shade300, width: 1.5)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [

                /// ✅ Checkbox
                GestureDetector(
                  onTap: onToggleBought,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: bought ? Colors.green : Colors.transparent,
                      border: Border.all(
                        color: bought ? Colors.green : Colors.grey.shade400,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: bought
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),

                const SizedBox(width: 12),

                /// ✅ Product Image
                if (item.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: item.imageUrl!.startsWith('http')
                        ? Image.network(
                            item.imageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.shopping_basket, size: 30),
                          )
                        : Image.file(
                            File(item.imageUrl!),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.shopping_basket, size: 30),
                          ),
                  )
                else
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.shopping_basket, color: Colors.grey.shade400),
                  ),

                const SizedBox(width: 12),

                /// ===== INFO =====
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// tên sản phẩm
                      Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: bought
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: bought ? Colors.grey : null,
                        ),
                      ),

                      const SizedBox(height: 4),

                      /// category
                      Text(
                        categoryName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 6),

                      /// giá + số lượng
                      Text(
                        "Dự kiến: ${CurrencyUtils.format(item.estimatedPrice)}\n"
                        "Số lượng: ${item.quantity}",
                        style: TextStyle(
                          decoration: bought ? TextDecoration.lineThrough : null,
                          color: bought ? Colors.grey : null,
                        ),
                      ),

                      if (cheapestMarketName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "💡 Rẻ nhất: ${CurrencyUtils.format(price)} ($cheapestMarketName)",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                /// ===== RIGHT SIDE =====
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Text(
                      CurrencyUtils.format(price * item.quantity),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: bought ? Colors.green : Colors.red,
                        decoration: bought ? TextDecoration.lineThrough : null,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        /// EDIT
                        InkWell(
                          onTap: onEdit,
                          child: const Icon(Icons.edit, size: 20),
                        ),

                        const SizedBox(width: 12),

                        /// DELETE
                        InkWell(
                          onTap: onDelete,
                          child: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
