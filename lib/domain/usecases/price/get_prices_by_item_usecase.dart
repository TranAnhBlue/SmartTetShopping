import '../../entities/item_price.dart';
import '../../repositories/price_repository.dart';

class GetPricesByItemUsecase {

  final PriceRepository repository;

  GetPricesByItemUsecase(this.repository);

  Future<List<ItemPrice>> call(int itemId) {
    return repository.getPricesByItem(itemId);
  }
}
