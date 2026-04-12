import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:search/features/search/logic/system_cache_service.dart';
import '../domain/models/cached_file.dart';

class FileCache {
  static final ValueNotifier<List<CachedFile>> recentFilesNotifier = ValueNotifier([]);
  static const int _maxRecents = 20;
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await _loadFromCache();
  }

  static Future<void> clear() async {
    await SystemCacheService.clear('recent_files_cache_v2');
    recentFilesNotifier.value = [];
  }

  static Future<void> _loadFromCache() async {
    try {
      final String? jsonStr = await SystemCacheService.load('recent_files_cache_v2');
      if (jsonStr != null) {
        final List<dynamic> list = jsonDecode(jsonStr);
        recentFilesNotifier.value = list.map((e) => CachedFile.fromMap(e as Map)).toList();
      }
    } catch (e) {
      debugPrint("Error loading file cache: $e");
    }
  }

  static Future<void> addRecent(CachedFile file) async {
    final currentList = List<CachedFile>.from(recentFilesNotifier.value);
    currentList.removeWhere((f) => f.path == file.path);
    currentList.insert(0, file);
    if (currentList.length > _maxRecents) {
      currentList.removeLast();
    }
    recentFilesNotifier.value = currentList;
    await _saveToCache(currentList);
  }

  static Future<void> _saveToCache(List<CachedFile> files) async {
    try {
      final data = files.map((f) => f.toMap()).toList();
      await SystemCacheService.save('recent_files_cache_v2', jsonEncode(data));
    } catch (e) {
      debugPrint("Error saving file cache: $e");
    }
  }
}
