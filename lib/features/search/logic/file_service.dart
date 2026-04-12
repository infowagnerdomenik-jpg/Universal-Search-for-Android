import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/cached_file.dart';

class FileService {
  static const _channel = MethodChannel('de.search.dw.search/files');
  static const _permissionChannel = MethodChannel('de.search.dw.search/permissions');
  static const String _filePermission = "de.search.companion.dw.READ_FILES";

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('enable_companion_access') ?? false;
  }

  static Future<bool> hasPermission() async {
    try {
      return await _permissionChannel.invokeMethod('checkPermission', {'permission': _filePermission}) ?? false;
    } catch (_) { return false; }
  }

  static Future<List<CachedFile>> searchFiles(String query) async {
    if (!await isEnabled()) return [];
    if (!await hasPermission()) return []; // NEU: Harter Check vor der Suche
    
    try {
      final List<dynamic>? results = await _channel.invokeMethod('searchFiles', {'query': query});
      if (results == null) return [];
      
      return results.map((e) => CachedFile.fromMap(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> openFile(String path) async {
    if (!await isEnabled()) return false;
    
    try {
      final success = await _channel.invokeMethod('openFile', {'path': path});
      return success == true;
    } catch (e) {
      return false;
    }
  }

  static Future<Uint8List?> getThumbnail(String path) async {
    try {
      final Uint8List? bytes = await _channel.invokeMethod('getFileThumbnail', {'path': path});
      return bytes;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> isCompanionInstalled() async {
    try {
      return await _channel.invokeMethod('hasFilePermissions') ?? false;
    } catch (e) {
      return false;
    }
  }
}
