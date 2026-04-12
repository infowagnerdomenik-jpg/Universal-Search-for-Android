import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/search_engine.dart';
import '../data/search_engines.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

class SearchSettingsController extends ChangeNotifier {
  static final SearchSettingsController _instance = SearchSettingsController._internal();
  factory SearchSettingsController() => _instance;

  SearchSettingsController._internal();

  SearchEngine _activeEngine = SearchEngines.defaultEngine;
  SearchEngine get activeEngine => _activeEngine;

  // NEU: Die Quelle für Privacy-Vorschläge (Standard: 'none')
  String _privacySource = 'none';
  String get privacySource => _privacySource;

  // NEU: Reihenfolge der Suchergebnisse
  List<String> _searchOrder = ['calendar', 'shortcuts', 'apps', 'contacts', 'files', 'text_results'];
  List<String> get searchOrder => _searchOrder;

  // NEU: Sichtbarkeit der Suchergebnisse
  Map<String, bool> _searchVisibility = {
    'calendar': true,
    'shortcuts': true,
    'apps': true,
    'contacts': true,
    'files': true,
    'text_results': true,
  };

  bool isVisible(String id) => _searchVisibility[id] ?? true;

  // NEU: Kalender-spezifische Einstellungen
  int _calendarLimit = 5;
  int get calendarLimit => _calendarLimit;

  // NEU: Datei-spezifische Einstellungen
  int _fileSearchLimit = 5;
  int get fileSearchLimit => _fileSearchLimit;

  int _fileWidgetLimit = 5;
  int get fileWidgetLimit => _fileWidgetLimit;

  List<String> _enabledCalendarIds = [];
  List<String> get enabledCalendarIds => _enabledCalendarIds;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // --- INIT: Öffentlich und awaitable ---
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Engine laden
    final savedId = prefs.getString('selected_search_engine_id');
    if (savedId != null) {
      try {
        _activeEngine = SearchEngines.all.firstWhere((e) => e.id == savedId);
      } catch (e) {
        _activeEngine = SearchEngines.defaultEngine;
      }
    }

    // 2. NEU: Privacy Source laden
    _privacySource = prefs.getString('privacy_source') ?? 'none';

    // 3. NEU: Such-Reihenfolge laden
    final savedOrder = prefs.getStringList('search_result_order');
    if (savedOrder != null && savedOrder.isNotEmpty) {
      _searchOrder = savedOrder;
    }

    // 4. NEU: Such-Sichtbarkeit laden
    for (var id in _searchOrder) {
      _searchVisibility[id] = prefs.getBool('search_visibility_$id') ?? true;
    }
    // Sicherstellen, dass 'calendar', 'shortcuts' und 'files' vorhanden sind
    for (var id in ['calendar', 'shortcuts', 'files']) {
      if (!_searchVisibility.containsKey(id)) {
        _searchVisibility[id] = true;
      }
      if (!_searchOrder.contains(id)) {
        // Reihenfolge beachten
        if (id == 'calendar') {
          _searchOrder.insert(0, id);
        } else if (id == 'shortcuts') {
           _searchOrder.insert(1, id);
        } else if (id == 'files') {
           final index = _searchOrder.indexOf('text_results');
           if (index != -1) {
             _searchOrder.insert(index, id);
           } else {
             _searchOrder.add(id);
           }
        }
      }
    }

    // 5. NEU: Kalender-spezifische Einstellungen laden
    _calendarLimit = prefs.getInt('calendar_limit') ?? 5;
    _fileSearchLimit = prefs.getInt('file_search_limit') ?? 5;
    _fileWidgetLimit = prefs.getInt('file_widget_limit') ?? 5;
    
    // Wir prüfen, ob jemals eine Auswahl getroffen wurde
    if (prefs.containsKey('enabled_calendar_ids')) {
      _enabledCalendarIds = prefs.getStringList('enabled_calendar_ids') ?? [];
    } else {
      // ERSTSTART: Wir setzen die Liste auf einen speziellen Wert oder lassen sie leer
      // Die eigentliche Initialisierung mit ALLen IDs machen wir im Cache, sobald die Kalender geladen sind.
      _enabledCalendarIds = [];
      _isFirstCalendarInit = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  bool _isFirstCalendarInit = false;
  bool get isFirstCalendarInit => _isFirstCalendarInit;

  Future<void> markCalendarInitialized() async {
    if (!_isFirstCalendarInit) return;
    _isFirstCalendarInit = false;
    final prefs = await SharedPreferences.getInstance();
    // Durch das Speichern einer (ggf. noch leeren) Liste markieren wir, 
    // dass die Initialisierung stattgefunden hat.
    if (!prefs.containsKey('enabled_calendar_ids')) {
      await prefs.setStringList('enabled_calendar_ids', _enabledCalendarIds);
    }
    notifyListeners();
  }

  Future<void> resetCalendarSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('enabled_calendar_ids');
    _enabledCalendarIds = [];
    _isFirstCalendarInit = true;
    notifyListeners();
  }

  // --- KALENDER SETTER ---
  Future<void> setCalendarLimit(int limit) async {
    if (_calendarLimit == limit) return;
    _calendarLimit = limit;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('calendar_limit', limit);
  }

  Future<void> setFileSearchLimit(int limit) async {
    if (_fileSearchLimit == limit) return;
    _fileSearchLimit = limit;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('file_search_limit', limit);
  }

  Future<void> setFileWidgetLimit(int limit) async {
    if (_fileWidgetLimit == limit) return;
    _fileWidgetLimit = limit;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('file_widget_limit', limit);
  }

  Future<void> setEnabledCalendarIds(List<String> ids) async {
    _enabledCalendarIds = ids;
    _isFirstCalendarInit = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('enabled_calendar_ids', ids);
  }

  Future<void> toggleCalendarId(String id) async {
    _isFirstCalendarInit = false;
    if (_enabledCalendarIds.contains(id)) {
      _enabledCalendarIds.remove(id);
    } else {
      _enabledCalendarIds.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('enabled_calendar_ids', _enabledCalendarIds);
  }

  // Die alte Version mit allIds entfernen wir
  @Deprecated('Nutze toggleCalendarId(id)')
  Future<void> toggleCalendarIdOld(String id, List<String> allIds) async {
    await toggleCalendarId(id);
  }

  Future<void> setActiveEngine(SearchEngine engine) async {
    if (_activeEngine.id == engine.id) return;

    _activeEngine = engine;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_search_engine_id', engine.id);
  }

  // NEU: Methode zum Speichern der Privacy-Einstellung
  Future<void> setPrivacySource(String source) async {
    if (_privacySource == source) return;

    _privacySource = source;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('privacy_source', source);
  }

  // NEU: Reorder-Logik für Suchergebnisse
  Future<void> reorderSearch(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _searchOrder.removeAt(oldIndex);
    _searchOrder.insert(newIndex, item);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_result_order', _searchOrder);
  }

  // NEU: Sichtbarkeit umschalten
  Future<void> toggleSearchVisibility(String id) async {
    final currentValue = _searchVisibility[id] ?? true;
    _searchVisibility[id] = !currentValue;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('search_visibility_$id', !currentValue);
  }
}