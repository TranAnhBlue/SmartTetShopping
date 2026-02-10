import '../../entities/item_price.dart';
import '../../repositories/price_repository.dart';

class AddPriceUsecase {

  final PriceRepository repository;

  AddPriceUsecase(this.repository);

  Future<void> call(ItemPrice price) {
    return repository.addPrice(price);
  }
}
