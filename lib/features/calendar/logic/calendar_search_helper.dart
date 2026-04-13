import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:search/l10n/app_localizations.dart';
import 'package:search/features/calendar/logic/calendar_service.dart';

class CalendarSearchHelper {
  /// Prüft, ob der Suchstring ein Datum, ein Wochentag oder ein relatives Wort ist.
  /// Falls ja, wird eine Liste von passenden Zeitfenstern (Start/Ende) zurückgegeben.
  static List<DateTimeRange>? parseSearchQuery(String query, BuildContext context) {
    final q = query.toLowerCase().trim();
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Relativ: Heute / Morgen
    if (q == l10n.get('search_date_today')) {
      return [DateTimeRange(start: today, end: today.add(const Duration(days: 1)))];
    }
    if (q == l10n.get('search_date_tomorrow')) {
      final tomorrow = today.add(const Duration(days: 1));
      return [DateTimeRange(start: tomorrow, end: tomorrow.add(const Duration(days: 1)))];
    }

    // 2. Wochentage (Montag - Sonntag)
    final weekDays = {
      DateTime.monday: l10n.get('search_day_monday'),
      DateTime.tuesday: l10n.get('search_day_tuesday'),
      DateTime.wednesday: l10n.get('search_day_wednesday'),
      DateTime.thursday: l10n.get('search_day_thursday'),
      DateTime.friday: l10n.get('search_day_friday'),
      DateTime.saturday: l10n.get('search_day_saturday'),
      DateTime.sunday: l10n.get('search_day_sunday'),
    };

    int? targetWeekday;
    weekDays.forEach((day, name) {
      if (q == name) targetWeekday = day;
    });

    if (targetWeekday != null) {
      // Wir geben die nächsten 52 Wochen als mögliche Ziele zurück (für das Auffüllen)
      List<DateTimeRange> ranges = [];
      DateTime current = today;
      // Finde den ersten passenden Tag (heute oder in der Zukunft)
      while (current.weekday != targetWeekday) {
        current = current.add(const Duration(days: 1));
      }
      
      // Erstelle die nächsten 10 Vorkommen dieses Wochentags
      for (int i = 0; i < 10; i++) {
        final day = current.add(Duration(days: i * 7));
        ranges.add(DateTimeRange(start: day, end: day.add(const Duration(days: 1))));
      }
      return ranges;
    }

    // 3. Exaktes Datum (Sprachabhängig)
    // Wir versuchen verschiedene Formate basierend auf der Locale
    final locale = Localizations.localeOf(context).toString();
    
    // Einfache Regex für TT.MM. (oder MM/DD)
    // Wir unterstützen: "13.12", "13.12.", "13.12.2026", "12/13", "12/13/2026"
    final dateRegex = RegExp(r'^(\d{1,2})[\.\/](\d{1,2})(?:[\.\/](\d{2,4}))?\.?$');
    final match = dateRegex.firstMatch(q);

    if (match != null) {
      int part1 = int.parse(match.group(1)!);
      int part2 = int.parse(match.group(2)!);
      int? year = match.group(3) != null ? int.parse(match.group(3)!) : null;
      if (year != null && year < 100) year += 2000;

      int day, month;
      // Einfache Logik: Wenn Locale US/UK, dann MM/DD, sonst DD.MM.
      if (locale.startsWith('en_US') || locale.startsWith('en_CA')) {
        month = part1;
        day = part2;
      } else {
        day = part1;
        month = part2;
      }

      try {
        if (year != null) {
          final target = DateTime(year, month, day);
          return [DateTimeRange(start: target, end: target.add(const Duration(days: 1)))];
        } else {
          // Wiederkehrendes Datum (nächsten 5 Jahre)
          List<DateTimeRange> ranges = [];
          for (int i = 0; i < 5; i++) {
            final target = DateTime(today.year + i, month, day);
            // Nur wenn der Tag nicht in der Vergangenheit liegt (beim aktuellen Jahr)
            if (i == 0 && target.isBefore(today)) continue;
            ranges.add(DateTimeRange(start: target, end: target.add(const Duration(days: 1))));
          }
          return ranges;
        }
      } catch (e) { return null; }
    }

    return null;
  }

  /// Prüft, ob ein Event in eines der Zeitfenster fällt.
  static bool isEventInRange(NativeEvent event, List<DateTimeRange> ranges) {
    if (event.start == null) return false;
    final eventStart = event.start!;
    
    for (final range in ranges) {
      // Ein Event ist "in Range", wenn es am selben Tag beginnt (für diese Suche)
      if (eventStart.isAfter(range.start.subtract(const Duration(seconds: 1))) && 
          eventStart.isBefore(range.end)) {
        return true;
      }
    }
    return false;
  }
}
