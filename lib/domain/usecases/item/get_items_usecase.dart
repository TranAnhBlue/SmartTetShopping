import '../../entities/shopping_item.dart';
import '../../repositories/item_repository.dart';
import '../../repositories/shopping_repository.dart';

class GetItemsUsecase {

  final ItemRepository repository;

  GetItemsUsecase(this.repository);

  Future<List<ShoppingItem>> call() {
    return repository.getItems();
  }
}
