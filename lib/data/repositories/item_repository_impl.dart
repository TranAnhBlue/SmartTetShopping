// import '../../domain/entities/shopping_item.dart';
// import '../../domain/repositories/shopping_repository.dart';
// import '../local_db/dao/item_dao.dart';
//
// class ItemRepositoryImpl implements ShoppingRepository {
//
//   final ItemDao itemDao;
//
//   ItemRepositoryImpl(this.itemDao);
//
//   @override
//   Future<void> addItem(ShoppingItem item) async {
//     await itemDao.insert(_toModel(item));
//   }
//
//   @override
//   Future<List<ShoppingItem>> getItems() async {
//     final models = await itemDao.getAll();
//     return models.map(_toEntity).toList();
//   }
//
//   @override
//   Future<void> deleteItem(int id) async {
//     await itemDao.delete(id);
//   }
//
//   @override
//   Future<void> updateItem(ShoppingItem item) async {
//     await itemDao.update(_toModel(item));
//   }
//
//   ShoppingItem _toEntity(ItemModel model) => ShoppingItem(
//     id: model.id,
//     name: model.name,
//     categoryId: model.categoryId,
//     quantity: model.quantity,
//     estimatedPrice: model.estimatedPrice,
//     isBought: model.isBought,
//   );
//
//   ItemModel _toModel(ShoppingItem entity) => ItemModel(
//     id: entity.id,
//     name: entity.name,
//     categoryId: entity.categoryId,
//     quantity: entity.quantity,
//     estimatedPrice: entity.estimatedPrice,
//     isBought: entity.isBought,
//   );
// }
