import '../database_helper.dart';
import '../../models/category_model.dart';

class CategoryDao {

  final dbHelper = DatabaseHelper.instance;

  Future<int> insert(CategoryModel category) async {
    final db = await dbHelper.database;
    return db.insert('categories', category.toMap());
  }

  Future<List<CategoryModel>> getAll() async {
    final db = await dbHelper.database;
    final result = await db.query('categories');

    return result.map((e) => CategoryModel.fromMap(e)).toList();
  }
}
