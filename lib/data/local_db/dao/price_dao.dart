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
        MIN(p.price) as price,
        m.name AS market_name
      FROM item_prices p
      JOIN markets m ON p.market_id = m.id
      WHERE p.item_id = ?
      GROUP BY m.id
      ORDER BY price ASC
    ''', [itemId]);
  }

  Future<Map<String, dynamic>?> getCheapestMarket(int itemId) async {
    final db = await dbHelper.database;

    final result = await db.rawQuery('''
    SELECT m.name as market_name, p.price
    FROM item_prices p
    JOIN markets m ON p.market_id = m.id
    WHERE p.item_id = ?
    ORDER BY p.price ASC
    LIMIT 1
  ''', [itemId]);

    if (result.isEmpty) return null;

    return result.first;
  }

  Future<List<Map<String, dynamic>>> getTotalCostByMarket() async {
    final db = await DatabaseHelper.instance.database;

    return await db.rawQuery('''
    SELECT 
      m.name AS market_name,
      SUM(COALESCE(p.price, i.estimated_price) * i.quantity) AS total_cost
    FROM markets m
    CROSS JOIN items i
    LEFT JOIN item_prices p ON p.item_id = i.id AND p.market_id = m.id
    GROUP BY m.name
    ORDER BY total_cost ASC
  ''');
  }

  Future<List<Map<String, dynamic>>> getPricesByItem(int itemId) async {

    final db = await DatabaseHelper.instance.database;

    return await db.query(
      'item_prices',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
  }
}