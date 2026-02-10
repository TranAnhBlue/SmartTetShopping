import '../../entities/cheapest_market.dart';
import '../../repositories/price_repository.dart';

class GetCheapestMarketUsecase {

  final PriceRepository repository;

  GetCheapestMarketUsecase(this.repository);

  Future<CheapestMarket?> call(int itemId) {
    return repository.getCheapestMarket(itemId);
  }
}
