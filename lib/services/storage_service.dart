import 'package:hive_flutter/hive_flutter.dart';
import '../models/item.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late Box<Item> _itemBox;
  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ItemAdapter());
    _itemBox = await Hive.openBox<Item>('items');
    _settingsBox = await Hive.openBox('settings');
  }

  List<Item> getAllItems() => _itemBox.values.toList();
  Future<void> saveItem(Item item) async => _itemBox.containsKey(item.id) ? await item.save() : await _itemBox.put(item.id, item);
  Future<void> deleteItem(String id) async => await _itemBox.delete(id);
  Future<void> deleteAllItems() async => await _itemBox.clear();
  
  Map<String, String> getCategoryAliases() => Map<String, String>.from(_settingsBox.get('aliases', defaultValue: {}));
  Future<void> saveCategoryAliases(Map<String, String> aliases) async => await _settingsBox.put('aliases', aliases);
  List<String> getCustomCategories() => List<String>.from(_settingsBox.get('custom_cats', defaultValue: []));
  Future<void> saveCustomCategories(List<String> cats) async => await _settingsBox.put('custom_cats', cats);
  Map<String, String> getCustomEmojis() => Map<String, String>.from(_settingsBox.get('custom_emojis', defaultValue: {}));
  Future<void> saveCustomEmojis(Map<String, String> emojis) async => await _settingsBox.put('custom_emojis', emojis);
}