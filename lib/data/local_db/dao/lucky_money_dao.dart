import 'package:sqflite/sqflite.dart';
import '../../../domain/entities/lucky_money.dart';

class LuckyMoneyDao {
  final Database db;
  LuckyMoneyDao(this.db);

  Future<int> insert(LuckyMoney luckyMoney) async {
    return await db.insert('lucky_money', luckyMoney.toMap());
  }

  Future<List<LuckyMoney>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query('lucky_money');
    return List.generate(maps.length, (i) => LuckyMoney.fromMap(maps[i]));
  }

  Future<int> update(LuckyMoney luckyMoney) async {
    return await db.update(
      'lucky_money',
      luckyMoney.toMap(),
      where: 'id = ?',
      whereArgs: [luckyMoney.id],
    );
  }

  Future<int> delete(int id) async {
    return await db.delete(
      'lucky_money',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
