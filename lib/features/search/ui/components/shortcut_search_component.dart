import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- NEUE DESIGN ENGINE IMPORTE ---
import 'package:design_engine/layer3_logic/design_engine_controller.dart';
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

import 'package:search/features/search/logic/shortcut_service.dart';
import 'package:search/features/search/logic/search_status_controller.dart';

class ShortcutSearchComponent extends StatefulWidget {
  final String query;

  const ShortcutSearchComponent({super.key, required this.query});

  @override
  State<ShortcutSearchComponent> createState() => _ShortcutSearchComponentState();
}

class _ShortcutSearchComponentState extends State<ShortcutSearchComponent> {
  List<SystemShortcut> _shortcuts = [];

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void didUpdateWidget(ShortcutSearchComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _performSearch();
    }
  }

  Future<void> _performSearch() async {
    final results = await ShortcutService.searchShortcuts(widget.query);
    if (mounted) {
      setState(() {
        _shortcuts = results;
      });
      SearchStatusController().reportResults('shortcuts', results.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_shortcuts.isEmpty) return const SizedBox.shrink();

    // --- DESIGN ENGINE FARBEN ---
    final Color eonbg = context.eonbackground; // ehemals txt1
    final Color esv = context.esurfacevariant; // ehemals cf2
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16), // Einheitliches Padding
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
              "Einstellungen",
              style: TextStyle(color: eonbg, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero, // Wichtig: Kein internes Padding
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 0,
                crossAxisSpacing: 8,
                mainAxisExtent: 82, // Exakt angepasst
              ),
              itemCount: _shortcuts.length > 8 ? 8 : _shortcuts.length,
              itemBuilder: (context, index) {
                final shortcut = _shortcuts[index];
                return GestureDetector(
                  onTap: () { HapticFeedback.mediumImpact(); ShortcutService.launch(shortcut); },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppFallbackIcon(icon: shortcut.icon, size: 56, iconSize: 28),
                      const SizedBox(height: 4),
                      Text(
                        shortcut.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: eonbg, fontSize: 11, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
