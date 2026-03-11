import '../../repositories/price_repository.dart';

class SeedPricesUsecase {
  final PriceRepository repository;

  SeedPricesUsecase(this.repository);

  Future<void> call(int itemId, double estimatedPrice) {
    return repository.seedPricesForItem(itemId, estimatedPrice);
  }
}
