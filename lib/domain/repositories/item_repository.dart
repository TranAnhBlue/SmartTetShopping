import '../entities/shopping_item.dart';

abstract class ItemRepository {

  /// Get all items
  Future<List<ShoppingItem>> getItems();

  /// Add new item
  Future<void> addItem(ShoppingItem item);

  /// Update item
  Future<void> updateItem(ShoppingItem item);

  /// Delete item
  Future<void> deleteItem(int id);

  /// Toggle bought status
  // Future<void> toggleBought(int id, bool isBought);
}
