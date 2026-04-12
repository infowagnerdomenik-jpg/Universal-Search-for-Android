import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:design_engine/layer3_logic/design_engine_controller.dart';
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

import 'package:search/l10n/app_localizations.dart';
import 'package:search/l10n/language_controller.dart';

// Human-validated languages (no AI badge)
const _humanValidated = {'en', 'de'};

// Display name for each language code (in the native language)
const _languageNames = {
  'auto': '',
  'en': 'English',
  'de': 'Deutsch',
  'es': 'Español',
  'fr': 'Français',
  'it': 'Italiano',
  'pt': 'Português',
  'nl': 'Nederlands',
  'pl': 'Polski',
  'ru': 'Русский',
  'ja': '日本語',
  'zh': '中文',
  'ko': '한국어',
  'ar': 'العربية',
  'tr': 'Türkçe',
  'hi': 'हिन्दी',
  'sv': 'Svenska',
  'da': 'Dansk',
  'fi': 'Suomi',
  'cs': 'Čeština',
  'uk': 'Українська',
};

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final designController = Provider.of<DesignEngineController>(context);
    final langController = context.watch<LanguageController>();
    final l10n = AppLocalizations.of(context);
    final bool isDark = designController.isEffectiveDark(context);

    final Color ebg = context.ebackground;
    final Color esv = context.esurfacevariant;
    final Color eonbg = context.eonbackground;
    final Color eonsv = context.eonsurfacevariant;
    final Color eprimary = context.eprimary;

    const topShape = BorderRadius.only(
      topLeft: Radius.circular(28),
      topRight: Radius.circular(28),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(4),
    );
    const midShape = BorderRadius.all(Radius.circular(4));
    const botShape = BorderRadius.only(
      topLeft: Radius.circular(4),
      topRight: Radius.circular(4),
      bottomLeft: Radius.circular(28),
      bottomRight: Radius.circular(28),
    );
    const singleShape = BorderRadius.all(Radius.circular(28));

    final options = ['auto', ...AppLocalizations.supportedLanguageCodes];
    final current = langController.language;

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
        iconTheme: IconThemeData(color: eonbg),
        title: Text(
          l10n.get('language_screen_title'),
          style: TextStyle(color: eonbg, fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: [
              for (int i = 0; i < options.length; i++)
                _buildLanguageOption(
                  context: context,
                  code: options[i],
                  isSelected: current == options[i],
                  isDark: isDark,
                  esv: esv,
                  eonbg: eonbg,
                  eonsv: eonsv,
                  eprimary: eprimary,
                  l10n: l10n,
                  shape: options.length == 1
                      ? singleShape
                      : i == 0
                          ? topShape
                          : i == options.length - 1
                              ? botShape
                              : midShape,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    langController.setLanguage(options[i]);
                  },
                  spacer: i < options.length - 1
                      ? const SizedBox(height: 3)
                      : const SizedBox.shrink(),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String code,
    required bool isSelected,
    required bool isDark,
    required Color esv,
    required Color eonbg,
    required Color eonsv,
    required Color eprimary,
    required AppLocalizations l10n,
    required BorderRadius shape,
    required VoidCallback onTap,
    required Widget spacer,
  }) {
    final bool isAuto = code == 'auto';
    final bool isAI = !isAuto && !_humanValidated.contains(code);
    final String displayName = isAuto
        ? l10n.get('language_auto')
        : _languageNames[code] ?? code.toUpperCase();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isSelected ? eprimary.withOpacity(0.15) : esv,
            borderRadius: shape,
            border: isSelected
                ? Border.all(color: eprimary.withOpacity(0.5), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.0 : 0.06),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: shape,
              onTap: onTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isAuto ? l10n.get('language_auto') : displayName,
                                style: TextStyle(
                                  color: eonbg,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                              if (isAI) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: eprimary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: eprimary.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    l10n.get('language_ai_badge'),
                                    style: TextStyle(
                                      color: eprimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (!isAuto) ...[
                            const SizedBox(height: 2),
                            Text(
                              code.toUpperCase(),
                              style: TextStyle(
                                color: eonbg.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: eprimary, size: 22)
                    else
                      Icon(Icons.circle_outlined,
                          color: eonbg.withOpacity(0.25), size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),
        spacer,
      ],
    );
  }
}
