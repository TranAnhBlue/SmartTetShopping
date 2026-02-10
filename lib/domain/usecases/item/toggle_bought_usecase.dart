import '../../entities/shopping_item.dart';
import '../../repositories/item_repository.dart';
import '../../repositories/shopping_repository.dart';

class ToggleBoughtUsecase {

  final ItemRepository repository;

  ToggleBoughtUsecase(this.repository);

  Future<void> call(ShoppingItem item) async {

    final updated = ShoppingItem(
      id: item.id,
      name: item.name,
      categoryId: item.categoryId,
      quantity: item.quantity,
      estimatedPrice: item.estimatedPrice,
      isBought: !item.isBought,
    );

    await repository.updateItem(updated);
  }
}
