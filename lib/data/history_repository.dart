import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_item.dart';

class HistoryRepository {
  static const _key = 'history_items';

  static Future<List<ScanItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    return list
        .map((e) {
          try {
            return ScanItem.fromJson(json.decode(e) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<ScanItem>()
        .toList();
  }

  static Future<void> add(ScanItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    // Newest first
    list.insert(0, json.encode(item.toJson()));
    await prefs.setStringList(_key, list);
  }

  static Future<void> removeAt(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      await prefs.setStringList(_key, list);
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}