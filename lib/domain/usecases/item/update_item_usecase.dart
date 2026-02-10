import '../../entities/shopping_item.dart';
import '../../repositories/item_repository.dart';

class UpdateItemUsecase {
  final ItemRepository repository;

  UpdateItemUsecase(this.repository);

  Future<void> call(ShoppingItem item) async {
    if (item.id == null) {
      throw Exception("Item ID cannot be null when updating");
    }

    await repository.updateItem(item);
  }
}
