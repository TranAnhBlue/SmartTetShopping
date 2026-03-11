import '../entities/item_price.dart';
import '../entities/market_price.dart';
import '../entities/cheapest_market.dart';
import '../entities/market_total_cost.dart';

abstract class PriceRepository {

  Future<void> addPrice(ItemPrice price);

  Future<List<ItemPrice>> getPricesByItem(int itemId);

  Future<List<MarketPrice>> getPricesWithMarket(int itemId);

  Future<CheapestMarket?> getCheapestMarket(int itemId);

  Future<List<MarketTotalCost>> getTotalCostByMarket();

  Future<void> seedPricesForItem(int itemId, double estimatedPrice);
}
