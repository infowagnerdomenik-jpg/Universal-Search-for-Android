import 'dart:convert';
import 'package:search/features/search/logic/system_cache_service.dart';

class AppLaunchTracker {
  static const _key = 'app_launch_counts';

  // Wird aufgerufen, wenn du auf eine App klickst
  static Future<void> recordAppLaunch(String packageName) async {
    final String? data = await SystemCacheService.load(_key);

    // Alte Daten laden oder leere Map erstellen
    Map<String, dynamic> counts = data != null ? jsonDecode(data) : {};

    // Zähler um 1 erhöhen
    counts[packageName] = (counts[packageName] ?? 0) + 1;

    // Speichern im SYSTEM-CACHE (wird bei "Cache leeren" gelöscht)
    await SystemCacheService.save(_key, jsonEncode(counts));
  }

  // Holt die Top X Apps sortiert nach Häufigkeit
  static Future<List<String>> getTopApps(int limit) async {
    final String? data = await SystemCacheService.load(_key);
    if (data == null) return [];

    Map<String, dynamic> counts = jsonDecode(data);

    // Sortieren nach dem höchsten Wert (Häufigkeit)
    var sortedKeys = counts.keys.toList(growable: false)
      ..sort((k1, k2) => (counts[k2] as int).compareTo(counts[k1] as int));

    return sortedKeys.take(limit).toList();
  }

  static Future<void> clear() async {
    await SystemCacheService.clear(_key);
  }
}
