import 'package:flutter/material.dart';

import '../../domain/entities/shopping_item.dart';
import '../../domain/entities/category.dart';

import '../../domain/usecases/item/add_item_usecase.dart';
import '../../domain/usecases/item/delete_item_usecase.dart';
import '../../domain/usecases/item/get_items_usecase.dart';
import '../../domain/usecases/item/update_item_usecase.dart';
import '../../domain/usecases/price/get_cheapest_market_usecase.dart';
import '../../domain/usecases/price/get_prices_with_market_usecase.dart';
import '../../domain/usecases/price/get_total_cost_by_market_usecase.dart';
import '../../domain/usecases/category/get_categories_usecase.dart';
import '../../domain/usecases/price/seed_prices_usecase.dart';
import '../../domain/usecases/price/get_prices_by_item_usecase.dart';
import '../../core/utils/sync_service.dart';
import '../../core/utils/auth_service.dart';

class ShoppingProvider extends ChangeNotifier {
  final SyncService _syncService = SyncService();
  final AuthService _authService = AuthService();

  final AddItemUsecase addItemUsecase;
  final GetItemsUsecase getItemsUsecase;
  final UpdateItemUsecase updateItemUsecase;
  final DeleteItemUsecase deleteItemUsecase;

  final GetPricesWithMarketUsecase _getPrices;
  final GetCheapestMarketUsecase _getCheapest;
  final GetTotalCostByMarketUsecase _getTotalCost;
  
  final GetCategoriesUsecase _getCategories;
  final SeedPricesUsecase _seedPrices;
  final GetPricesByItemUsecase _getPricesByItem;

  ShoppingProvider(
      this.addItemUsecase,
      this.getItemsUsecase,
      this.updateItemUsecase,
      this.deleteItemUsecase,
      this._getPrices,
      this._getCheapest,
      this._getTotalCost,
      this._getCategories,
      this._seedPrices,
      this._getPricesByItem
      );

  /// =====================================================
  /// STATE
  /// =====================================================

  List<ShoppingItem> items = [];
  List<Category> categories = [];

  int? selectedCategoryId;

  /// itemId -> cheapest market
  final Map<int, Map<String, dynamic>?> cheapestMarkets = {};

  /// itemId -> all prices
  final Map<int, List<Map<String, dynamic>>> itemPrices = {};

  /// tránh generate nhiều lần
  final Set<int> _generatedItems = {};

  bool isLoading = false;

  /// =====================================================
  /// FILTERED ITEMS
  /// =====================================================

  List<ShoppingItem> get filteredItems {
    if (selectedCategoryId == null) return items;

    return items
        .where((e) => e.categoryId == selectedCategoryId)
        .toList();
  }

  void setCategoryFilter(int? categoryId) {
    selectedCategoryId = categoryId;
    notifyListeners();
  }

  /// =====================================================
  /// LOAD ITEMS
  /// =====================================================

