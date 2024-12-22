import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/item.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase db = AppDatabase._();

  static const String TABLE_NAME_ITEM = "item";
  static const String COLUMN_ITEM_ID = "id";
  static const String COLUMN_ITEM_CATEGORY = "category";
  static const String COLUMN_ITEM_TEXT = "text";
  static const String COLUMN_ITEM_FILE_PATH = "file_path";

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDb();
    return _database!;
  }

  Future<Database> initDb() async {
    var documentsDirectory = await getApplicationDocumentsDirectory();
    var path = join(documentsDirectory.path, "ItemDB.db");

    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE $TABLE_NAME_ITEM (
          $COLUMN_ITEM_ID INTEGER PRIMARY KEY AUTOINCREMENT,
          $COLUMN_ITEM_CATEGORY TEXT,
          $COLUMN_ITEM_TEXT TEXT,
          $COLUMN_ITEM_FILE_PATH TEXT
        )
      ''');
    });
  }

  Future<int> insertItem(Item item) async {
    var db = await database;
    return await db.insert(TABLE_NAME_ITEM, item.toMap());
  }

  Future<List<Item>> getAllItems() async {
    var db = await database;
    var result = await db.query(TABLE_NAME_ITEM);
    return result.map((map) => Item.fromMap(map)).toList();
  }

  Future<int> updateItem(Item item) async {
    var db = await database;
    return await db.update(
      TABLE_NAME_ITEM,
      item.toMap(),
      where: '$COLUMN_ITEM_ID = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(String id) async {
    var db = await database;
    return await db.delete(
      TABLE_NAME_ITEM,
      where: '$COLUMN_ITEM_ID = ?',
      whereArgs: [id],
    );
  }

  Future<List<Item>> getFilteredItems(String category) async {
    var db = await database;
    var result = await db.query(
      TABLE_NAME_ITEM,
      where: '$COLUMN_ITEM_CATEGORY = ?',
      whereArgs: [category],
    );
    return result.map((map) => Item.fromMap(map)).toList();
  }
}

