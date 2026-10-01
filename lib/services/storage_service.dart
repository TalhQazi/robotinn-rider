import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static dynamic sanitizeForJson(dynamic item) {
    if (item == null) return null;
    if (item is num || item is bool || item is String) return item;
    if (item is List) {
      return item.map(sanitizeForJson).toList();
    }
    if (item is Map) {
      final Map<String, dynamic> clean = {};
      item.forEach((key, val) {
        clean[key.toString()] = sanitizeForJson(val);
      });
      return clean;
    }
    if (item is DateTime) {
      return item.toIso8601String();
    }
    // Handle Firestore GeoPoint
    try {
      final dynamic d = item;
      if (d.latitude != null && d.longitude != null) {
        return {'latitude': d.latitude, 'longitude': d.longitude};
      }
    } catch (_) {}
    // Handle Firestore Timestamp
    try {
      final dynamic d = item;
      if (d.toDate != null) {
        final dt = d.toDate();
        if (dt is DateTime) return dt.toIso8601String();
      }
    } catch (_) {}
    return item.toString();
  }

  static Future<bool> setString(String key, String value) async {
    await init();
    return await _prefs!.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  static Future<bool> setBool(String key, bool value) async {
    await init();
    return await _prefs!.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  static Future<bool> setObject(String key, dynamic value) async {
    await init();
    try {
      final sanitized = sanitizeForJson(value);
      final jsonStr = jsonEncode(sanitized);
      return await _prefs!.setString(key, jsonStr);
    } catch (e) {
      print('StorageService.setObject error for $key: $e');
      return false;
    }
  }

  static dynamic getObject(String key) {
    final str = _prefs?.getString(key);
    if (str == null || str.isEmpty) return null;
    try {
      return jsonDecode(str);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> remove(String key) async {
    await init();
    return await _prefs!.remove(key);
  }

  static Future<bool> clear() async {
    await init();
    return await _prefs!.clear();
  }
}

