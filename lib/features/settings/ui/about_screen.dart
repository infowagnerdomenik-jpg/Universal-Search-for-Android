import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:design_engine/layer3_logic/design_engine_controller.dart';
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

import 'package:search/l10n/app_localizations.dart';
import 'package:search/features/search/logic/internet_service.dart';
import 'package:search/features/search/logic/file_service.dart';
import 'package:search/features/settings/logic/update_controller.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  // Status-Variablen für Updates
  String _searchAppStatus = '...';
  String _fileCompanionStatus = '...';
  String _internetCompanionStatus = '...';

  Color _searchAppStatusColor = Colors.grey;
  Color _fileCompanionStatusColor = Colors.grey;
  Color _internetCompanionStatusColor = Colors.grey;

  bool _isInternetCompanionInstalled = false;

  @override
  void initState() {
    super.initState();
    _checkAllUpdates();
  }

  Future<void> _checkAllUpdates() async {
    _isInternetCompanionInstalled = await InternetService.isCompanionInstalled();
    final l10n = AppLocalizations.of(context);

    if (!_isInternetCompanionInstalled) {
      if (mounted) {
        setState(() {
          _searchAppStatus = l10n.get('update_status_companion_missing');
          _searchAppStatusColor = Colors.orange;
          _fileCompanionStatus = l10n.get('update_status_companion_missing');
          _fileCompanionStatusColor = Colors.orange;
          _internetCompanionStatus = l10n.get('update_status_companion_missing');
          _internetCompanionStatusColor = Colors.orange;
        });
      }
      return;
    }

    // 1. Search App Check
    await _checkUpdate(
      repo: 'Universal-Search-for-Android',
      localVersion: UpdateController.mainVersion,
      onResult: (status, color) => setState(() {
        _searchAppStatus = status;
        _searchAppStatusColor = color;
      }),
    );

    // 2. File Companion Check
    final fileInstalled = await FileService.isCompanionInstalled();
    if (!fileInstalled) {
      if (mounted) {
        setState(() {
          _fileCompanionStatus = l10n.get('update_status_not_installed');
          _fileCompanionStatusColor = Colors.orange;
        });
      }
    } else {
      await _checkUpdate(
        repo: 'Search-Files-Companion',
        localVersion: UpdateController.fileVersion,
        onResult: (status, color) => setState(() {
          _fileCompanionStatus = status;
          _fileCompanionStatusColor = color;
        }),
      );
    }

    // 3. Internet Companion Check
    await _checkUpdate(
      repo: 'Search-Internet-Companion',
      localVersion: UpdateController.internetVersion,
      onResult: (status, color) => setState(() {
        _internetCompanionStatus = status;
        _internetCompanionStatusColor = color;
      }),
    );
  }

  Future<void> _checkUpdate({
    required String repo,
    required String localVersion,
    required Function(String, Color) onResult,
  }) async {
    final latest = await InternetService.fetchVersion(repo: repo);
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    
    if (latest == null) {
      onResult(l10n.get('update_status_up_to_date'), Colors.green);
      return;
    }

    final cleanLocal = _clean(localVersion);
    final cleanLatest = _clean(latest);

    if (_isHigher(cleanLatest, cleanLocal)) {
      onResult(l10n.get('update_status_available'), Colors.blue);
    } else {
      onResult(l10n.get('update_status_up_to_date'), Colors.green);
    }
  }

  String _clean(String v) => v.toLowerCase().replaceAll('alpha', '').replaceAll('(no github)', '').replaceAll('github', '').trim();

  bool _isHigher(String remote, String local) {
    try {
      List<int> r = remote.split('.').map((e) => int.parse(e.replaceAll(RegExp(r'[^0-9]'), ''))).toList();
      List<int> l = local.split('.').map((e) => int.parse(e.replaceAll(RegExp(r'[^0-9]'), ''))).toList();
      for (int i = 0; i < r.length && i < l.length; i++) {
        if (r[i] > l[i]) return true;
        if (r[i] < l[i]) return false;
      }
      return r.length > l.length;
    } catch (e) { return remote != local; }
  }

  void _showUpdateInfoDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.esurfacevariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.get('update_info_title'), style: TextStyle(color: context.eonbackground)),
        content: Text(
          l10n.get('update_info_text'),
          style: TextStyle(color: context.eonbackground.withOpacity(0.8), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('btn_ok'), style: TextStyle(color: context.eprimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final designController = Provider.of<DesignEngineController>(context);
    final bool isDark = designController.isEffectiveDark(context);
    final l10n = AppLocalizations.of(context);

    final Color ebg   = context.ebackground;
    final Color esv   = context.esurfacevariant;
    final Color eonbg = context.eonbackground;
    final Color eonsv = context.eonsurfacevariant;

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
                        UpdateController.mainVersion,
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
                    Row(
                      children: [
                        Expanded(child: _buildSectionHeader(l10n.get('updates_title'), eonbg)),
                        if (!_isInternetCompanionInstalled)
                          Padding(
                            padding: const EdgeInsets.only(right: 16, bottom: 8),
                            child: InkWell(
                              onTap: _showUpdateInfoDialog,
                              borderRadius: BorderRadius.circular(12),
                              child: Icon(Icons.info_outline, size: 18, color: eonbg.withOpacity(0.4)),
                            ),
                          ),
                      ],
                    ),
                    _buildSectionCard(
                      shape: singleShape,
                      esv: esv,
                      isDark: isDark,
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.update,
                            title: l10n.get('update_search_app'),
                            subtitle: _searchAppStatus,
                            eonbg: eonbg,
                            eonsv: _searchAppStatusColor,
                            onTap: () => launchUrl(Uri.parse('https://github.com/infowagnerdomenik-jpg/Universal-Search-for-Android/releases/'), mode: LaunchMode.externalApplication),
                          ),
                          Divider(height: 1, color: eonbg.withOpacity(0.05), indent: 60),
                          _buildInfoRow(
                            icon: Icons.folder_outlined,
                            title: l10n.get('update_file_companion'),
                            subtitle: _fileCompanionStatus,
                            eonbg: eonbg,
                            eonsv: _fileCompanionStatusColor,
                            onTap: () => launchUrl(Uri.parse('https://github.com/infowagnerdomenik-jpg/Search-Files-Companion/releases'), mode: LaunchMode.externalApplication),
                          ),
                          Divider(height: 1, color: eonbg.withOpacity(0.05), indent: 60),
                          _buildInfoRow(
                            icon: Icons.public,
                            title: l10n.get('update_internet_companion'),
                            subtitle: _internetCompanionStatus,
                            eonbg: eonbg,
                            eonsv: _internetCompanionStatusColor,
                            onTap: () => launchUrl(Uri.parse('https://github.com/infowagnerdomenik-jpg/Search-Internet-Companion/releases'), mode: LaunchMode.externalApplication),
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
                            url: 'https://github.com/infowagnerdomenik-jpg/Universal-Search-for-Android',
                            isDark: isDark,
                            eonbg: eonbg,
                            eonsv: eonsv,
                          ),
                          Divider(height: 1, color: eonbg.withOpacity(0.05), indent: 60),
                          _buildGitHubRow(
                            title: l10n.get('about_github_file_companion'),
                            subtitle: l10n.get('about_github_sub'),
                            url: 'https://github.com/infowagnerdomenik-jpg/Search-Files-Companion',
                            isDark: isDark,
                            eonbg: eonbg,
                            eonsv: eonsv,
                          ),
                          Divider(height: 1, color: eonbg.withOpacity(0.05), indent: 60),
                          _buildGitHubRow(
                            title: l10n.get('about_github_internet_companion'),
                            subtitle: l10n.get('about_github_sub'),
                            url: 'https://github.com/infowagnerdomenik-jpg/Search-Internet-Companion',
                            isDark: isDark,
                            eonbg: eonbg,
                            eonsv: eonsv,
                          ),
                          Divider(height: 1, color: eonbg.withOpacity(0.05), indent: 60),
                          _buildGitHubRow(
                            title: l10n.get('about_github_design_engine'),
                            subtitle: l10n.get('about_github_sub'),
                            url: 'https://github.com/infowagnerdomenik-jpg/Design-Engine-Plug-In-for-the-search-app',
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
                                applicationVersion: UpdateController.mainVersion,
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
    required String url,
    required bool isDark,
    required Color eonbg,
    required Color eonsv,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final Uri uri = Uri.parse(url);
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            debugPrint("Fehler beim Öffnen von GitHub: $e");
          }
        },
        child: Padding(
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
              Icon(Icons.chevron_right, color: eonbg.withOpacity(0.3)),
            ],
          ),
        ),
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
