import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../domain/entities/category.dart';

class DatabaseHelper {

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smart_tet.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future<void> deleteDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_tet.db');

    await deleteDatabase(path);
  }

  // ================= CREATE DB =================
  Future<void> _createDB(Database db, int version) async {

    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT,
        color TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE markets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT,
        zone TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        estimated_price REAL NOT NULL,
        is_bought INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(category_id)
          REFERENCES categories(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE item_prices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        market_id INTEGER NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY(item_id) REFERENCES items(id) ON DELETE CASCADE,
        FOREIGN KEY(market_id) REFERENCES markets(id) ON DELETE CASCADE
      )
    ''');

    /// ⭐ SEED DATA
    await _seedCategories(db);
    await _seedMarkets(db);
  }

  // ================= SEED CATEGORY =================
  Future<void> _seedCategories(Database db) async {

    final categories = [
      {'name': 'Thực phẩm'},
      {'name': 'Đồ cúng'},
      {'name': 'Trang trí'},
      {'name': 'Đồ uống'},
      {'name': 'Bánh kẹo'},
    ];

    for (var c in categories) {
      await db.insert('categories', c);
    }
  }

  // ================= SEED MARKETS =================
  Future<void> _seedMarkets(Database db) async {

    final markets = [
      {
        'name': 'Co.opmart',
        'location': 'Siêu thị',
        'zone': 'Chuỗi bán lẻ'
      },
      {
        'name': 'Big C',
        'location': 'Siêu thị',
        'zone': 'Chuỗi bán lẻ'
      },
      {
        'name': 'WinMart',
        'location': 'Siêu thị',
        'zone': 'Chuỗi bán lẻ'
      },
      {
        'name': 'Bách Hoá Xanh',
        'location': 'Cửa hàng tiện lợi',
        'zone': 'Chuỗi bán lẻ'
      },
      {
        'name': 'Chợ truyền thống',
        'location': 'Chợ',
        'zone': 'Local market'
      },
    ];

    for (var m in markets) {
      await db.insert('markets', m);
    }
  }

  // ======================================================
  // ===================== ITEMS CRUD =====================
  // ======================================================

  Future<int> insertItem({
    required String name,
    required int categoryId,
    required int quantity,
    required double estimatedPrice,
    bool isBought = false,
  }) async {

    final db = await instance.database;

    return await db.insert('items', {
      'name': name,
      'category_id': categoryId,
      'quantity': quantity,
      'estimated_price': estimatedPrice,
      'is_bought': isBought ? 1 : 0,
    });
  }

  Future<List<Map<String, dynamic>>> getItemsWithCategory() async {
    final db = await instance.database;

    return await db.rawQuery('''
      SELECT items.*, categories.name AS category_name
      FROM items
      LEFT JOIN categories
      ON items.category_id = categories.id
      ORDER BY items.id DESC
    ''');
  }

  Future<int> deleteItem(int id) async {
    final db = await instance.database;

    return await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ======================================================
  // ===================== MARKETS =========================
  // ======================================================

  Future<List<Map<String, dynamic>>> getAllMarkets() async {
    final db = await instance.database;
    return await db.query('markets');
  }

  // ======================================================
  // ===================== ITEM PRICES =====================
  // ======================================================

  Future<int> insertItemPrice({
    required int itemId,
    required int marketId,
    required double price,
  }) async {

    final db = await instance.database;

    return await db.insert('item_prices', {
      'item_id': itemId,
      'market_id': marketId,
      'price': price,
    });
  }

  Future<List<Category>> getCategories() async {

    final db = await database;

    final maps = await db.query('categories');

    return maps.map((e) => Category.fromMap(e)).toList();
  }

}
