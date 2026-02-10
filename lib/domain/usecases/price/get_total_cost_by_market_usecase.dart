import '../../entities/market_total_cost.dart';
import '../../repositories/price_repository.dart';

class GetTotalCostByMarketUsecase {

  final PriceRepository repository;

  GetTotalCostByMarketUsecase(this.repository);

  Future<List<MarketTotalCost>> call() {
    return repository.getTotalCostByMarket();
  }
}
