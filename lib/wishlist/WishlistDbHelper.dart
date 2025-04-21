import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:sqflite/sqflite.dart';

class WishlistDatabaseHelper {
  static const String _tableName = 'wishlist';

  static const String _createTableQuery = '''
    CREATE TABLE IF NOT EXISTS $_tableName (
      id TEXT PRIMARY KEY,
      title TEXT,
      handle TEXT,
      descriptionHtml TEXT,
      images TEXT,
      options TEXT,
      variants TEXT,
      metafields TEXT
    )
  ''';

  static Future<Database> _getDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      '$dbPath/wishlist.db',
      onCreate: (db, version) async {
        await db.execute(_createTableQuery);
      },
      version: 1,
    );
  }

  static Future<void> recreateTable() async {
    final db = await _getDatabase();
    // Drop the existing table
    await db.execute('DROP TABLE IF EXISTS $_tableName');
    // Recreate the table
    await db.execute(_createTableQuery);
  }

  static Future<void> addProduct(Map<String, dynamic> product) async {
    final db = await _getDatabase();

    // Serialize nested objects to JSON strings and ensure they're Strings
    final data = {
      'id': product['id'] as String, // Cast to String
      'title': product['title'] as String, // Cast to String
      'handle': product['handle'] as String, // Cast to String
      'descriptionHtml': product['descriptionHtml'] as String, // Cast to String
      'images': jsonEncode(product['images']), // Convert to String
      'options': jsonEncode(product['options']), // Convert to String
      'variants': jsonEncode(product['variants']), // Convert to String
      'metafields': jsonEncode(product['metafields']), // Convert to String
    };

    await db.insert(
      _tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> removeProduct(String id) async {
    final db = await _getDatabase();
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await _getDatabase();
    final result = await db.query(_tableName);

    // Deserialize JSON strings back to original objects
    return result.map((product) {
      return {
        'id': product['id'] as String, // Cast to String
        'title': product['title'] as String, // Cast to String
        'handle': product['handle'] as String, // Cast to String
        'descriptionHtml': product['descriptionHtml'] as String, // Cast to String
        'images': jsonDecode(product['images'] as String), // Decode from String
        'options': jsonDecode(product['options'] as String), // Decode from String
        'variants': jsonDecode(product['variants'] as String), // Decode from String
        'metafields': jsonDecode(product['metafields'] as String), // Decode from String
      };
    }).toList();
  }
}
