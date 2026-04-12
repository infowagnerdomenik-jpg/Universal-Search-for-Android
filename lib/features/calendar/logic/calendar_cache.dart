import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:search/features/calendar/logic/calendar_service.dart';
import 'package:search/features/search/logic/search_settings_controller.dart';
import 'package:search/features/search/logic/system_cache_service.dart';

class CalendarCache {
  static final ValueNotifier<List<NativeEvent>> allEventsNotifier = ValueNotifier([]);
  static final ValueNotifier<List<NativeEvent>> filteredEventsNotifier = ValueNotifier([]);
  static final ValueNotifier<List<NativeCalendar>> availableCalendarsNotifier = ValueNotifier([]);
  static final ValueNotifier<bool> loadingNotifier = ValueNotifier(false);
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) {
      if (allEventsNotifier.value.isEmpty) await refresh();
      return;
    }
    _isInitialized = true;
    
    // 1. Zuerst aus System-Cache laden (sofortige Anzeige)
    await _loadFromCache();
    
    // 2. Refresh im Hintergrund triggern
    refresh();
    
    SearchSettingsController().addListener(() => _applyFilter());
  }

  static Future<void> clear() async {
    await SystemCacheService.clear('calendar_events_cache');
    await SearchSettingsController().resetCalendarSettings(); // NEU: Einstellungen zurücksetzen
    allEventsNotifier.value = [];
    filteredEventsNotifier.value = [];
    availableCalendarsNotifier.value = [];
  }

  static Future<void> _loadFromCache() async {
    try {
      final String? jsonStr = await SystemCacheService.load('calendar_events_cache');
      if (jsonStr != null) {
        final List<dynamic> list = jsonDecode(jsonStr);
        allEventsNotifier.value = list.map((e) => NativeEvent.fromMap(e as Map)).toList();
        _applyFilter();
      }
    } catch (e) {
      debugPrint("Fehler beim Laden des Kalender-Speichers: $e");
    }
  }

  static Future<void> _saveToCache() async {
    try {
      final data = allEventsNotifier.value.map((e) => e.toMap()).toList();
      await SystemCacheService.save('calendar_events_cache', jsonEncode(data));
    } catch (e) {
      debugPrint("Fehler beim Speichern des Kalender-Speichers: $e");
    }
  }

  static Future<void> refresh() async {
    // 0. Vorab-Check: Darf ich überhaupt laden?
    if (!await CalendarService.checkPermission()) {
      loadingNotifier.value = false;
      return;
    }

    if (loadingNotifier.value) return;
    loadingNotifier.value = true;
    
    try {
      final rawData = await CalendarService.getRawData();
      
      // 1. Kalender mappen
      final calendars = (rawData['calendars'] as List).map((c) => NativeCalendar.fromMap(c as Map)).toList();
      availableCalendarsNotifier.value = calendars;

      // 2. Events mappen
      final events = (rawData['events'] as List).map((e) => NativeEvent.fromMap(e as Map)).toList();
      allEventsNotifier.value = events;

      // ERST-INITIALISIERUNG:
      final settings = SearchSettingsController();
      if (settings.isFirstCalendarInit && calendars.isNotEmpty) {
        final allIds = calendars.map((c) => c.id).toList();
        await settings.setEnabledCalendarIds(allIds);
        await settings.markCalendarInitialized();
      }

      // 3. Filter anwenden
      _applyFilter();
      await _saveToCache();
      
      debugPrint("Nativer Kalender Cache: Sync abgeschlossen. ${events.length} Events geladen.");
    } catch (e) {
      debugPrint("Nativer Kalender Cache: Fehler beim Sync: $e");
    } finally {
      loadingNotifier.value = false;
    }
  }

  static void _applyFilter() {
    final settings = SearchSettingsController();
    final enabledIds = settings.enabledCalendarIds;
    final limit = settings.calendarLimit;
    final now = DateTime.now();

    // Falls die Liste der IDs leer ist (Erststart), zeigen wir alle
    if (enabledIds.isEmpty && !settings.isFirstCalendarInit) {
      filteredEventsNotifier.value = [];
      return;
    }

    final filtered = allEventsNotifier.value.where((event) {
      // 1. Kalender-ID Filter
      if (enabledIds.isNotEmpty && !enabledIds.contains(event.calendarId)) return false;
      
      // 2. Nur Termine zeigen, die noch nicht vorbei sind
      final compareTime = event.end ?? event.start;
      if (compareTime != null && compareTime.isBefore(now)) return false;

      return true;
    }).toList();

    // Sortieren nach Startzeit
    filtered.sort((a, b) => (a.start ?? now).compareTo(b.start ?? now));

    filteredEventsNotifier.value = filtered.take(limit).toList();
  }
}
