import 'package:flutter/material.dart';
import 'package:search/features/search/logic/internet_service.dart';
import 'package:search/features/search/logic/file_service.dart';

class UpdateController extends ChangeNotifier {
  static final UpdateController _instance = UpdateController._internal();
  factory UpdateController() => _instance;
  UpdateController._internal();

  bool _isUpdateAvailable = false;
  bool get isUpdateAvailable => _isUpdateAvailable;

  // --- ZENTRALE VERSIONSVERWALTUNG ---
  static const String mainVersion = 'Alpha 1.0.3 Github';
  static const String fileVersion = 'Alpha 1.0.1 Github';
  static const String internetVersion = 'Alpha 1.0.1 Github';

  Future<void> checkUpdates() async {
    final internetInstalled = await InternetService.isCompanionInstalled();
    if (!internetInstalled) {
      if (_isUpdateAvailable) {
        _isUpdateAvailable = false;
        notifyListeners();
      }
      return;
    }

    // Prüfung der drei Repositories mit ihren jeweiligen Versionen
    final mainUpdate = await _hasUpdate(repo: 'Universal-Search-for-Android', local: mainVersion);
    
    bool fileUpdate = false;
    if (await FileService.isCompanionInstalled()) {
      fileUpdate = await _hasUpdate(repo: 'Search-Files-Companion', local: fileVersion);
    }

    final internetUpdate = await _hasUpdate(repo: 'Search-Internet-Companion', local: internetVersion);

    final foundUpdate = mainUpdate || fileUpdate || internetUpdate;

    if (_isUpdateAvailable != foundUpdate) {
      _isUpdateAvailable = foundUpdate;
      notifyListeners();
    }
  }

  Future<bool> _hasUpdate({required String repo, required String local}) async {
    final latest = await InternetService.fetchVersion(repo: repo);
    if (latest == null) return false;

    final cleanLocal = _cleanVersion(local);
    final cleanLatest = _cleanVersion(latest);

    // Update nur, wenn Remote > Local
    return _isVersionHigher(cleanLatest, cleanLocal);
  }

  String _cleanVersion(String v) {
    return v.toLowerCase()
        .replaceAll('alpha', '')
        .replaceAll('(no github)', '')
        .replaceAll('github', '')
        .trim();
  }

  bool _isVersionHigher(String remote, String local) {
    try {
      List<int> remoteParts = remote.split('.').map((e) => int.parse(e.replaceAll(RegExp(r'[^0-9]'), ''))).toList();
      List<int> localParts = local.split('.').map((e) => int.parse(e.replaceAll(RegExp(r'[^0-9]'), ''))).toList();
      
      for (int i = 0; i < remoteParts.length && i < localParts.length; i++) {
        if (remoteParts[i] > localParts[i]) return true;
        if (remoteParts[i] < localParts[i]) return false;
      }
      return remoteParts.length > localParts.length;
    } catch (e) {
      return remote != local; 
    }
  }
}
