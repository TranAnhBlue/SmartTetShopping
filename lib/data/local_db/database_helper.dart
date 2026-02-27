import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../domain/entities/category.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // ======================================================
  // DATABASE INIT
  // ======================================================

  Future<Database> get database async {
    _database ??= await _initDB('smart_tet.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createLuckyMoneyTable(db);
    }
  }

  Future<void> deleteDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_tet.db');
    await deleteDatabase(path);
  }

  // ======================================================
  // CREATE DATABASE
  // ======================================================

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

    await _createLuckyMoneyTable(db);

    await _seedCategories(db);
    await _seedMarkets(db);
    await _seedItems(db); // ⭐ nhiều sản phẩm
  }

  // ======================================================
  // SEED CATEGORY
  // ======================================================

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

  Future<void> _createLuckyMoneyTable(Database db) async {
    await db.execute('''
      CREATE TABLE lucky_money(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipient TEXT NOT NULL,
        amount REAL NOT NULL,
        group_name TEXT NOT NULL,
        is_prepared INTEGER NOT NULL DEFAULT 0,
        is_gave INTEGER NOT NULL DEFAULT 0,
        note TEXT
      )
    ''');
  }

  // ======================================================
  // SEED MARKETS
  // ======================================================

  Future<void> _seedMarkets(Database db) async {
    final markets = [
      {'name': 'Co.opmart', 'location': 'Siêu thị', 'zone': 'Retail'},
      {'name': 'Big C', 'location': 'Siêu thị', 'zone': 'Retail'},
      {'name': 'WinMart', 'location': 'Siêu thị', 'zone': 'Retail'},
      {'name': 'Bách Hoá Xanh', 'location': 'Cửa hàng', 'zone': 'Retail'},
      {'name': 'Chợ truyền thống', 'location': 'Chợ', 'zone': 'Local'},
    ];

    for (var m in markets) {
      await db.insert('markets', m);
    }
  }

  // ======================================================
  // SEED MANY ITEMS ⭐⭐⭐⭐⭐
  // ======================================================

  Future<void> _seedItems(Database db) async {
    final random = Random();
    final markets = await db.query('markets');

    final items = [
      // ===== THỰC PHẨM
      ['Thịt heo', 1, 120000],
      ['Thịt bò', 1, 220000],
      ['Gà ta', 1, 180000],
      ['Chả lụa', 1, 150000],
      ['Trứng gà', 1, 35000],
      ['Rau cải', 1, 20000],
      ['Cà rốt', 1, 15000],
      ['Hành lá', 1, 10000],

      // ===== ĐỒ CÚNG
      ['Bánh chưng', 2, 70000],
      ['Hoa cúc', 2, 50000],
      ['Nhang', 2, 30000],
      ['Đèn cầy', 2, 25000],
      ['Mâm ngũ quả', 2, 200000],

      // ===== TRANG TRÍ
      ['Bao lì xì', 3, 20000],
      ['Câu đối đỏ', 3, 45000],
      ['Đèn lồng', 3, 80000],
      ['Sticker Tết', 3, 15000],

      // ===== ĐỒ UỐNG
      ['Coca Cola', 4, 90000],
      ['Pepsi', 4, 85000],
      ['Bia Heineken', 4, 320000],
      ['Nước suối', 4, 60000],
      ['Trà xanh', 4, 70000],

      // ===== BÁNH KẸO
      ['Kẹo dừa', 5, 80000],
      ['Hạt dưa', 5, 60000],
      ['Mứt gừng', 5, 90000],
      ['Mứt dừa', 5, 85000],
      ['Bánh quy bơ', 5, 110000],
      ['Socola hộp', 5, 140000],
      ['Kẹo trái cây', 5, 75000],
    ];

    for (var item in items) {
      final itemId = await db.insert('items', {
        'name': item[0],
        'category_id': item[1],
        'quantity': 1,
        'estimated_price': item[2],
        'is_bought': 0,
      });

      /// auto generate prices
      for (var market in markets) {
        final price =
            (item[2] as int) * (0.75 + random.nextDouble() * 0.5);

        await db.insert('item_prices', {
          'item_id': itemId,
          'market_id': market['id'],
          'price': price,
        });
      }
    }
  }

  Future<void> generatePricesIfNeeded(
      int itemId,
      double estimatedPrice,
      ) async {

    final db = await database;

    final existed = await db.query(
      'item_prices',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );

    if (existed.isNotEmpty) return;

    final markets = await db.query('markets');

    final random = Random();

    for (var market in markets) {
      final price =
          estimatedPrice * (0.7 + random.nextDouble() * 0.6);

      await db.insert('item_prices', {
        'item_id': itemId,
        'market_id': market['id'],
        'price': price,
      });
    }
  }

  // ======================================================
  // INSERT ITEM
  // ======================================================

  Future<int> insertItem({
    required String name,
    required int categoryId,
    required int quantity,
    required double estimatedPrice,
  }) async {
    final db = await database;

    final itemId = await db.insert('items', {
      'name': name,
      'category_id': categoryId,
      'quantity': quantity,
      'estimated_price': estimatedPrice,
      'is_bought': 0,
    });

    await seedPricesForItem(itemId, estimatedPrice);
    return itemId;
  }

  Future<void> seedPricesForItem(
      int itemId, double estimatedPrice) async {
    final db = await database;
    final markets = await db.query('markets');
    final random = Random();

    for (var market in markets) {
      final price =
          estimatedPrice * (0.8 + random.nextDouble() * 0.4);

      await db.insert('item_prices', {
        'item_id': itemId,
        'market_id': market['id'],
        'price': price,
      });
    }
  }

  // ======================================================
  // QUERIES
  // ======================================================

  Future<List<Map<String, dynamic>>> getItemsWithCategory() async {
    final db = await database;

    return db.rawQuery('''
      SELECT items.*, categories.name AS category_name
      FROM items
      LEFT JOIN categories
      ON items.category_id = categories.id
      ORDER BY items.id DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getAllMarkets() async {
    final db = await database;
    return db.query('markets');
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories');
    return maps.map((e) => Category.fromMap(e)).toList();
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> debugDatabase() async {
    final db = await database;

    final categories = await db.query('categories');
    final markets = await db.query('markets');
    final items = await db.query('items');
    final prices = await db.query('item_prices');

    print("========== DATABASE DEBUG ==========");
    print("Categories: ${categories.length}");
    print("Markets: ${markets.length}");
    print("Items: ${items.length}");
    print("Item Prices: ${prices.length}");

    if (items.isNotEmpty) {
      print("Sample item: ${items.first}");
    }

    if (prices.isNotEmpty) {
      print("Sample price: ${prices.first}");
    }

    print("====================================");
  }
}