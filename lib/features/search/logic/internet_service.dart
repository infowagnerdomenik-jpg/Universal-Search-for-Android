import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InternetService {
  static const _channel = MethodChannel('de.search.dw.search/internet');

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('enable_internet_companion_access') ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_internet_companion_access', value);
  }

  static Future<bool> isCompanionInstalled() async {
    try {
      return await _channel.invokeMethod('isCompanionInstalled') ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> checkConnection() async {
    try {
      return await _channel.invokeMethod('checkConnection') ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<List<String>> fetchSuggestions(String query, String type) async {
    try {
      final List<dynamic>? results = await _channel.invokeMethod('fetchSuggestions', {
        'query': query,
        'type': type,
      });
      if (results == null) return [];
      return results.cast<String>();
    } catch (e) {
      return [];
    }
  }
}
