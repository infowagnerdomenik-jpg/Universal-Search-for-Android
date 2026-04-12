class QuickSearchProvider {
  final String id;
  final String name;
  final String assetIcon;
  final String searchUrl;
  final String homeUrl;
  final bool isDynamic;

  const QuickSearchProvider({
    required this.id,
    required this.name,
    required this.assetIcon,
    required this.searchUrl,
    required this.homeUrl,
    this.isDynamic = false,
  });

  static const List<QuickSearchProvider> all = [
    QuickSearchProvider(
      id: 'youtube',
      name: 'YouTube',
      assetIcon: 'assets/icons/original/youtube.svg',
      searchUrl: 'https://www.youtube.com/results?search_query={q}',
      homeUrl: 'https://www.youtube.com',
    ),
    QuickSearchProvider(
      id: 'yt_music',
      name: 'YouTube Music',
      assetIcon: 'assets/icons/original/youtube_music.svg',
      searchUrl: 'https://music.youtube.com/search?q={q}',
      homeUrl: 'https://music.youtube.com',
    ),
    QuickSearchProvider(
      id: 'amazon',
      name: 'Amazon',
      assetIcon: 'assets/icons/original/amazon.svg',
      searchUrl: 'https://www.amazon.de/s?k={q}',
      homeUrl: 'https://www.amazon.de',
    ),
    QuickSearchProvider(
      id: 'chatgpt',
      name: 'ChatGPT',
      assetIcon: 'assets/icons/dynamic/OpenAI-white-monoblossom.svg',
      searchUrl: 'https://chatgpt.com/?q={q}',
      homeUrl: 'https://chatgpt.com',
      isDynamic: true,
    ),
    QuickSearchProvider(
      id: 'spotify',
      name: 'Spotify',
      assetIcon: 'assets/icons/original/spotify.svg',
      searchUrl: 'https://open.spotify.com/search/{q}',
      homeUrl: 'https://open.spotify.com',
    ),
    QuickSearchProvider(
      id: 'wikipedia',
      name: 'Wikipedia',
      assetIcon: 'assets/icons/original/wikipedia.svg',
      searchUrl: 'https://de.wikipedia.org/wiki/Special:Search?search={q}',
      homeUrl: 'https://de.wikipedia.org',
    ),
    QuickSearchProvider(
      id: 'osm',
      name: 'OpenStreetMap',
      assetIcon: 'assets/icons/original/osm.svg',
      searchUrl: 'https://www.openstreetmap.org/search?query={q}',
      homeUrl: 'https://www.openstreetmap.org',
    ),
    QuickSearchProvider(
      id: 'maps',
      name: 'Maps',
      assetIcon: 'assets/icons/original/google_maps.svg',
      searchUrl: 'https://www.google.com/maps/search/{q}',
      homeUrl: 'https://www.google.com/maps',
    ),
  ];
}
