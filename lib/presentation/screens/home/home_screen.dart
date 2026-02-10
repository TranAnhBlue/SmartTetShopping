import 'dart:math';
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _petalController;
  late List<double> _petalPositions;
  int _currentPage = 1;
  final int _itemsPerPage = 3;

  List getPagedItems(List items) {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;

    if (start >= items.length) return [];

    return items.sublist(
      start,
      end > items.length ? items.length : end,
    );
  }

  int getTotalPages(int totalItems) {
    return (totalItems / _itemsPerPage).ceil();
  }


  // ================= INIT =================

  @override
  void initState() {
    super.initState();

    final provider = context.read<ShoppingProvider>();
    provider.loadItems();
    provider.loadCategories();

    _petalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    /// ⭐ FIX random position only once
    final random = Random();
    _petalPositions =
        List.generate(10, (_) => random.nextDouble());
  }

  @override
  void dispose() {
    _petalController.dispose();
    super.dispose();
  }

  // =====================================================
  // 🌸 BACKGROUND TẾT
  // =====================================================

  Widget _buildTetBackground() {
    return Stack(
      children: [

        /// Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF8B0000),
                Color(0xFFD32F2F),
                Color(0xFFFFC107),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        Positioned(top: -120, left: -80, child: _buildGlow()),
        Positioned(bottom: -120, right: -80, child: _buildGlow()),

        /// Petals animation
        AnimatedBuilder(
          animation: _petalController,
          builder: (_, __) => _buildPetals(),
        ),
      ],
    );
  }

  Widget _buildGlow() {
    return Container(
      width: 280,
      height: 280,
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

  // =====================================================
  // 🌸 PETAL ANIMATION
  // =====================================================

  Widget _buildPetals() {

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: List.generate(_petalPositions.length, (index) {

        final progress =
            (_petalController.value + index * 0.12) % 1;

        return Positioned(
          top: progress * screenHeight,

          /// sway left-right
          left: (_petalPositions[index] +
              sin(progress * 2 * pi) * 0.05) * screenWidth,

          child: Transform.rotate(
            angle: progress * 2 * pi,
            child: Transform.scale(
              scale: 0.8 + progress * 0.4,
              child: const Text(
                "🌸",
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
        );
      }),
    );
  }

  // =====================================================
  // HEADER BANNER
  // =====================================================

  Widget _buildTetBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.red, Colors.orange],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withOpacity(0.2),
          )
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("🧧", style: TextStyle(fontSize: 28)),
          SizedBox(width: 10),
          Text(
            "Chúc Mừng Năm Mới 2026",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }

  // =====================================================
  // SUMMARY CARD
  // =====================================================

  Widget _buildSummary(double total) {

    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFEF5350)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 15,
            color: Colors.black.withOpacity(0.25),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Tổng chi phí dự kiến",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            currency.format(total),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }

  // =====================================================
  // CATEGORY FILTER
  // =====================================================

  Widget _buildCategoryFilter(ShoppingProvider provider) {

    return SizedBox(
      height: 55,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        children: [

          _chip(
            "Tất cả",
            provider.selectedCategoryId == null,
                () {
              provider.setCategoryFilter(null);
              setState(() => _currentPage = 1);
            },
          ),

          ...provider.categories.map((cat) => _chip(
            cat.name,
            provider.selectedCategoryId == cat.id,
                () {
              provider.setCategoryFilter(cat.id);
              setState(() => _currentPage = 1);
            },
          )),
        ],
      ),
    );
  }

  Widget _chip(String text, bool selected, VoidCallback onTap) {

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(text),
        selected: selected,
        selectedColor: Colors.orange,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.red,
          fontWeight: FontWeight.bold,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _buildPagination(int totalItems) {

    final totalPages = getTotalPages(totalItems);

    if (totalPages <= 1) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () => setState(() => _currentPage--)
                : null,
          ),

          Text(
            "Page $_currentPage / $totalPages",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages
                ? () => setState(() => _currentPage++)
                : null,
          ),
        ],
      ),
    );
  }


  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {

    final provider = context.watch<ShoppingProvider>();
    final total = provider.getTotalEstimatedCost();
    final pagedItems = getPagedItems(provider.filteredItems);

    return Scaffold(
      appBar: AppBar(
        title: const Text("🎆 Smart Tết Shopping"),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () =>
                Navigator.pushNamed(context, '/compare-market'),
          )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
        onPressed: () =>
            Navigator.pushNamed(context, "/add-item"),
      ),

      body: Stack(
        children: [

          _buildTetBackground(),

          provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [

              _buildTetBanner(),
              _buildSummary(total),
              const SizedBox(height: 12),
              _buildCategoryFilter(provider),

              Expanded(
                child: Column(
                  children: [

                    Expanded(
                      child: ListView.builder(
                        itemCount: pagedItems.length,
                        itemBuilder: (_, i) {

                          final item = pagedItems[i];

                          return ItemCard(
                            item: item,
                            categoryName:
                            provider.getCategoryName(item.categoryId),
                            cheapestMarket: item.id == null
                                ? null
                                : provider.cheapestMarkets[item.id!],
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/item-price',
                                arguments: ItemPriceArgs(
                                  itemId: item.id!,
                                  itemName: item.name,
                                ),
                              );
                            },
                            onEdit: () =>
                                Navigator.pushNamed(
                                    context,
                                    '/edit-item',
                                    arguments: item),
                            onDelete: () =>
                                provider.deleteItem(item.id!),
                          );
                        },
                      ),
                    ),

                    _buildPagination(provider.filteredItems.length),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

}
