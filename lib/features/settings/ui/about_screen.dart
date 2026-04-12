import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:design_engine/layer3_logic/design_engine_controller.dart';
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

import 'package:search/l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final designController = Provider.of<DesignEngineController>(context);
    final bool isDark = designController.isEffectiveDark(context);
    final l10n = AppLocalizations.of(context);

    final Color ebg   = context.ebackground;
    final Color esv   = context.esurfacevariant;
    final Color eonbg = context.eonbackground;
    final Color eonsv = context.eonsurfacevariant;

    const String appVersion = 'Alpha 1.0.0 (No Github)';
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
        iconTheme: IconThemeData(color: eonbg),
        title: Text(
          l10n.get('about_title'),
          style: TextStyle(color: eonbg, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        primary: true,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- App Logo & Header ---
                    const SizedBox(height: 20),
                    Center(
                      child: SvgPicture.asset(
                        'assets/icons/original/Search_App_Icon.svg',
                        width: 100,
                        height: 100,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        l10n.get('app_name_title'),
                        style: TextStyle(
                          color: eonbg,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        appVersion,
                        style: TextStyle(
                          color: eonsv,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Description Card ---
                    _buildSectionCard(
                      shape: singleShape,
                      esv: esv,
                      isDark: isDark,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          l10n.get('about_description'),
                          style: TextStyle(color: eonbg, fontSize: 15, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- Updates Section ---
                    _buildSectionHeader(l10n.get('updates_title'), eonbg),
                    _buildSectionCard(
                      shape: singleShape,
                      esv: esv,
                      isDark: isDark,
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.update,
                            title: l10n.get('update_search_app'),
                            subtitle: l10n.get('update_status_up_to_date'),
                            eonbg: eonbg,
                            eonsv: Colors.green,
                          ),
                          Divider(height: 1, color: eonbg.withOpacity(0.05), indent: 60),
                          _buildInfoRow(
                            icon: Icons.folder_outlined,
                            title: l10n.get('update_file_companion'),
                            subtitle: l10n.get('update_status_up_to_date'),
                            eonbg: eonbg,
                            eonsv: Colors.green,
                          ),
                          Divider(height: 1, color: eonbg.withOpacity(0.05), indent: 60),
                          _buildInfoRow(
                            icon: Icons.public,
                            title: l10n.get('update_internet_companion'),
                            subtitle: l10n.get('update_status_up_to_date'),
                            eonbg: eonbg,
                            eonsv: Colors.green,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- GitHub Section ---
                    _buildSectionHeader(l10n.get('about_github_title'), eonbg),
                    _buildSectionCard(
                      shape: singleShape,
                      esv: esv,
                      isDark: isDark,
                      child: Column(
                        children: [
                          _buildGitHubRow(
                            title: '${l10n.get('about_github_title')}: ${l10n.get('app_name_title')}',
                            subtitle: l10n.get('about_github_sub'),
                            isDark: isDark,
                            eonbg: eonbg,
                            eonsv: eonsv,
                          ),
                          Divider(height: 1, color: eonbg.withOpacity(0.05), indent: 60),
                          _buildGitHubRow(
                            title: l10n.get('about_github_file_companion'),
                            subtitle: l10n.get('about_github_sub'),
                            isDark: isDark,
                            eonbg: eonbg,
                            eonsv: eonsv,
                          ),
                          Divider(height: 1, color: eonbg.withOpacity(0.05), indent: 60),
                          _buildGitHubRow(
                            title: l10n.get('about_github_internet_companion'),
                            subtitle: l10n.get('about_github_sub'),
                            isDark: isDark,
                            eonbg: eonbg,
                            eonsv: eonsv,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- Developer & License ---
                    _buildSectionHeader(l10n.get('about_developer_title'), eonbg),
                    _buildSectionCard(
                      shape: singleShape,
                      esv: esv,
                      isDark: isDark,
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.person_outline,
                            title: l10n.get('about_developer_name'),
                            eonbg: eonbg,
                            eonsv: eonsv,
                          ),
                          Divider(height: 1, color: eonbg.withOpacity(0.05), indent: 60),
                          _buildInfoRow(
                            icon: Icons.description_outlined,
                            title: l10n.get('about_license_title'),
                            subtitle: l10n.get('about_license_sub'),
                            eonbg: eonbg,
                            eonsv: eonsv,
                            onTap: () async {
                              final Uri url = Uri.parse('https://www.apache.org/licenses/LICENSE-2.0');
                              try {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              } catch (e) {
                                debugPrint("Fehler beim Öffnen der Lizenz: $e");
                              }
                            },
                          ),
                          Divider(height: 1, color: eonbg.withOpacity(0.05), indent: 60),
                          _buildInfoRow(
                            icon: Icons.library_books_outlined,
                            title: l10n.get('about_oss_libraries_title'),
                            subtitle: l10n.get('about_oss_libraries_sub'),
                            eonbg: eonbg,
                            eonsv: eonsv,
                            onTap: () {
                              showLicensePage(
                                context: context,
                                applicationName: l10n.get('app_name_title'),
                                applicationVersion: appVersion,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color.withOpacity(0.5),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BorderRadius shape,
    required Color esv,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: esv,
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.0 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: child,
      ),
    );
  }

  Widget _buildGitHubRow({
    required String title,
    required String subtitle,
    required bool isDark,
    required Color eonbg,
    required Color eonsv,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          SvgPicture.asset(
            isDark 
              ? 'assets/icons/dynamic/GitHub_Invertocat_White.svg'
              : 'assets/icons/dynamic/GitHub_Invertocat_Black.svg',
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: eonbg, fontWeight: FontWeight.w600, fontSize: 16),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: eonsv, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color eonbg,
    required Color eonsv,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: eonbg, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: eonbg, fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(color: eonsv, fontSize: 13),
                      ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: eonbg.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
