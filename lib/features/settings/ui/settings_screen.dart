import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// --- NEUE DESIGN ENGINE IMPORTE ---
import 'package:design_engine/layer3_logic/design_engine_controller.dart';
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

// --- FEATURE IMPORTE ---
import 'package:search/features/settings/ui/theme_settings_screen.dart';
import 'package:search/features/settings/ui/search_settings_ui.dart';
import 'package:search/features/settings/ui/home_settings_screen.dart';
import 'package:search/features/settings/ui/permissions_screen.dart';
import 'package:search/features/settings/ui/about_screen.dart';
import 'package:search/features/settings/ui/language_settings_screen.dart';

// --- LOCALIZATION ---
import 'package:search/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const platform = MethodChannel('de.search.dw.search/widget');

  Future<void> _openWidgetSettings() async {
    try {
      await platform.invokeMethod('openWidgetSettings');
    } on PlatformException catch (e) {
      debugPrint("Fehler beim Öffnen der Widget-Settings: '\${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<DesignEngineController>(context);
    final bool isDark = controller.isEffectiveDark(context);

    // --- DESIGN ENGINE FARBEN ---
    final Color ebg = context.ebackground;     
    final Color esv = context.esurfacevariant; 
    final Color eonbg = context.eonbackground; 

    const topShape = BorderRadius.only(
      topLeft: Radius.circular(28), topRight: Radius.circular(28),
      bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4),
    );
    const midShape = BorderRadius.all(Radius.circular(4));
    const botShape = BorderRadius.only(
      topLeft: Radius.circular(4), topRight: Radius.circular(4),
      bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28),
    );
    const singleShape = BorderRadius.all(Radius.circular(28));

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
          AppLocalizations.of(context).get('settings_title'),
          style: TextStyle(color: eonbg, fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: [
              // --- All Settings as a single stacked block ---
              _buildSettingsCard(
                context: context,
                esv: esv,
                eonbg: eonbg,
                icon: Icons.palette_outlined,
                titleKey: 'design_title',
                subtitleKey: 'design_sub',
                shape: topShape,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ThemeSettingsScreen()));
                },
              ),
              const SizedBox(height: 3),
              _buildSettingsCard(
                context: context,
                esv: esv,
                eonbg: eonbg,
                icon: Icons.home_outlined,
                titleKey: 'home_settings_title',
                subtitleKey: 'home_settings_sub',
                shape: midShape,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeSettingsScreen()));
                },
              ),
              const SizedBox(height: 3),
              _buildSettingsCard(
                context: context,
                esv: esv,
                eonbg: eonbg,
                icon: Icons.manage_search,
                titleKey: 'search_title',
                subtitleKey: 'search_sub',
                shape: midShape,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchSettingsUI()));
                },
              ),
              const SizedBox(height: 3),
              _buildSettingsCard(
                context: context,
                esv: esv,
                eonbg: eonbg,
                icon: Icons.extension_outlined,
                titleKey: 'external_access_title',
                subtitleKey: 'external_access_sub',
                shape: Theme.of(context).platform == TargetPlatform.android ? midShape : botShape,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PermissionsScreen()));
                },
              ),
              
              if (Theme.of(context).platform == TargetPlatform.android) ...[
                const SizedBox(height: 3),
                _buildSettingsCard(
                  context: context,
                  esv: esv,
                  eonbg: eonbg,
                  icon: Icons.widgets_outlined,
                  titleKey: 'widget_title',
                  subtitleKey: 'widget_sub',
                  shape: midShape,
                  onTap: _openWidgetSettings,
                ),
                const SizedBox(height: 3),
                _buildSettingsCard(
                  context: context,
                  esv: esv,
                  eonbg: eonbg,
                  icon: Icons.language_outlined,
                  titleKey: 'language_title',
                  subtitleKey: 'language_sub',
                  shape: midShape,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageSettingsScreen()));
                  },
                ),
                const SizedBox(height: 3),
                _buildSettingsCard(
                  context: context,
                  esv: esv,
                  eonbg: eonbg,
                  icon: Icons.info_outline,
                  titleKey: 'about_title',
                  shape: botShape,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                  },
                ),
              ] else ...[
                const SizedBox(height: 3),
                _buildSettingsCard(
                  context: context,
                  esv: esv,
                  eonbg: eonbg,
                  icon: Icons.language_outlined,
                  titleKey: 'language_title',
                  subtitleKey: 'language_sub',
                  shape: midShape,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageSettingsScreen()));
                  },
                ),
                const SizedBox(height: 3),
                _buildSettingsCard(
                  context: context,
                  esv: esv,
                  eonbg: eonbg,
                  icon: Icons.info_outline,
                  titleKey: 'about_title',
                  shape: botShape,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                  },
                ),
              ],
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required BuildContext context,
    required Color esv,
    required Color eonbg,
    required IconData icon,
    required String titleKey,
    String? subtitleKey,
    required BorderRadius shape,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: esv,
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.0 : 0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                AppFallbackIcon(icon: icon, size: 36, iconSize: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).get(titleKey),
                        style: TextStyle(color: eonbg, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      if (subtitleKey != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context).get(subtitleKey),
                          style: TextStyle(color: eonbg.withOpacity(0.7), fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: eonbg.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
