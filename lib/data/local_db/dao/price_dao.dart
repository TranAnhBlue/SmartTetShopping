import '../database_helper.dart';
import '../../models/price_model.dart';

class PriceDao {
  final dbHelper = DatabaseHelper.instance;

  /// Insert price
  Future<int> insert(PriceModel price) async {
    final db = await dbHelper.database;
    return await db.insert('item_prices', price.toMap());
  }

  /// Update price
  Future<int> update(PriceModel price) async {
    final db = await dbHelper.database;

    return await db.update(
      'item_prices',
      price.toMap(),
      where: 'id = ?',
      whereArgs: [price.id],
    );
  }

  /// Delete price
  Future<int> delete(int id) async {
    final db = await dbHelper.database;

    return await db.delete(
      'item_prices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get prices by items id
  Future<List<PriceModel>> getByItem(int itemId) async {
    final db = await dbHelper.database;

    final result = await db.query(
      'item_prices',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );

    return result.map((e) => PriceModel.fromMap(e)).toList();
  }

  /// Get prices with market name
  Future<List<Map<String, dynamic>>> getPricesWithMarket(int itemId) async {
    final db = await dbHelper.database;

    return await db.rawQuery('''
      SELECT 
        p.id,
        p.item_id,
        p.market_id,
        p.price,
        p.updated_at,
        m.name AS market_name
      FROM item_prices p
      JOIN markets m ON p.market_id = m.id
      WHERE p.item_id = ?
      ORDER BY p.price ASC
    ''', [itemId]);
  }

  Future<Map<String, dynamic>?> getCheapestMarket(int itemId) async {
    final db = await dbHelper.database;

    final result = await db.rawQuery('''
    SELECT m.name as market_name, MIN(p.price) as cheapest_price
    FROM item_prices p
    JOIN markets m ON p.market_id = m.id
    WHERE p.item_id = ?
  ''', [itemId]);

    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getTotalCostByMarket() async {
    final db = await DatabaseHelper.instance.database;

    return await db.rawQuery('''
    SELECT 
      m.name AS market_name,
      SUM(p.price * i.quantity) AS total_cost
    FROM item_prices p
    JOIN markets m ON p.market_id = m.id
    JOIN shopping_items i ON p.item_id = i.id
    GROUP BY m.name
    ORDER BY total_cost ASC
  ''');
  }

  Future<List<Map<String, dynamic>>> getPricesByItem(int itemId) async {

    final db = await DatabaseHelper.instance.database;

    return await db.query(
      'prices',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
  }
}