import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/item_model.dart';

class ItemDao {

  final dbHelper = DatabaseHelper.instance;

  Future<int> insert(ItemModel item) async {
    final db = await dbHelper.database;
    return await db.insert('items', item.toMap());
  }

  Future<List<ItemModel>> getAll() async {
    final db = await dbHelper.database;
    final result = await db.query('items');

    return result.map((e) => ItemModel.fromMap(e)).toList();
  }

  Future<int> update(ItemModel item) async {
    final db = await dbHelper.database;

    return await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await dbHelper.database;

    return await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
