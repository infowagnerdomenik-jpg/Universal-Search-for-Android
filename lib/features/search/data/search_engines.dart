import '../domain/models/search_engine.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

class SearchEngines {
  static const List<SearchEngine> all = [
    SearchEngine(
      id: 'google',
      name: 'Google',
      assetIcon: 'assets/icons/original/Google_Favicon_2025.svg',
      searchUrl: 'https://www.google.com/search?q={q}',
      type: SuggestionType.google,
    ),
    SearchEngine(
      id: 'google_ai',
      name: 'Google AI',
      assetIcon: 'assets/icons/dynamic/google_AI_Search_48dp_FFFFFF_FILL1_wght400_GRAD0_opsz48.svg',
      searchUrl: 'https://www.google.com/search?udm=50&aep=11&q={q}',
      type: SuggestionType.google,
    ),
    SearchEngine(
      id: 'bing',
      name: 'Bing',
      assetIcon: 'assets/icons/original/Bing_Fluent_Logo.svg',
      searchUrl: 'https://www.bing.com/search?q={q}',
      type: SuggestionType.bing,
    ),
    SearchEngine(
      id: 'duckduckgo',
      name: 'DuckDuckGo',
      assetIcon: 'assets/icons/original/duckduckgo-icon.svg',
      searchUrl: 'https://duckduckgo.com/?q={q}',
      type: SuggestionType.duckDuckGo, // Führt jetzt zu leerer Liste
    ),
    SearchEngine(
      id: 'startpage',
      name: 'Startpage',
      assetIcon: 'assets/icons/original/startpage-icon.svg',
      searchUrl: 'https://www.startpage.com/sp/search?query={q}',
      type: SuggestionType.duckDuckGo, // Führt jetzt zu leerer Liste
    ),
    SearchEngine(
      id: 'ecosia',
      name: 'Ecosia',
      assetIcon: 'assets/icons/original/Ecosia-like_logo.svg',
      searchUrl: 'https://www.ecosia.org/search?q={q}',
      type: SuggestionType.qwant, // Nutzt jetzt Qwant Vorschläge
    ),
    SearchEngine(
      id: 'brave',
      name: 'Brave',
      assetIcon: 'assets/icons/original/brave_logo.svg',
      searchUrl: 'https://search.brave.com/search?q={q}',
      type: SuggestionType.openSearch, // Sollte funktionieren (via Bing API Fallback im Service)
    ),
    SearchEngine(
      id: 'perplexity',
      name: 'Perplexity',
      assetIcon: 'assets/icons/dynamic/Pure White.svg',
      searchUrl: 'https://www.perplexity.ai/search?q={q}',
      type: SuggestionType.none,
    ),
    SearchEngine(
      id: 'qwant',
      name: 'Qwant',
      assetIcon: 'assets/icons/original/Qwant_new_logo_2018.svg',
      searchUrl: 'https://www.qwant.com/?q={q}',
      type: SuggestionType.qwant,
    ),
  ];

  static SearchEngine get defaultEngine => all[0];

  static SearchEngine findById(String id) {
    return all.firstWhere((e) => e.id == id, orElse: () => defaultEngine);
  }
}