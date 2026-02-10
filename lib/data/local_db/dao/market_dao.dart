import '../database_helper.dart';
import '../../models/market_model.dart';

class MarketDao {
  final dbHelper = DatabaseHelper.instance;

  /// Insert market
  Future<int> insert(MarketModel market) async {
    final db = await dbHelper.database;

    return await db.insert(
      'markets',
      market.toMap(),
    );
  }

  /// Get all markets
  Future<List<MarketModel>> getAll() async {
    final db = await dbHelper.database;

    final result = await db.query(
      'markets',
      orderBy: 'name ASC',
    );

    return result.map((e) => MarketModel.fromMap(e)).toList();
  }

  /// Get market by id
  Future<MarketModel?> getById(int id) async {
    final db = await dbHelper.database;

    final result = await db.query(
      'markets',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return MarketModel.fromMap(result.first);
    }
    return null;
  }

  /// Update market
  Future<int> update(MarketModel market) async {
    final db = await dbHelper.database;

    return await db.update(
      'markets',
      market.toMap(),
      where: 'id = ?',
      whereArgs: [market.id],
    );
  }

  /// Delete market
  Future<int> delete(int id) async {
    final db = await dbHelper.database;

    return await db.delete(
      'markets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Search market by name
  Future<List<MarketModel>> searchByName(String keyword) async {
    final db = await dbHelper.database;

    final result = await db.query(
      'markets',
      where: 'name LIKE ?',
      whereArgs: ['%$keyword%'],
    );

    return result.map((e) => MarketModel.fromMap(e)).toList();
  }
}
