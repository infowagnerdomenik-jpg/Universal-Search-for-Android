import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// --- NEUE DESIGN ENGINE IMPORTE ---
import 'package:design_engine/layer3_logic/design_engine_controller.dart';
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

import 'package:search/features/calendar/logic/calendar_service.dart';
import 'package:search/features/calendar/logic/calendar_cache.dart';
import 'package:search/l10n/app_localizations.dart';

class FrequentCalendarWidget extends StatelessWidget {
  const FrequentCalendarWidget({super.key});

  Future<void> _openEvent(NativeEvent event) async {
    await CalendarService.openEvent(event.id, start: event.start, end: event.end);
  }

  @override
  Widget build(BuildContext context) {
    // --- DESIGN ENGINE FARBEN ---
    final Color eonbg = context.eonbackground; // ehemals txt1
    final Color esv = context.esurfacevariant; // ehemals cf2
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return FutureBuilder<bool>(
      future: CalendarService.checkPermission(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: CalendarCache.loadingNotifier,
              builder: (context, isLoading, child) {
                return ValueListenableBuilder<List<NativeEvent>>(
                  valueListenable: CalendarCache.filteredEventsNotifier,
                  builder: (context, events, child) {
                    if (events.isEmpty && !isLoading) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4), // Kompakterer Abstand
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.get('calendar_agenda_title'),
                                  style: TextStyle(color: eonbg, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                if (isLoading)
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: context.eprimary.withOpacity(0.5)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: events.isEmpty && isLoading
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                                      child: Center(child: Text(l10n.get('calendar_loading'), style: TextStyle(color: eonbg.withOpacity(0.5)))),
                                    )
                                  : Column(
                                      children: List.generate(events.length, (index) {
                                        final event = events[index];
                                        return AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 200),
                                          child: Column(
                                            key: ValueKey(event.id),
                                            children: [
                                              _buildEventItem(context, event, l10n, eonbg),
                                              if (index < events.length - 1)
                                                Divider(color: eonbg.withOpacity(0.05), height: 1, thickness: 1),
                                            ],
                                          ),
                                        );
                                      }),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEventItem(BuildContext context, NativeEvent event, AppLocalizations l10n, Color eonbg) {
    final startTime = event.start != null ? DateFormat('HH:mm').format(event.start!) : '';
    final dateStr = event.start != null ? _getSmartDate(event.start!, l10n) : '';

    return InkWell(
      onTap: () { HapticFeedback.mediumImpact(); _openEvent(event); },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), // Padding wie bei Dateisuche
        child: Row(
          children: [
            // Icon mit dem Farbring
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
                    event.title ?? l10n.get('calendar_no_title'),
                    style: TextStyle(color: eonbg, fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dateStr • $startTime',
                    style: TextStyle(color: eonbg.withOpacity(0.6), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (event.location != null && event.location!.isNotEmpty)
              Icon(Icons.location_on_outlined, size: 16, color: eonbg.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  String _getSmartDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final eventDate = DateTime(date.year, date.month, date.day);

    if (eventDate == today) return l10n.get('calendar_today');
    if (eventDate == tomorrow) return l10n.get('calendar_tomorrow');
    return DateFormat('dd.MM.').format(date);
  }
}
