import '../entities/market.dart';

abstract class MarketRepository {

  Future<List<Market>> getMarkets();

  Future<void> addMarket(Market market);
}
