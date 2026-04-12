import 'dart:convert';
import 'package:search/features/search/logic/system_cache_service.dart';

class ContactLaunchTracker {
  static const _key = 'contact_launch_counts';

  static Future<void> recordContactLaunch(String contactId) async {
    final String? data = await SystemCacheService.load(_key);

    Map<String, dynamic> counts = data != null ? jsonDecode(data) : {};
    counts[contactId] = (counts[contactId] ?? 0) + 1;

    await SystemCacheService.save(_key, jsonEncode(counts));
  }

  static Future<List<String>> getTopContacts(int limit) async {
    final String? data = await SystemCacheService.load(_key);
    if (data == null) return [];

    Map<String, dynamic> counts = jsonDecode(data);

    var sortedKeys = counts.keys.toList(growable: false)
      ..sort((k1, k2) => (counts[k2] as int).compareTo(counts[k1] as int));

    return sortedKeys.take(limit).toList();
  }

  static Future<void> clear() async {
    await SystemCacheService.clear(_key);
  }
}
