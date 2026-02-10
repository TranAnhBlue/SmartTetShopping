class ItemsTable {
  static const String tableName = "items";

  static const String createTable = '''
  CREATE TABLE $tableName (
    id TEXT PRIMARY KEY,
    name TEXT,
    price REAL,
    is_purchased INTEGER
  )
  ''';
}
