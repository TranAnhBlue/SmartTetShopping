import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../args/item_price_args.dart';
import '../../providers/shopping_provider.dart';
import '../../widgets/item_card.dart';
import '../../widgets/tet_countdown.dart';
import '../../widgets/spending_dashboard.dart';
import '../../../core/utils/location_service.dart';
import '../../../core/utils/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _petalController;
  late List<double> _petalPositions;
  int _currentPage = 1;
  final int _itemsPerPage = 2;

  List getPagedItems(List items) {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    if (start >= items.length) return [];
    return items.sublist(start, end > items.length ? items.length : end);
  }

  int getTotalPages(int totalItems) => (totalItems / _itemsPerPage).ceil();

  @override
  void initState() {
    super.initState();
    final provider = context.read<ShoppingProvider>();
    provider.loadItems();
    provider.loadCategories();
    provider.syncCloudToLocal();
    _petalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    final random = Random();
    _petalPositions = List.generate(10, (_) => random.nextDouble());
  }

  @override
  void dispose() {
    _petalController.dispose();
    super.dispose();
  }

  Widget _buildTetBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8B0000), Color(0xFFD32F2F), Color(0xFFFFC107)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(top: -120, left: -80, child: _buildGlow()),
        Positioned(bottom: -120, right: -80, child: _buildGlow()),
        AnimatedBuilder(animation: _petalController, builder: (_, __) => _buildPetals()),
      ],
    );
  }

  Widget _buildGlow() => Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Colors.orange.withOpacity(0.5), Colors.transparent])),
      );

  Widget _buildPetals() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: List.generate(_petalPositions.length, (index) {
        final progress = (_petalController.value + index * 0.12) % 1;
        return Positioned(
          top: progress * screenHeight,
          left: (_petalPositions[index] + sin(progress * 2 * pi) * 0.05) * screenWidth,
          child: Transform.rotate(
            angle: progress * 2 * pi,
            child: Transform.scale(
              scale: 0.8 + progress * 0.4,
              child: Text("🌸", style: TextStyle(fontSize: 24, color: Colors.white.withOpacity(0.6))),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTetBanner() => GestureDetector(
        onTap: () => LocationService().checkProximity(21.0285, 105.8542, "Chợ Đồng Xuân"),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Colors.red, Colors.orange]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black.withOpacity(0.2))],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("🧧", style: TextStyle(fontSize: 28)),
              SizedBox(width: 10),
              Text("Chúc Mừng Năm Mới 2026", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      );

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildActionItem("Lì xì 💸", Colors.orange, () => Navigator.pushNamed(context, '/lucky-money')),
          const SizedBox(width: 8),
          _buildActionItem("Lời chúc 💌", Colors.blue, () => Navigator.pushNamed(context, '/greetings')),
          const SizedBox(width: 8),
          _buildActionItem("Quét đơn 📸", Colors.green, () => Navigator.pushNamed(context, '/ocr-scanner')),
        ],
      ),
    );
  }

  Widget _buildActionItem(String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(ShoppingProvider provider) => SizedBox(
        height: 55,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          children: [
            _chip("Tất cả", provider.selectedCategoryId == null, () {
              provider.setCategoryFilter(null);
              setState(() => _currentPage = 1);
            }),
            ...provider.categories.map((cat) => _chip(cat.name, provider.selectedCategoryId == cat.id, () {
                  provider.setCategoryFilter(cat.id);
                  setState(() => _currentPage = 1);
                })),
          ],
        ),
      );

  Widget _chip(String text, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(text),
          selected: selected,
          selectedColor: Colors.orange,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(color: selected ? Colors.white : Colors.red, fontWeight: FontWeight.bold),
          onSelected: (_) => onTap(),
        ),
      );

  Widget _buildBarItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 75,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(int totalItems) {
    final totalPages = getTotalPages(totalItems);
    if (totalPages <= 1) return const SizedBox();
    return Container(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            child: Icon(Icons.chevron_left, size: 16, color: _currentPage > 1 ? Colors.white : Colors.white24),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              "$_currentPage / $totalPages",
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          GestureDetector(
            onTap: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
            child: Icon(Icons.chevron_right, size: 16, color: _currentPage < totalPages ? Colors.white : Colors.white24),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingProvider>();
    final pagedItems = getPagedItems(provider.filteredItems);
    return Scaffold(
      appBar: AppBar(
        title: const Text("🎆 Smart Tết Shopping"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Thoát",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Đăng xuất?"),
                  content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Đăng xuất")),
                  ],
                ),
              );
              if (confirm == true) {
                await AuthService().signOut();
                if (mounted) Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () => Navigator.pushNamed(context, "/add-item"),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 70, // Increased for labels
        color: const Color(0xFFD32F2F),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side
            Row(
              children: [
                _buildBarItem(Icons.bar_chart, "Thống kê", () => Navigator.pushNamed(context, '/compare-market')),
                _buildBarItem(Icons.cloud_sync, "Cloud", () async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Đang kiểm tra kết nối Backend...")));
                  final result = await provider.syncServiceTest();
                  scaffoldMessenger.showSnackBar(SnackBar(
                    content: Text(result == "SUCCESS" ? "✅ Kết nối Backend THÀNH CÔNG!" : "❌ $result"),
                    backgroundColor: result == "SUCCESS" ? Colors.green : Colors.red,
                  ));
                }),
              ],
            ),
            const SizedBox(width: 48), // FAB Notch
            // Right side
            Row(
              children: [
                _buildBarItem(Icons.auto_awesome, "AI Tết", () => Navigator.pushNamed(context, '/smart-ai')),
                _buildBarItem(Icons.document_scanner, "Quét đơn", () => Navigator.pushNamed(context, '/ocr-scanner')),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _buildTetBackground(),
          CustomScrollView(
            slivers: [
              if (provider.isLoading && provider.items.isEmpty)
                const SliverToBoxAdapter(child: LinearProgressIndicator(color: Colors.red)),
              
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildTetBanner(),
                    const TetCountdown(),
                    const SpendingDashboard(),
                    const SizedBox(height: 12),
                    _buildQuickActions(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoryFilterDelegate(
                  child: Container(
                    color: Colors.transparent, // Background will show through
                    child: _buildCategoryFilter(provider),
                  ),
                ),
              ),

              if (provider.items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      "🛒 Danh sách đang trống!\nBấm + hoặc Quét đơn để bắt đầu nhé.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final item = pagedItems[i];
                        return ItemCard(
                          item: item,
                          categoryName: provider.getCategoryName(item.categoryId),
                          cheapestMarket: item.id == null ? null : provider.cheapestMarkets[item.id!],
                          onTap: () async {
                            showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                            try {
                              await provider.openItemPrice(item);
                            } catch (e) {
                              debugPrint("Compare price error: $e");
                            }
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/item-price', arguments: ItemPriceArgs(itemId: item.id!, itemName: item.name));
                          },
                          onEdit: () => Navigator.pushNamed(context, '/edit-item', arguments: item),
                          onDelete: () => provider.deleteItem(item.id!),
                        );
                      },
                      childCount: pagedItems.length,
                    ),
                  ),
                ),

              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildPagination(provider.filteredItems.length),
                    const SizedBox(height: 80), // Padding for FAB
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _CategoryFilterDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 55.0;

  @override
  double get minExtent => 55.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

