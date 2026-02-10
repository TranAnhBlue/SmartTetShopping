
import 'package:smart_tet_shopping_manager/domain/repositories/item_repository.dart';

import '../../entities/shopping_item.dart';
import '../../repositories/shopping_repository.dart';

class AddItemUsecase {
  final ItemRepository repository;

  AddItemUsecase(this.repository);

  Future<void> call(ShoppingItem item) async {

    if (item.name.trim().isEmpty) {
      throw Exception("Tên món không được để trống");
    }

    if (item.quantity <= 0) {
      throw Exception("Số lượng phải > 0");
    }

    if (item.estimatedPrice < 0) {
      throw Exception("Giá không hợp lệ");
    }

    await repository.addItem(item);
  }

}
