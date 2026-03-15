import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/shopping_provider.dart';
import '../../../domain/entities/shopping_item.dart';
import '../../../core/utils/currency_utils.dart';

class RitualChecklistScreen extends StatelessWidget {
  const RitualChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rituals = [
      {
        'name': 'Cúng Tất niên (Chiều 30 Tết) 🍱',
        'items': [
          {'name': 'Gà trống luộc ngậm hoa hồng', 'price': 350000, 'cat': 'Thực phẩm'},
          {'name': 'Bánh chưng / Bánh tét', 'price': 80000, 'cat': 'Thực phẩm'},
          {'name': 'Giò lụa / Giò xào', 'price': 200000, 'cat': 'Thực phẩm'},
          {'name': 'Nem rán truyền thống', 'price': 150000, 'cat': 'Thực phẩm'},
          {'name': 'Canh măng khô hầm chân giò', 'price': 250000, 'cat': 'Thực phẩm'},
          {'name': 'Miến nấu lòng gà', 'price': 100000, 'cat': 'Thực phẩm'},
          {'name': 'Dưa hành / Kiệu muối', 'price': 50000, 'cat': 'Thực phẩm'},
          {'name': 'Xôi gấc đỏ tươi', 'price': 60000, 'cat': 'Thực phẩm'},
        ]
      },
      {
        'name': 'Cúng Giao thừa (Trong nhà & Ngoài trời) 🎇',
        'items': [
          {'name': 'Gà trống thiến luộc', 'price': 400000, 'cat': 'Thực phẩm'},
          {'name': 'Mâm ngũ quả tươi', 'price': 450000, 'cat': 'Thực phẩm'},
          {'name': 'Hoa cúc / Hoa ly tươi', 'price': 120000, 'cat': 'Trang trí'},
          {'name': 'Trầu cau, chè thuốc', 'price': 50000, 'cat': 'Đồ cúng'},
          {'name': 'Rượu nếp ngon', 'price': 80000, 'cat': 'Đồ uống'},
          {'name': 'Muối gạo, nước lọc', 'price': 10000, 'cat': 'Đồ cúng'},
          {'name': 'Giấy tiền vàng mã Giao thừa', 'price': 50000, 'cat': 'Đồ cúng'},
          {'name': 'Nến cốc / Đăng chiêu', 'price': 30000, 'cat': 'Đồ cúng'},
        ]
      },
      {
        'name': 'Cúng Tân niên (Sáng Mùng 1) 🧧',
        'items': [
          {'name': 'Thịt đông chân giò', 'price': 150000, 'cat': 'Thực phẩm'},
          {'name': 'Canh khổ qua rừng (Cầu may)', 'price': 120000, 'cat': 'Thực phẩm'},
          {'name': 'Dưa món / Rau củ ngâm', 'price': 40000, 'cat': 'Thực phẩm'},
          {'name': 'Bánh kẹo, mứt Tết cao cấp', 'price': 600000, 'cat': 'Bánh kẹo'},
          {'name': 'Trà Thái Nguyên xanh', 'price': 150000, 'cat': 'Đồ uống'},
          {'name': 'Hạt dưa / Hạt hướng dương', 'price': 100000, 'cat': 'Bánh kẹo'},
        ]
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mâm cỗ Tết truyền thống"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.red, Colors.orange]),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rituals.length,
        itemBuilder: (context, index) {
          final ritual = rituals[index];
          final items = ritual['items'] as List<Map<String, dynamic>>;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 4,
            child: ExpansionTile(
              title: Text(
                ritual['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              subtitle: Text("${items.length} món cần chuẩn bị"),
              children: [
                ...items.map((item) => ListTile(
                  dense: true,
                  title: Text(item['name']),
                  trailing: Text(CurrencyUtils.format((item['price'] as num).toDouble())),
                )),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _addAllToShoppingList(context, items),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text("Thêm tất cả vào danh sách"),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  void _addAllToShoppingList(BuildContext context, List<Map<String, dynamic>> items) {
    final provider = context.read<ShoppingProvider>();
    
    final List<ShoppingItem> newItems = [];
    
    for (var itemData in items) {
      String catName = itemData['cat'] as String;
      int? catId = provider.categories
          .where((c) => c.name.contains(catName))
          .firstOrNull?.id;
      
      newItems.add(ShoppingItem(
        name: itemData['name'] as String,
        estimatedPrice: (itemData['price'] as num).toDouble(),
        categoryId: catId,
        quantity: 1,
      ));
    }
    
    provider.addItemsBatch(newItems);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Đã thêm ${items.length} món vào danh sách!"),
        backgroundColor: Colors.green,
      ),
    );
  }
}
