import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ai/smart_shopping_ai.dart';
import '../../providers/shopping_provider.dart';

class SmartShoppingAIScreen extends StatefulWidget {
  const SmartShoppingAIScreen({super.key});

  @override
  State<SmartShoppingAIScreen> createState()
  => _SmartShoppingAIScreenState();
}

class _SmartShoppingAIScreenState
    extends State<SmartShoppingAIScreen> {

  bool _loading = true;
  List suggestions = [];

  @override
  void initState() {
    super.initState();

    /// chạy sau khi context sẵn sàng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareAI();
    });
  }

  // =====================================================
  // 🤖 PREPARE AI DATA (FIXED)
  // =====================================================
  Future<void> _prepareAI() async {

    final provider = context.read<ShoppingProvider>();

    /// đảm bảo items có
    if (provider.items.isEmpty) {
      await provider.loadItems();
    }

    /// ✅ chạy song song (KHÔNG block)
    await Future.wait(
      provider.items
          .where((e) => e.id != null)
          .map((item) {

        if (!provider.itemPrices.containsKey(item.id)) {
          return provider.openItemPrice(item);
        }

        return Future.value();
      }),
    );

    /// AI generate
    suggestions = SmartShoppingAI.generateSuggestions(
      provider.items,
      provider.itemPrices,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("🤖 Smart Shopping AI"),
      ),

      body: _loading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text("AI đang phân tích giỏ hàng..."),
          ],
        ),
      )
          : suggestions.isEmpty
          ? const Center(
        child: Text("Chưa đủ dữ liệu AI"),
      )
          : ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (_, i) {

          final s = suggestions[i];

          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(
                Icons.auto_awesome,
                color: Colors.orange,
              ),
              title: Text(
                s.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle:
              Text("Nên mua tại ${s.market}"),
              trailing: Text(
                "${s.price.toStringAsFixed(0)}₫",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}