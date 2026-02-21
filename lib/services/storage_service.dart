import 'package:hive_flutter/hive_flutter.dart';
import '../models/item.dart';

class StorageService {
  final _itemsBox = Hive.box<Item>('items');
  final _settingsBox = Hive.box('settings');

  // --- Theme & Sprache ---
  String getTheme() => _settingsBox.get('theme', defaultValue: 'light');
  Future<void> saveTheme(String theme) async => await _settingsBox.put('theme', theme);

  String getLanguage() => _settingsBox.get('language', defaultValue: 'de');
  Future<void> saveLanguage(String lang) async => await _settingsBox.put('language', lang);

  // --- Notifications ---
  bool getNotificationsEnabled() => _settingsBox.get('notifications', defaultValue: true);
  Future<void> saveNotificationsEnabled(bool enabled) async => await _settingsBox.put('notifications', enabled);

  // --- Items ---
  List<Item> getAllItems() => _itemsBox.values.toList();
  
  // WICHTIG: Hier stand vorher 'void', jetzt 'Future<void>', damit 'await' funktioniert
  Future<void> saveItem(Item item) async => await _itemsBox.put(item.id, item);
  
  Future<void> deleteItem(String id) async => await _itemsBox.delete(id);
  Future<void> deleteAllItems() async => await _itemsBox.clear();

  // --- Custom Data ---
  List<String> getCustomCategories() => List<String>.from(_settingsBox.get('custom_categories', defaultValue: []));
  Future<void> saveCustomCategories(List<String> cats) async => await _settingsBox.put('custom_categories', cats);

  Map<String, String> getCustomEmojis() => Map<String, String>.from(_settingsBox.get('custom_emojis', defaultValue: {}));
  Future<void> saveCustomEmojis(Map<String, String> emojis) async => await _settingsBox.put('custom_emojis', emojis);

  Map<String, String> getCategoryAliases() => Map<String, String>.from(_settingsBox.get('category_aliases', defaultValue: {}));
  Future<void> saveCategoryAliases(Map<String, String> aliases) async => await _settingsBox.put('category_aliases', aliases);
}