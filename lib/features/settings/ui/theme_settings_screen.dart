import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:design_engine/layer3_logic/design_engine_controller.dart';
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

import 'package:search/l10n/app_localizations.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<DesignEngineController>(context);
    final l10n = AppLocalizations.of(context);

    final Color ebg   = context.ebackground;
    final Color esv   = context.esurfacevariant;
    final Color ep    = context.eprimary;
    final Color eonbg = context.eonbackground;
    final Color eonsv = context.eonsurfacevariant;

    final bool isDark = controller.isEffectiveDark(context);

    // Globaler Statusleisten-Fix: Erzwingt die korrekte Helligkeit unabhängig vom System
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    const topShape = BorderRadius.only(
      topLeft: Radius.circular(28), topRight: Radius.circular(28),
      bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4),
    );
    const midShape = BorderRadius.all(Radius.circular(4));
    const botShape = BorderRadius.only(
      topLeft: Radius.circular(4), topRight: Radius.circular(4),
      bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28),
    );

    final modeShape = isDark ? midShape : botShape;

    final themes = [
      AppTheme.system,
      AppTheme.standard,
      AppTheme.blue,
      AppTheme.green,
      AppTheme.red,
      AppTheme.nothing,
    ];

    final Color colorDay = controller.lightTheme?.colorScheme.primaryContainer ?? Colors.white;
    final Color colorNight = controller.darkTheme?.colorScheme.primaryContainer ?? Colors.black;

    return Scaffold(
      backgroundColor: ebg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: eonbg,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.get('theme_title'),
          style: TextStyle(color: eonbg, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // --- Preview ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _ThemePreviewCard(
              accentColor: ep,
              backgroundColor: ebg,
              surfaceColor: esv,
              textColor: eonbg,
              label: l10n.get('preview_title'),
            ),
          ),

          const SizedBox(height: 16),

          // --- Settings ---
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Color selection
                        _SectionCard(
                          shape: topShape,
                          esv: esv,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                                child: Text(
                                  l10n.get('theme_section_color'),
                                  style: TextStyle(color: eonbg, fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                                child: Row(
                                  children: themes.map((theme) => _ColorCircleItem(
                                    label: _themeLabel(theme, l10n),
                                    color: controller.eprimaryForTheme(theme, context),
                                    isSelected: controller.currentTheme == theme,
                                    textColor: eonsv,
                                    selectionColor: ep,
                                    onTap: () { HapticFeedback.selectionClick(); controller.setTheme(theme); },
                                  )).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 3),

                        // Brightness
                        _SectionCard(
                          shape: modeShape,
                          esv: esv,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                                child: Text(
                                  l10n.get('theme_section_brightness'),
                                  style: TextStyle(color: eonbg, fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                                child: Row(
                                  children: [
                                    _ModeCircleItem(
                                      label: l10n.get('theme_mode_auto'),
                                      isSelected: controller.themeMode == ThemeMode.system,
                                      isSplit: true,
                                      fillColorA: colorDay,
                                      fillColorB: colorNight,
                                      textColor: eonsv,
                                      selectionColor: ep,
                                      onTap: () { HapticFeedback.selectionClick(); controller.setThemeMode(ThemeMode.system); },
                                    ),
                                    _ModeCircleItem(
                                      label: l10n.get('theme_mode_day'),
                                      isSelected: controller.themeMode == ThemeMode.light,
                                      isSplit: false,
                                      fillColorA: colorDay,
                                      fillColorB: colorDay,
                                      textColor: eonsv,
                                      selectionColor: ep,
                                      onTap: () { HapticFeedback.selectionClick(); controller.setThemeMode(ThemeMode.light); },
                                    ),
                                    _ModeCircleItem(
                                      label: l10n.get('theme_mode_night'),
                                      isSelected: controller.themeMode == ThemeMode.dark,
                                      isSplit: false,
                                      fillColorA: colorNight,
                                      fillColorB: colorNight,
                                      textColor: eonsv,
                                      selectionColor: ep,
                                      onTap: () { HapticFeedback.selectionClick(); controller.setThemeMode(ThemeMode.dark); },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // AMOLED (only when dark)
                        if (isDark) ...[
                          const SizedBox(height: 3),
                          _SectionCard(
                            shape: botShape,
                            esv: esv,
                            child: _SwitchRow(
                              title: l10n.get('theme_amoled_title'),
                              subtitle: l10n.get('theme_amoled_subtitle'),
                              value: controller.isAmoled,
                              onChanged: (val) { HapticFeedback.selectionClick(); controller.setAmoled(val); },
                              eonbg: eonbg,
                              eonsv: eonsv,
                              ep: ep,
                              esv: esv,
                            ),
                          ),
                        ],

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _themeLabel(AppTheme theme, AppLocalizations l10n) {
    switch (theme) {
      case AppTheme.system:   return l10n.get('theme_system');
      case AppTheme.standard: return l10n.get('theme_standard');
      case AppTheme.blue:     return l10n.get('theme_blue');
      case AppTheme.green:    return l10n.get('theme_green');
      case AppTheme.red:      return l10n.get('theme_red');
      case AppTheme.nothing:  return l10n.get('theme_nothing');
    }
  }
}

// --- Shared card container ---

class _SectionCard extends StatelessWidget {
  final BorderRadius shape;
  final Color esv;
  final Widget child;

  const _SectionCard({required this.shape, required this.esv, required this.child});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: esv,
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.0 : 0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

// --- Switch row (title + subtitle + switch) ---

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color eonbg, eonsv, ep, esv;

  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.eonbg,
    required this.eonsv,
    required this.ep,
    required this.esv,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: eonbg, fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(color: eonsv, fontSize: 13)),
                ],
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected) ? esv : eonsv),
            trackColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected) ? ep : eonbg.withOpacity(0.1)),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

// --- Color circle item ---

class _ColorCircleItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final Color textColor, selectionColor;
  final VoidCallback onTap;

  const _ColorCircleItem({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.textColor,
    required this.selectionColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isSelected)
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: isSelected ? BorderRadius.circular(24) : null,
                          shape: isSelected ? BoxShape.rectangle : BoxShape.circle,
                          border: Border.all(color: selectionColor, width: 3),
                        ),
                      ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: isSelected ? BorderRadius.circular(16) : null,
                        shape: isSelected ? BoxShape.rectangle : BoxShape.circle,
                        border: Border.all(color: Colors.black.withOpacity(isDark ? 0.0 : 0.1)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: textColor, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Mode circle item ---

class _ModeCircleItem extends StatelessWidget {
  final String label;
  final bool isSelected, isSplit;
  final Color fillColorA, fillColorB, textColor, selectionColor;
  final VoidCallback onTap;

  const _ModeCircleItem({
    required this.label,
    required this.isSelected,
    required this.isSplit,
    required this.fillColorA,
    required this.fillColorB,
    required this.textColor,
    required this.selectionColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isSelected)
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: isSelected ? BorderRadius.circular(24) : null,
                          shape: isSelected ? BoxShape.rectangle : BoxShape.circle,
                          border: Border.all(color: selectionColor, width: 3),
                        ),
                      ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: isSelected ? BorderRadius.circular(16) : null,
                        shape: isSelected ? BoxShape.rectangle : BoxShape.circle,
                        gradient: isSplit
                            ? LinearGradient(
                                colors: [fillColorA, fillColorA, fillColorB, fillColorB],
                                stops: const [0.0, 0.5, 0.5, 1.0],
                              )
                            : null,
                        color: isSplit ? null : fillColorA,
                        border: Border.all(color: Colors.black.withOpacity(isDark ? 0.0 : 0.1)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: textColor, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Preview card ---

class _ThemePreviewCard extends StatelessWidget {
  final Color accentColor, backgroundColor, surfaceColor, textColor;
  final String label;

  const _ThemePreviewCard({
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.0 : 0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 8, width: 120, decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 6),
                      Container(height: 8, width: 80, decoration: BoxDecoration(color: surfaceColor.withOpacity(0.6), borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                  Container(
                    height: 28,
                    decoration: BoxDecoration(color: accentColor.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    child: Container(height: 8, width: 60, decoration: BoxDecoration(color: accentColor.withOpacity(0.5), borderRadius: BorderRadius.circular(4))),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
