enum SuggestionType { google, bing, duckDuckGo, openSearch, qwant, none }

class SearchEngine {
  final String id;
  final String name;
  final String assetIcon; // Pfad zum SVG

  final String searchUrl;
  final String? suggestionUrl;
  final SuggestionType type;

  const SearchEngine({
    required this.id,
    required this.name,
    required this.assetIcon,
    required this.searchUrl,
    this.suggestionUrl,
    this.type = SuggestionType.none,
  });
}