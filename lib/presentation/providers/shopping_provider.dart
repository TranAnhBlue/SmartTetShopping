import 'package:flutter/material.dart';

import '../../data/local_db/dao/price_dao.dart';
import '../../data/local_db/database_helper.dart';

import '../../domain/entities/shopping_item.dart';
import '../../domain/entities/category.dart';

import '../../domain/usecases/item/add_item_usecase.dart';
import '../../domain/usecases/item/delete_item_usecase.dart';
import '../../domain/usecases/item/get_items_usecase.dart';
import '../../domain/usecases/item/update_item_usecase.dart';
import '../../domain/usecases/price/get_cheapest_market_usecase.dart';
import '../../domain/usecases/price/get_prices_with_market_usecase.dart';
import '../../domain/usecases/price/get_total_cost_by_market_usecase.dart';

class ShoppingProvider extends ChangeNotifier {

  final AddItemUsecase addItemUsecase;
  final GetItemsUsecase getItemsUsecase;
  final UpdateItemUsecase updateItemUsecase;
  final DeleteItemUsecase deleteItemUsecase;

  final GetPricesWithMarketUsecase _getPrices;
  final GetCheapestMarketUsecase _getCheapest;
  final GetTotalCostByMarketUsecase _getTotalCost;

  final PriceDao priceDao = PriceDao();

  ShoppingProvider(
      this.addItemUsecase,
      this.getItemsUsecase,
      this.updateItemUsecase,
      this.deleteItemUsecase,
      this._getPrices,
      this._getCheapest,
      this._getTotalCost
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

    isLoading = true;
    notifyListeners();

    items = await getItemsUsecase();

    await _loadCheapestMarkets();

    isLoading = false;
    notifyListeners();
  }

  /// =====================================================
  /// LOAD CHEAPEST MARKETS
  /// =====================================================

  Future<void> _loadCheapestMarkets() async {

    cheapestMarkets.clear();

    for (final item in items) {

      if (item.id == null) continue;

      final cheapest =
      await priceDao.getCheapestMarket(item.id!);

      cheapestMarkets[item.id!] = cheapest;
    }
  }

  /// =====================================================
  /// LOAD CATEGORIES
  /// =====================================================

  Future<void> loadCategories() async {
    categories =
    await DatabaseHelper.instance.getCategories();

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
  }

  Future<void> updateItem(ShoppingItem item) async {

    await updateItemUsecase(item);

    final index = items.indexWhere((e) => e.id == item.id);

    if (index != -1) {
      items[index] = item;
    }

    if (item.id != null) {
      cheapestMarkets[item.id!] =
      await priceDao.getCheapestMarket(item.id!);
    }

    notifyListeners();
  }

  Future<void> deleteItem(int id) async {

    await deleteItemUsecase(id);

    items.removeWhere((e) => e.id == id);

    cheapestMarkets.remove(id);
    itemPrices.remove(id);
    _generatedItems.remove(id);

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
    await DatabaseHelper.instance.seedPricesForItem(
      itemId,
      item.estimatedPrice,
    );

    final prices =
    await priceDao.getPricesByItem(itemId);

    itemPrices[itemId] = prices;

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


}