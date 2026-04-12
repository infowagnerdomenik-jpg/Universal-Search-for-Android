import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:search/features/search/data/search_engines.dart';
import 'package:search/features/search/logic/search_settings_controller.dart';
import 'package:search/l10n/app_localizations.dart';

// --- NEUE DESIGN ENGINE IMPORTE ---
import 'package:design_engine/layer3_logic/design_engine_controller.dart';
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

class EngineSwitcherSheet extends StatelessWidget {
  const EngineSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final searchController = SearchSettingsController();

    // Wir hören nur auf SearchSettings (für aktive Engine Auswahl)
    return ListenableBuilder(
      listenable: searchController,
      builder: (context, child) {

        // === DESIGN ENGINE FARBEN ===
        final Color esv = context.esurfacevariant; // ehemals cf2 (Surface)
        final Color ep = context.eprimary;         // ehemals cf3 (Accent)
        final Color eonbg = context.eonbackground; // ehemals txt1 (Text)

        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(context),
              child: const SizedBox.expand(),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: IntrinsicWidth(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 712), 
              decoration: BoxDecoration(
                color: esv,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                bottom: true,
                top: true,
                left: false,
                right: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle Indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: eonbg.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16, left: 2),
                            child: Text(
                              AppLocalizations.of(context).get('active_engine_header'),
                              style: TextStyle(
                                color: eonbg,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.start, 
                            children: SearchEngines.all.map((engine) {
                              final isSelected = searchController.activeEngine.id == engine.id;

                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  searchController.setActiveEngine(engine);
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  width: 85,
                                  height: 85,
                                  decoration: BoxDecoration(
                                    color: isSelected ? ep.withOpacity(0.1) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? ep : eonbg.withOpacity(0.1),
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 32,
                                        width: 32,
                                        child: SvgPicture.asset(
                                          engine.assetIcon,
                                          colorFilter: engine.id == 'perplexity'
                                                  ? const ColorFilter.mode(Color(0xFF20808D), BlendMode.srcIn)
                                                  : null,
                                          placeholderBuilder: (_) => Icon(
                                            Icons.public,
                                            color: isSelected ? ep : eonbg,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text(
                                          engine.name,
                                          style: TextStyle(
                                            color: isSelected ? ep : eonbg,
                                            fontSize: 11,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
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
      },
    );
  }
}