import 'package:flutter/services.dart';
import 'package:search/features/search/domain/models/search_engine.dart';
import 'package:search/features/search/logic/search_settings_controller.dart';
import 'package:search/features/search/logic/internet_service.dart';

class SuggestionService {
  static const _permissionChannel = MethodChannel('de.search.dw.search/permissions');
  static const String _internetPermission = "de.search.companion.internet.dw.INTERNET_ACCESS";

  /// Ruft Vorschläge basierend auf dem Typ der Suchmaschine ab
  static Future<List<String>> fetchSuggestions(String query, SuggestionType type) async {
    if (query.trim().length < 2) return [];

    try {
      // 1. Ist die Funktion in den Einstellungen an?
      if (!await InternetService.isEnabled()) return [];

      // 2. Ist der Begleiter installiert?
      if (!await InternetService.isCompanionInstalled()) return [];

      // 3. Haben wir die System-Berechtigung? (NEU: Stiller Check)
      final bool hasPermission = await _permissionChannel.invokeMethod('checkPermission', {'permission': _internetPermission}) ?? false;
      if (!hasPermission) return [];

      switch (type) {
        case SuggestionType.google:
          return await InternetService.fetchSuggestions(query, 'google');

        case SuggestionType.qwant:
          return await InternetService.fetchSuggestions(query, 'qwant');

        case SuggestionType.bing:
        case SuggestionType.openSearch:
          return await InternetService.fetchSuggestions(query, 'bing');

        case SuggestionType.none: // Perplexity & Andere ohne eigene API
        case SuggestionType.duckDuckGo: // Startpage, DDG
        // HIER IST DIE LOGIK-WEICHE:
        // Wir holen die Einstellung aus dem Controller
          final source = SearchSettingsController().privacySource;

          switch (source) {
            case 'google':
              return await InternetService.fetchSuggestions(query, 'google');
            case 'bing':
              return await InternetService.fetchSuggestions(query, 'bing');
            case 'brave':
              return await InternetService.fetchSuggestions(query, 'brave');
            case 'qwant':
              return await InternetService.fetchSuggestions(query, 'qwant');
            case 'none':
            default:
              return []; // Gar keine Vorschläge (Datenschutz pur)
          }
      }
    } catch (e) {
      return [];
    }
  }
}