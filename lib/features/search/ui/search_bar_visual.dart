import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:search/features/search/logic/search_settings_controller.dart';
import 'package:search/features/search/ui/components/engine_switcher_sheet.dart';

// --- NEUE DESIGN ENGINE IMPORTE ---
import 'package:design_engine/layer3_logic/design_engine_controller.dart';
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

import 'package:search/l10n/app_localizations.dart';

class SearchBarVisual extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSearch;

  const SearchBarVisual({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final searchController = SearchSettingsController();

    return ListenableBuilder(
      listenable: searchController,
      builder: (context, child) {
        // --- DESIGN ENGINE FARBEN ---
        final Color esv = context.esurfacevariant; // ehemals cf2
        final Color ep = context.eprimary;         // ehemals cf3
        final Color eonbg = context.eonbackground; // ehemals txt1
        final Color eonp = context.eonprimary;     // ehemals txt2 (Icon auf ep-Hintergrund)
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: esv,
            borderRadius: BorderRadius.circular(30),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      spreadRadius: -4,
                      offset: const Offset(0, 0),
                    ),
                  ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => const EngineSwitcherSheet(),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 4), // Nach oben ausgerichtet + Ausgleich für Text-Padding
                  padding: const EdgeInsets.all(8),
                  color: Colors.transparent,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: SvgPicture.asset(
                      searchController.activeEngine.assetIcon,
                      colorFilter: searchController.activeEngine.id == 'perplexity'
                              ? const ColorFilter.mode(Color(0xFF20808D), BlendMode.srcIn)
                              : null,
                      placeholderBuilder: (_) => Icon(Icons.search, color: eonbg, size: 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: false, // Geändert: Fokus wird manuell gesteuert
                  style: TextStyle(color: eonbg, fontSize: 16),
                  cursorColor: ep,
                  textInputAction: TextInputAction.search,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: AppLocalizations.of(context).get('search_hint'),
                    hintStyle: TextStyle(color: eonbg.withOpacity(0.5)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12), // Angepasst für Multiline Padding
                  ),
                  onSubmitted: (value) => onSearch(),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      controller.clear();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 10), // Ausrichtung an Text-Zeile 1
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.close, color: ep, size: 24),
                    ),
                  );
                },
              ),
              GestureDetector(
                onTap: () { HapticFeedback.mediumImpact(); onSearch(); },
                child: Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(color: ep, shape: BoxShape.circle),
                  child: Icon(Icons.arrow_forward, color: eonp, size: 24),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}