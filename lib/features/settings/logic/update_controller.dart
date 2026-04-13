import 'package:flutter/material.dart';
import 'package:search/features/search/logic/internet_service.dart';
import 'package:search/features/search/logic/file_service.dart';

class UpdateController extends ChangeNotifier {
  static final UpdateController _instance = UpdateController._internal();
  factory UpdateController() => _instance;
  UpdateController._internal();

  bool _isUpdateAvailable = false;
  bool get isUpdateAvailable => _isUpdateAvailable;

  static const String appVersion = 'Alpha 1.0.1 Github';

  Future<void> checkUpdates() async {
    final internetInstalled = await InternetService.isCompanionInstalled();
    if (!internetInstalled) {
      if (_isUpdateAvailable) {
        _isUpdateAvailable = false;
        notifyListeners();
      }
      return;
    }

    final repos = [
      'Universal-Search-for-Android',
      'Search-Files-Companion',
      'Search-Internet-Companion'
    ];

    bool foundUpdate = false;
    for (final repo in repos) {
      // Wenn es die File-Companion Repo ist, prüfen wir nur wenn sie auch installiert ist
      if (repo == 'Search-Files-Companion') {
        final installed = await FileService.isCompanionInstalled();
        if (!installed) continue;
      }

      final latest = await InternetService.fetchVersion(repo: repo);
      if (latest != null) {
        final cleanLocal = appVersion.toLowerCase().replaceAll('alpha', '').replaceAll('(no github)', '').trim();
        final cleanLatest = latest.toLowerCase().replaceAll('v', '').replaceAll('alpha', '').trim();
        
        if (cleanLatest != cleanLocal && !cleanLocal.contains(cleanLatest)) {
          foundUpdate = true;
          break;
        }
      }
    }

    if (_isUpdateAvailable != foundUpdate) {
      _isUpdateAvailable = foundUpdate;
      notifyListeners();
    }
  }
}
