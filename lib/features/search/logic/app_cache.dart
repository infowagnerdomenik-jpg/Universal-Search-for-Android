import 'package:search/features/home/logic/app_launch_tracker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:search/features/search/logic/system_cache_service.dart';
import 'package:search/features/home/logic/app_launch_tracker.dart';

// Eine kleine Hilfsklasse, die genau die Daten hält, die wir brauchen
class CachedApp {
  final String name;
  final String packageName;
  final Uint8List? icon;

  CachedApp({required this.name, required this.packageName, this.icon});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedApp &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          packageName == other.packageName &&
          listEquals(icon, other.icon);

  @override
  int get hashCode => name.hashCode ^ packageName.hashCode ^ icon.hashCode;
}

class AppCache {
  // ValueNotifier benachrichtigt die UI automatisch (LIVE) bei Änderungen!
  static final ValueNotifier<List<CachedApp>> appsNotifier = ValueNotifier([]);
  static bool _isInitialized = false;

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('enable_app_search') ?? true; // Standardmäßig an
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_app_search', value);
    if (!value) {
      await clear(); // Cache leeren wenn deaktiviert
    } else {
      await init();
    }
  }

  static Future<void> clear() async {
    await SystemCacheService.clear('app_cache_v2');
    await AppLaunchTracker.clear(); // NEU: Auch Nutzungsdaten löschen
    appsNotifier.value = [];
  }

  static Future<void> init() async {
    if (!await isEnabled()) {
      appsNotifier.value = [];
      return;
    }
    if (_isInitialized) {
      if (appsNotifier.value.isEmpty) await refresh();
      return;
    }
    _isInitialized = true;

    final cachedData = await SystemCacheService.load('app_cache_v2');

    if (cachedData != null) {
      appsNotifier.value = _decode(cachedData);
      refresh();
    } else {
      await refresh();
    }
  }

  static Future<void> refresh() async {
    try {
      final realApps = await InstalledApps.getInstalledApps(excludeSystemApps: false, withIcon: true);

      List<CachedApp> newApps = realApps.map((a) => CachedApp(
        name: a.name ?? 'Unbekannt',
        packageName: a.packageName ?? '',
        icon: a.icon,
      )).toList();

      newApps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      // Live Update
      appsNotifier.value = newApps;

      // Speichern im System-Cache
      await SystemCacheService.save('app_cache_v2', _encode(newApps));
    } catch (e) {
      debugPrint("Fehler beim App-Update: $e");
    }
  }

  // Wandelt die Icons und Namen in Text um, damit sie gespeichert werden können
  static String _encode(List<CachedApp> apps) {
    List<Map<String, dynamic>> list = apps.map((a) => {
      'n': a.name,
      'p': a.packageName,
      'i': a.icon != null ? base64Encode(a.icon!) : null,
    }).toList();
    return jsonEncode(list);
  }

  // Holt die Daten rasend schnell aus dem Text zurück
  static List<CachedApp> _decode(String jsonStr) {
    try {
      List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => CachedApp(
        name: item['n'] ?? '',
        packageName: item['p'] ?? '',
        icon: item['i'] != null ? base64Decode(item['i']) : null,
      )).toList();
    } catch (e) {
      return [];
    }
  }
}
