import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../args/item_price_args.dart';
import '../../providers/shopping_provider.dart';
import '../../widgets/item_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final provider = context.read<ShoppingProvider>();
      provider.loadItems();
      provider.loadCategories();
    });
  }

  Widget _buildTetBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFB71C1C), // đỏ đậm
            Color(0xFFD32F2F),
            Color(0xFFFFC107), // vàng Tết
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [

          /// 🌟 Glow ánh sáng
          Positioned(
            top: -100,
            left: -50,
            child: _buildGlow(),
          ),

          Positioned(
            bottom: -120,
            right: -60,
            child: _buildGlow(),
          ),

          /// 🌸 Pattern hoa mai nhẹ
          Opacity(
            opacity: 0.08,
            child: Center(
              child: Text(
                "🌸 🌸 🌸 🌸 🌸",
                style: TextStyle(fontSize: 120),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlow() {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.orange.withOpacity(0.5),
            Colors.transparent,
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    final provider = context.watch<ShoppingProvider>();

    final total = provider.getTotalEstimatedCost();

    return Scaffold(
      appBar: AppBar(
        title: const Text("🧧 Chúc mừng năm mới 2026"),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.pushNamed(context, '/market-compare');
            },
          )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, "/add-item");
        },
      ),

        body: Stack(
          children: [

            /// 🎆 BACKGROUND TẾT
            _buildTetBackground(),

            /// Nội dung cũ
            provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              children: [

                _buildSummary(total),

                _buildCategoryFilter(provider),

                Expanded(
                  child: provider.filteredItems.isEmpty
                      ? const Center(child: Text("Chưa có món nào"))
                      : ListView.builder(
                    itemCount: provider.filteredItems.length,
                    itemBuilder: (_, i) {

                      final item = provider.filteredItems[i];

                      return ItemCard(
                        item: item,
                        categoryName:
                        provider.getCategoryName(item.categoryId),
                        cheapestMarket: item.id == null
                            ? null
                            : provider.cheapestMarkets[item.id!],
                        onTap: () {
                          if (item.id == null) return;

                          Navigator.pushNamed(
                            context,
                            '/item-price',
                            arguments: ItemPriceArgs(
                              itemId: item.id!,
                              itemName: item.name,
                            ),
                          );
                        },
                        onEdit: () {
                          Navigator.pushNamed(
                            context,
                            '/edit-item',
                            arguments: item,
                          );
                        },
                        onDelete: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Xóa sản phẩm"),
                              content: const Text(
                                  "Bạn chắc chắn muốn xóa sản phẩm này?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Hủy"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    provider.deleteItem(item.id!);
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Xóa"),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ));
        }

        /// ===============================
  /// SUMMARY CARD
  /// ===============================
  Widget _buildSummary(double total) {

    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "Tổng chi phí dự kiến",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            currency.format(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// CATEGORY FILTER
  /// ===============================
  Widget _buildCategoryFilter(ShoppingProvider provider) {

    return SizedBox(
      height: 55,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        children: [

          /// ALL
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text("Tất cả"),
              selected: provider.selectedCategoryId == null,
              onSelected: (_) => provider.setCategoryFilter(null),
            ),
          ),

          ...provider.categories.map((cat) {

            final id = cat.id;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(cat.name),
                selected: provider.selectedCategoryId == id,
                onSelected: (_) => provider.setCategoryFilter(id),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

}
