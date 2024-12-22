import '../data/database.dart';
import '../models/item.dart';

class ItemRepository {
  final AppDatabase _database = AppDatabase.db;

  Future<List<Item>> getItems() async {
    return await _database.getAllItems();
  }

  Future<void> addItem(Item item) async {
    await _database.insertItem(item);
  }

  Future<void> updateItem(Item item) async {
    await _database.updateItem(item);
  }

  Future<void> deleteItem(String id) async {
    await _database.deleteItem(id);
  }

  Future<List<Item>> getFilteredItems(String category) async {
    return await _database.getFilteredItems(category);
  }
}

