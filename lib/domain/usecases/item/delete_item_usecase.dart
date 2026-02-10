import '../../repositories/item_repository.dart';

class DeleteItemUsecase {
  final ItemRepository repository;

  DeleteItemUsecase(this.repository);

  Future<void> call(int id) {
    return repository.deleteItem(id);
  }
}
