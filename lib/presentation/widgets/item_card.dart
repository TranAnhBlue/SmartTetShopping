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

    /// giá ưu tiên từ market rẻ nhất
    final price =
        (cheapestMarket?['price'] as num?)?.toDouble()
            ?? item.estimatedPrice;

    final cheapestMarketName =
    cheapestMarket?['market_name'];

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),

      /// ⭐ dùng InkWell để có ripple effect
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Row(
            children: [

              /// ICON
              CircleAvatar(
                backgroundColor: Colors.red.shade100,
                child: const Icon(
                  Icons.shopping_basket,
                  color: Colors.red,
                ),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                      "Giá: ${currency.format(price)}\n"
                          "Số lượng: ${item.quantity}",
                    ),

                    ///  hiển thị nơi rẻ nhất (NEW)
                    if (cheapestMarketName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "💡 Rẻ nhất: $cheapestMarketName",
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

                  /// tổng tiền
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
    );
  }
}