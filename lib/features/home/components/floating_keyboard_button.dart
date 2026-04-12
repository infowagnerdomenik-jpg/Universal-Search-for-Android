import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:design_engine/layer4_ui/design_engine_ui.dart';
import 'package:search/l10n/app_localizations.dart';

class FloatingKeyboardButton extends StatelessWidget {
  final VoidCallback onPressed;

  const FloatingKeyboardButton({super.key, required this.onPressed});

  // Prüft, ob es ein Touch-Gerät ist
  bool get _isTouchDevice => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Widget build(BuildContext context) {
    // Auf dem PC (Web/Windows/Mac) zeichnen wir den Button gar nicht erst
    if (!_isTouchDevice) return const SizedBox.shrink();

    // --- NEUE DESIGN ENGINE FARBEN ---
    final Color eprimary = context.eprimary;
    final Color eonprimary = context.eonprimary;

    return FloatingActionButton.extended(
      onPressed: () { HapticFeedback.lightImpact(); onPressed(); },
      backgroundColor: eprimary,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      icon: Icon(Icons.keyboard_outlined, color: eonprimary, size: 24),
      label: Text(
        AppLocalizations.of(context).get('show_keyboard'),
        style: TextStyle(color: eonprimary, fontWeight: FontWeight.w600),
      ),
    );
  }
}