  Future<void> loadItems() async {
    if (isLoading) return;
    isLoading = true;
    notifyListeners();

    try {
      items = await getItemsUsecase();
      await _loadCheapestMarkets();
    } catch (e) {
      debugPrint("Load Items Error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// =====================================================
  /// LOAD CHEAPEST MARKETS
  /// =====================================================

  Future<void> _loadCheapestMarkets() async {
    cheapestMarkets.clear();
    final futures = items.where((e) => e.id != null).map((item) async {
      final cheapest = await _getCheapest(item.id!);
      cheapestMarkets[item.id!] = cheapest == null ? null : {
        'market_name': cheapest.marketName,
        'price': cheapest.price,
      };
    });
    await Future.wait(futures);
  }

  /// =====================================================
  /// LOAD CATEGORIES
  /// =====================================================

  Future<void> loadCategories() async {
    categories = await _getCategories();
    notifyListeners();
  }

  String getCategoryName(int? categoryId) {

    if (categoryId == null) return "Unknown";

    final cat = categories.firstWhere(
          (e) => e.id == categoryId,
      orElse: () => Category(name: "Unknown"),
    );

    return cat.name;
  }

  /// =====================================================
  /// CRUD ITEM
  /// =====================================================

  Future<void> addItem(
      String name,
      double price,
      int quantity,
      int categoryId,
      ) async {

    final item = ShoppingItem(
      name: name,
      categoryId: categoryId,
      estimatedPrice: price,
      quantity: quantity,
    );

    await addItemUsecase(item);
    await loadItems();
    
    // Sync to cloud
    final newItem = items.firstWhere((e) => e.name == name && e.categoryId == categoryId);
    await _syncService.uploadItem(newItem);
  }

  Future<void> addItemsBatch(List<ShoppingItem> newItems) async {
    for (final item in newItems) {
      await addItemUsecase(item);
    }
    await loadItems();
  }

  int getCategoryIdByName(String name) {
    final cat = categories.firstWhere(
      (e) => e.name.toLowerCase().contains(name.toLowerCase()),
      orElse: () => categories.isNotEmpty ? categories.first : Category(id: 1, name: "Thực phẩm"),
    );
    return cat.id ?? 1;
  }

  Future<void> updateItem(ShoppingItem item) async {
    await updateItemUsecase(item);

    final index = items.indexWhere((e) => e.id == item.id);

    if (index != -1) {
      items[index] = item;
    }

    if (item.id != null) {
      final cheapest = await _getCheapest(item.id!);
      cheapestMarkets[item.id!] = cheapest == null ? null : {
        'market_name': cheapest.marketName,
        'price': cheapest.price,
      };
      
      // Sync to cloud
      await _syncService.uploadItem(item);
    }

    notifyListeners();
  }

  Future<void> deleteItem(int id) async {
    await deleteItemUsecase(id);

    items.removeWhere((e) => e.id == id);

    cheapestMarkets.remove(id);
    itemPrices.remove(id);
    _generatedItems.remove(id);

    // Sync to cloud
    await _syncService.deleteItem(id);

    notifyListeners();
  }

  /// =====================================================
  /// TOTAL COST
  /// =====================================================

  double getTotalEstimatedCost() {

    double total = 0;

    for (var item in filteredItems) {

      if (item.id == null) continue;

      final cheapest = cheapestMarkets[item.id!];

      final price =
          cheapest?['price'] ?? item.estimatedPrice;

      total += price * item.quantity;
    }

    return total;
  }

  /// =====================================================
  /// ⭐ AUTO GENERATE + LOAD PRICES
  /// =====================================================

  Future<void> loadItemPrices(int itemId) async {

    final item = items.firstWhere((e) => e.id == itemId);

    /// luôn đảm bảo có price
    await _seedPrices(itemId, item.estimatedPrice);

    final prices = await _getPrices(itemId);

    itemPrices[itemId] = prices.map((e) => {
      'marketId': e.marketId,
      'market_name': e.marketName,
      'price': e.price,
    }).toList();

    await findCheapestMarket(itemId);

    notifyListeners();
  }

  /// =====================================================
  /// FIND CHEAPEST
  /// =====================================================

  Future<void> findCheapestMarket(int itemId) async {

    final prices = itemPrices[itemId];

    if (prices == null || prices.isEmpty) {
      cheapestMarkets[itemId] = null;
      return;
    }

    prices.sort(
          (a, b) =>
          (a['price'] as num)
              .compareTo(b['price'] as num),
    );

    cheapestMarkets[itemId] = prices.first;
  }

  /// =====================================================
  /// USER TAP ITEM
  /// =====================================================

  Future<void> openItemPrice(ShoppingItem item) async {
    if (item.id == null) return;
    if (itemPrices.containsKey(item.id)) return;
    await loadItemPrices(item.id!);
  }

  /// =====================================================
  /// ⭐ CLOUD SYNC
  /// =====================================================

  Future<String> syncServiceTest() async {
    return await _syncService.testConnection();
  }

  Future<void> syncCloudToLocal() async {
    if (_authService.currentUser == null) return;

    try {
      // Timeout after 5 seconds to prevent getting stuck
      final cloudItems = await _syncService.listenToItems().first.timeout(const Duration(seconds: 5));
      
      bool hasNewData = false;
      for (var cloudItem in cloudItems) {
        final exists = items.any((local) => local.id == cloudItem.id);
        if (!exists) {
          await addItemUsecase(cloudItem);
          hasNewData = true;
        } else {
          // Update local if cloud is newer (simplified)
          await updateItemUsecase(cloudItem);
          hasNewData = true;
        }
      }
      
      if (hasNewData) {
        await loadItems();
      }
      
      // Also push local unique items to cloud
      await syncLocalToCloud();
      
    } catch (e) {
      debugPrint("Sync Error/Timeout: $e");
    }
  }

  Future<void> syncLocalToCloud() async {
    if (_authService.currentUser == null) return;
    for (var item in items) {
      await _syncService.uploadItem(item);
    }
  }
}

