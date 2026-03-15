import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/shopping_provider.dart';
import '../../../domain/entities/shopping_item.dart';

class ScanPreviewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> scannedItems;

  const ScanPreviewScreen({super.key, required this.scannedItems});

  @override
  State<ScanPreviewScreen> createState() => _ScanPreviewScreenState();
}

class _ScanPreviewScreenState extends State<ScanPreviewScreen> {
  late List<Map<String, dynamic>> items;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    // Create a mutable copy and handle Gemini field names
    items = widget.scannedItems.map((item) {
      final String name = item['name'] ?? 'Sản phẩm mới';
      final double price = (item['estimated_price'] ?? item['price'] ?? 0.0).toDouble();
      final int qty = (item['quantity'] ?? 1).toInt();
      final String catName = item['category'] ?? 'Thực phẩm';
      
      return {
        'name': name,
        'price': price,
        'quantity': qty,
        'selected': true,
        'categoryId': context.read<ShoppingProvider>().getCategoryIdByName(catName),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kết quả quét hóa đơn"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return CheckboxListTile(
                  title: TextFormField(
                    initialValue: item['name'],
                    decoration: const InputDecoration(labelText: "Tên món"),
                    onChanged: (val) => item['name'] = val,
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: item['price'].toString(),
                          decoration: const InputDecoration(labelText: "Giá"),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => item['price'] = double.tryParse(val) ?? 0.0,
                        ),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<int>(
                        value: item['categoryId'],
                        items: const [
                          DropdownMenuItem(value: 1, child: Text("Thực phẩm")),
                          DropdownMenuItem(value: 2, child: Text("Đồ cúng")),
                          DropdownMenuItem(value: 3, child: Text("Trang trí")),
                          DropdownMenuItem(value: 4, child: Text("Đồ uống")),
                        ],
                        onChanged: (val) {
                          setState(() {
                            item['categoryId'] = val;
                          });
                        },
                      ),
                    ],
                  ),
                  value: item['selected'],
                  onChanged: (val) {
                    setState(() {
                      item['selected'] = val;
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _saveItems,
                child: isSaving 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Thêm vào danh sách"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveItems() async {
    setState(() => isSaving = true);
    final provider = context.read<ShoppingProvider>();
    
    final selectedData = items.where((item) => item['selected'] == true).toList();
    
    final List<ShoppingItem> newItems = selectedData.map((data) => ShoppingItem(
      name: data['name'],
      estimatedPrice: data['price'],
      quantity: data['quantity'] ?? 1,
      categoryId: data['categoryId'],
    )).toList();
    
    await provider.addItemsBatch(newItems);
    
    if (mounted) {
      Navigator.pop(context); // Close preview
      Navigator.pop(context); // Close add item screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã thêm ${newItems.length} món từ hóa đơn!")),
      );
    }
  }
}
