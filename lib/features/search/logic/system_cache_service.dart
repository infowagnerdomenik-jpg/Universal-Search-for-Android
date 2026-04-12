import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class SystemCacheService {
  static Future<File> _getCacheFile(String fileName) async {
    final cacheDir = await getTemporaryDirectory();
    return File('${cacheDir.path}/$fileName.json');
  }

  static Future<void> save(String key, String data) async {
    try {
      final file = await _getCacheFile(key);
      await file.writeAsString(data);
    } catch (e) {
      debugPrint("SystemCache: Fehler beim Speichern von $key: $e");
    }
  }

  static Future<String?> load(String key) async {
    try {
      final file = await _getCacheFile(key);
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      debugPrint("SystemCache: Fehler beim Laden von $key: $e");
    }
    return null;
  }

  static Future<void> clear(String key) async {
    try {
      final file = await _getCacheFile(key);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {}
  }
}
