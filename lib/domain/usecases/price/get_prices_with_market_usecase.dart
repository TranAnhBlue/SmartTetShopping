import '../../entities/market_price.dart';
import '../../repositories/price_repository.dart';

class GetPricesWithMarketUsecase {

  final PriceRepository repository;

  GetPricesWithMarketUsecase(this.repository);

  Future<List<MarketPrice>> call(int itemId) {
    return repository.getPricesWithMarket(itemId);
  }
}
