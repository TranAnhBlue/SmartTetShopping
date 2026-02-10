import 'package:flutter/material.dart';
import '../../data/local_db/dao/price_dao.dart';
import '../../data/local_db/database_helper.dart';
import '../../domain/entities/shopping_item.dart';
import '../../domain/usecases/item/add_item_usecase.dart';
import '../../domain/usecases/item/delete_item_usecase.dart';
import '../../domain/usecases/item/get_items_usecase.dart';
import '../../domain/usecases/item/update_item_usecase.dart';
import '../../domain/entities/category.dart';

class ShoppingProvider extends ChangeNotifier {

  final AddItemUsecase addItemUsecase;
  final GetItemsUsecase getItemsUsecase;
  final UpdateItemUsecase updateItemUsecase;
  final DeleteItemUsecase deleteItemUsecase;

  final PriceDao priceDao = PriceDao();

  ShoppingProvider(
      this.addItemUsecase,
      this.getItemsUsecase,
      this.updateItemUsecase,
      this.deleteItemUsecase,
      );

  /// ===============================
  /// STATE
  /// ===============================

  List<ShoppingItem> items = [];

  /// ⭐ FIX TYPE
  List<Category> categories = [];

  int? selectedCategoryId;

  Map<int, Map<String, dynamic>?> cheapestMarkets = {};

  bool isLoading = false;

  /// ===============================
  /// FILTERED ITEMS
  /// ===============================
  List<ShoppingItem> get filteredItems {

    if (selectedCategoryId == null) return items;

    return items
        .where((item) => item.categoryId == selectedCategoryId)
        .toList();
  }

  /// ===============================
  /// SET CATEGORY FILTER
  /// ===============================
  void setCategoryFilter(int? categoryId) {

    selectedCategoryId = categoryId;
    notifyListeners();
  }

  /// ===============================
  /// LOAD ITEMS + CHEAPEST MARKET
  /// ===============================
  Future<void> loadItems() async {

    isLoading = true;
    notifyListeners();

    items = await getItemsUsecase();

    await _loadCheapestMarkets();

    isLoading = false;
    notifyListeners();
  }

  /// ===============================
  /// LOAD CHEAPEST MARKETS
  /// ===============================
  Future<void> _loadCheapestMarkets() async {

    cheapestMarkets.clear();

    await Future.wait(
      items.map((item) async {

        if (item.id == null) return;

        final cheapest = await priceDao.getCheapestMarket(item.id!);

        cheapestMarkets[item.id!] = cheapest;
      }),
    );
  }

  /// ===============================
  /// LOAD CATEGORIES
  /// ===============================
  Future<void> loadCategories() async {

    categories = await DatabaseHelper.instance.getCategories();

    notifyListeners();
  }

  /// ===============================
  /// GET CATEGORY NAME
  /// ===============================
  String getCategoryName(int? categoryId) {

    if (categoryId == null) return "Unknown";

    final cat = categories.firstWhere(
          (e) => e.id == categoryId,
      orElse: () => Category(name: "Unknown"),
    );

    return cat.name;
  }

  /// ===============================
  /// ADD ITEM
  /// ===============================
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

  /// ===============================
  /// UPDATE ITEM
  /// ===============================
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

  /// ===============================
  /// DELETE ITEM
  /// ===============================
  Future<void> deleteItem(int id) async {

    await deleteItemUsecase(id);

    items.removeWhere((e) => e.id == id);

    cheapestMarkets.remove(id);

    notifyListeners();
  }

  /// ===============================
  /// TOTAL COST
  /// ===============================
  double getTotalEstimatedCost() {

    double total = 0;

    for (var item in filteredItems) {

      if (item.id == null) continue;

      final cheapest = cheapestMarkets[item.id!];

      final price = cheapest?['price'] ?? item.estimatedPrice;

      total += price * item.quantity;
    }

    return total;
  }
}
