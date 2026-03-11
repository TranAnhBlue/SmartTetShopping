import '../../domain/entities/item_price.dart';
import '../../domain/entities/market_price.dart';
import '../../domain/entities/cheapest_market.dart';
import '../../domain/entities/market_total_cost.dart';
import '../../domain/repositories/price_repository.dart';
import '../local_db/dao/price_dao.dart';
import '../models/price_model.dart';
import '../local_db/database_helper.dart';

class PriceRepositoryImpl implements PriceRepository {

  final PriceDao priceDao;

  PriceRepositoryImpl(this.priceDao);

  // ================= ADD =================
  @override
  Future<void> addPrice(ItemPrice price) async {
    await priceDao.insert(
      PriceModel(
        id: price.id,
        itemId: price.itemId,
        marketId: price.marketId,
        price: price.price,
      ),
    );
  }

  // ================= GET BY ITEM =================
  @override
  Future<List<ItemPrice>> getPricesByItem(int itemId) async {

    final models = await priceDao.getByItem(itemId);

    return models.map((m) => ItemPrice(
      id: m.id,
      itemId: m.itemId,
      marketId: m.marketId,
      price: m.price,
    )).toList();
  }

  // ================= GET WITH MARKET =================
  @override
  Future<List<MarketPrice>> getPricesWithMarket(int itemId) async {

    final result = await priceDao.getPricesWithMarket(itemId);

    return result.map((e) => MarketPrice(
      id: (e['id'] as num).toInt(),
      itemId: (e['item_id'] as num).toInt(),
      marketId: (e['market_id'] as num).toInt(),
      marketName: e['market_name'] as String,
      price: (e['price'] as num).toDouble(),
    )).toList();
  }

  // ================= CHEAPEST =================
  @override
  Future<CheapestMarket?> getCheapestMarket(int itemId) async {

    final map = await priceDao.getCheapestMarket(itemId);

    if (map == null) return null;

    return CheapestMarket(
      marketName: map['market_name'] as String,
      price: (map['price'] as num).toDouble(),
    );
  }

  // ================= TOTAL COST =================
  @override
  Future<List<MarketTotalCost>> getTotalCostByMarket() async {

    final result = await priceDao.getTotalCostByMarket();

    return result.map((e) => MarketTotalCost(
      marketName: e['market_name'] as String,
      totalCost: (e['total_cost'] as num).toDouble(),
    )).toList();
  }

  @override
  Future<void> seedPricesForItem(int itemId, double estimatedPrice) async {
    await DatabaseHelper.instance.seedPricesForItem(itemId, estimatedPrice);
  }
}