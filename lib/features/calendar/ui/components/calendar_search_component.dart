import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// --- NEUE DESIGN ENGINE IMPORTE ---
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

import 'package:search/features/calendar/logic/calendar_service.dart';
import 'package:search/features/calendar/logic/calendar_cache.dart';
import 'package:search/features/search/logic/search_settings_controller.dart';
import 'package:search/features/search/logic/search_status_controller.dart';
import 'package:search/l10n/app_localizations.dart';

class CalendarSearchComponent extends StatefulWidget {
  final String query;

  const CalendarSearchComponent({super.key, required this.query});

  @override
  State<CalendarSearchComponent> createState() => _CalendarSearchComponentState();
}

class _CalendarSearchComponentState extends State<CalendarSearchComponent> {
  List<NativeEvent> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void didUpdateWidget(CalendarSearchComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _performSearch();
    }
  }

  void _performSearch() {
    final q = widget.query.toLowerCase().trim();
    if (q.length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    final settings = SearchSettingsController();
    final enabledIds = settings.enabledCalendarIds;
    final limit = settings.calendarLimit;

    final results = CalendarCache.allEventsNotifier.value.where((event) {
      if (enabledIds.isNotEmpty && !enabledIds.contains(event.calendarId)) return false;
      final title = event.title?.toLowerCase() ?? '';
      return title.contains(q);
    }).toList();

    setState(() {
      _searchResults = results.take(limit).toList();
    });
    SearchStatusController().reportResults('calendar', _searchResults.length);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: CalendarService.checkPermission(),
      builder: (context, snapshot) {
        if (snapshot.data != true || _searchResults.isEmpty) return const SizedBox.shrink();

        // --- DESIGN ENGINE FARBEN ---
        final Color eonsv = context.eonsurfacevariant; // ehemals txt1
        final Color esv = context.esurfacevariant;     // ehemals cf2
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        return Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), // Optimierter Abstand
            decoration: BoxDecoration(
              color: esv,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.0 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).get('calendar_title'),
                  style: TextStyle(color: eonsv, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Column(
                  children: List.generate(_searchResults.length, (index) {
                    final event = _searchResults[index];
                    return Column(
                      children: [
                        _buildEventItem(context, event, eonsv),
                        if (index < _searchResults.length - 1)
                          Divider(color: eonsv.withOpacity(0.05), height: 1, thickness: 1),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventItem(BuildContext context, NativeEvent event, Color eonsv) {
    final startTime = event.start != null ? DateFormat('HH:mm').format(event.start!) : '';
    final dateStr = event.start != null ? DateFormat('dd. MMM').format(event.start!) : '';

    return InkWell(
      onTap: () { HapticFeedback.mediumImpact(); CalendarService.openEvent(event.id, start: event.start, end: event.end); },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: event.color != null ? Color(event.color!).withOpacity(0.8) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: const AppFallbackIcon(icon: Icons.calendar_today, size: 36, iconSize: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title ?? 'Unbenannter Termin',
                    style: TextStyle(color: eonsv, fontWeight: FontWeight.w500, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dateStr • $startTime',
                    style: TextStyle(color: eonsv.withOpacity(0.6), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
