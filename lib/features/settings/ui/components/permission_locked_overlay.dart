import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- NEUER DESIGN ENGINE IMPORT ---
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

import 'package:search/features/settings/ui/permissions_screen.dart';

class PermissionLockedOverlay extends StatelessWidget {
  final Widget child;
  final bool isLocked;
  final String featureName;
  final String description;
  final VoidCallback? onRefresh;

  const PermissionLockedOverlay({
    super.key,
    required this.child,
    required this.isLocked,
    required this.featureName,
    required this.description,
    this.onRefresh,
  });

  void _handleActivation(BuildContext context) {
    // --- NEUE LAYER-4 FARBEN ---
    final Color cf2 = context.esurfacevariant;         // ehemals cf2
    final Color cf3 = context.esurfacecontainerhigh;   // ehemals cf3
    final Color txt1 = context.eonsurface;             // ehemals txt1
    final Color txt2 = context.eonsurfacevariant;      // ehemals txt2

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cf2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.lock_person_outlined, color: cf3),
            const SizedBox(width: 12),
            Text("Berechtigung", style: TextStyle(color: txt1)),
          ],
        ),
        content: Text(
          "Um den $featureName zu nutzen, wird eine Berechtigung benötigt.\n\n$description",
          style: TextStyle(color: txt1.withOpacity(0.7), fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Abbrechen", style: TextStyle(color: txt1.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PermissionsScreen()),
              );
              if (onRefresh != null) onRefresh!();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cf3,
              foregroundColor: txt2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
            ),
            child: const Text("Zu den Einstellungen"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;

    // --- NEUE LAYER-4 FARBEN ---
    final Color txt2 = context.eonsurfacevariant;
    final Color cf3 = context.esurfacecontainerhigh;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Content stark ausgegraut
        Opacity(
          opacity: 0.15,
          child: AbsorbPointer(child: child),
        ),

        // Zentraler Aktivierungs-Button
        Positioned.fill(
          child: Center(
            child: GestureDetector(
              onTap: () { HapticFeedback.mediumImpact(); _handleActivation(context); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: cf3,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.0 : 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, color: txt2, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Aktivieren",
                      style: TextStyle(
                        color: txt2,
                        fontSize: 13,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
