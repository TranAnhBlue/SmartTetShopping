import '../../domain/entities/cheapest_market.dart';
import '../../domain/entities/market_price.dart';
import '../../domain/entities/market_total_cost.dart';
import '../../domain/entities/shopping_item.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/item_repository.dart';
import '../../domain/repositories/price_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/entities/item_price.dart';

import '../local_db/dao/item_dao.dart';
import '../local_db/dao/price_dao.dart';
import '../local_db/database_helper.dart';

import '../models/item_model.dart';
import '../models/price_model.dart';

class ShoppingRepositoryImpl
    implements ItemRepository, PriceRepository, CategoryRepository {

  final ItemDao itemDao;
  final PriceDao priceDao;

  ShoppingRepositoryImpl(this.itemDao, this.priceDao);

  // =====================================================
  // ITEM CRUD
  // =====================================================

  @override
  Future<void> addItem(ShoppingItem item) async {
    await itemDao.insert(_toModel(item));
  }

  @override
  Future<List<ShoppingItem>> getItems() async {
    final models = await itemDao.getAll();
    return models.map(_toEntity).toList();
  }

  @override
  Future<void> deleteItem(int id) async {
    await itemDao.delete(id);
  }

  @override
  Future<void> updateItem(ShoppingItem item) async {
    if (item.id != null) {
      final db = await DatabaseHelper.instance.database;
      final oldData = await db.query('items', where: 'id = ?', whereArgs: [item.id]);
      if (oldData.isNotEmpty) {
        final oldPrice = (oldData.first['estimated_price'] as num).toDouble();
        if (oldPrice != item.estimatedPrice) {
          // If estimated price changed, we must regenerate the market prices
          await db.delete('item_prices', where: 'item_id = ?', whereArgs: [item.id]);
          await DatabaseHelper.instance.seedPricesForItem(item.id!, item.estimatedPrice);
        }
      }
    }
    await itemDao.update(_toModel(item));
  }

  // =====================================================
  // PRICE FEATURE
  // =====================================================

  @override
  Future<void> addPrice(ItemPrice price) async {
    await priceDao.insert(_priceToModel(price));
  }

  @override
  Future<List<ItemPrice>> getPricesByItem(int itemId) async {
    final models = await priceDao.getByItem(itemId);
    return models.map(_priceToEntity).toList();
  }

  @override
  Future<List<MarketPrice>> getPricesWithMarket(int itemId) async {
    final data = await priceDao.getPricesWithMarket(itemId);
    return data.map((e) {
      return MarketPrice(
        id: e['id'],
        itemId: e['item_id'],
        marketId: e['market_id'],
        marketName: e['market_name'],
        price: (e['price'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  @override
  Future<CheapestMarket?> getCheapestMarket(int itemId) async {
    final data = await priceDao.getCheapestMarket(itemId);
    if (data == null) return null;
    return CheapestMarket(
      marketName: data['market_name'],
      price: (data['price'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Future<List<MarketTotalCost>> getTotalCostByMarket() async {
    final data = await priceDao.getTotalCostByMarket();
    return data.map((e) {
      return MarketTotalCost(
        marketName: e['market_name'],
        totalCost: (e['total_cost'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  @override
  Future<void> seedPricesForItem(int itemId, double estimatedPrice) async {
    await DatabaseHelper.instance.seedPricesForItem(itemId, estimatedPrice);
  }

  // =====================================================
  // CATEGORY
  // =====================================================

  @override
  Future<List<Category>> getCategories() async {
    return await DatabaseHelper.instance.getCategories();
  }

  @override
  Future<void> addCategory(Category category) async {
    // Implementation if needed, but not used in current provider scope
  }

  // =====================================================
  // MAPPERS
  // =====================================================

  ShoppingItem _toEntity(ItemModel model) {
    return ShoppingItem(
      id: model.id,
      name: model.name,
      categoryId: model.categoryId,
      quantity: model.quantity,
      estimatedPrice: model.estimatedPrice,
      isBought: model.isBought,
      imageUrl: model.imageUrl,
    );
  }

  ItemModel _toModel(ShoppingItem entity) {
    return ItemModel(
      id: entity.id,
      name: entity.name,
      categoryId: entity.categoryId,
      quantity: entity.quantity,
      estimatedPrice: entity.estimatedPrice,
      isBought: entity.isBought,
      imageUrl: entity.imageUrl,
    );
  }

  ItemPrice _priceToEntity(PriceModel model) {
    return ItemPrice(
      id: model.id,
      itemId: model.itemId,
      marketId: model.marketId,
      price: model.price,
    );
  }

  PriceModel _priceToModel(ItemPrice entity) {
    return PriceModel(
      id: entity.id,
      itemId: entity.itemId,
      marketId: entity.marketId,
      price: entity.price,
    );
  }
}
