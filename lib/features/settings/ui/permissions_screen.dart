import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// --- NEUE DESIGN ENGINE IMPORTE ---
import 'package:design_engine/layer3_logic/design_engine_controller.dart';
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

import 'package:search/features/search/logic/file_service.dart';
import 'package:search/features/search/logic/internet_service.dart';
import 'package:search/features/search/logic/app_cache.dart';
import 'package:search/features/search/logic/contact_cache.dart';
import 'package:search/features/calendar/logic/calendar_cache.dart';
import 'package:search/features/search/logic/file_cache.dart';
import 'package:search/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  static const _calendarChannel = MethodChannel('de.search.dw.search/calendar');
  static const _permissionChannel = MethodChannel('de.search.dw.search/permissions');
  static const _qsTileChannel = MethodChannel('de.search.dw.search/qstile');

  static const String _filePermissionName = "de.search.companion.dw.READ_FILES";
  static const String _internetPermissionName = "de.search.companion.internet.dw.INTERNET_ACCESS";

  bool _isFileAccessEnabled = false;
  bool _isInternetAccessEnabled = false;
  bool _isCalendarEnabled = false;
  bool _isContactsEnabled = false;
  bool _isAppSearchEnabled = true;
  bool _isQsTileAdded = false;

  bool _isFileCompanionInstalled = false;
  bool _isInternetCompanionInstalled = false;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    bool fileStatus = false;
    bool internetStatus = false;
    try {
      fileStatus = await _permissionChannel.invokeMethod('checkPermission', {'permission': _filePermissionName}) ?? false;
      internetStatus = await _permissionChannel.invokeMethod('checkPermission', {'permission': _internetPermissionName}) ?? false;
    } catch (_) {}
    
    bool calendarStatus = false;
    try {
      calendarStatus = await _calendarChannel.invokeMethod('checkPermission') ?? false;
    } catch (_) {
      calendarStatus = await Permission.calendar.isGranted;
    }
    
    final contactsStatus = await Permission.contacts.isGranted;
    final appSearchEnabled = await AppCache.isEnabled();
    
    final fileInstalled = await FileService.isCompanionInstalled();
    final internetInstalled = await InternetService.isCompanionInstalled();

    bool qsTileAdded = false;
    try {
      qsTileAdded = await _qsTileChannel.invokeMethod('checkQsTileAdded') ?? false;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isFileAccessEnabled = fileStatus;
        _isInternetAccessEnabled = internetStatus;
        _isCalendarEnabled = calendarStatus;
        _isContactsEnabled = contactsStatus;
        _isAppSearchEnabled = appSearchEnabled;
        _isFileCompanionInstalled = fileInstalled;
        _isInternetCompanionInstalled = internetInstalled;
        _isQsTileAdded = qsTileAdded;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFileAccess(bool value) async {
    if (value) {
      if (!_isFileCompanionInstalled) {
        _showMissingCompanionDialog(AppLocalizations.of(context).get('perm_file_title'));
        return;
      }
      final bool? success = await _permissionChannel.invokeMethod('requestPermission', {'permission': _filePermissionName});
      if (success == true) await FileCache.init();
      setState(() => _isFileAccessEnabled = success ?? false);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('enable_companion_access', success ?? false);
    } else {
      openAppSettings();
    }
  }

  Future<void> _toggleInternetAccess(bool value) async {
    if (value) {
      if (!_isInternetCompanionInstalled) {
        _showMissingCompanionDialog(AppLocalizations.of(context).get('perm_internet_title'));
        return;
      }
      final bool? success = await _permissionChannel.invokeMethod('requestPermission', {'permission': _internetPermissionName});
      setState(() => _isInternetAccessEnabled = success ?? false);
      await InternetService.setEnabled(success ?? false);
    } else {
      openAppSettings();
    }
  }

  Future<void> _toggleCalendar(bool value) async {
    if (value) {
      try {
        final bool? success = await _calendarChannel.invokeMethod('requestPermission');
        if (success == true) await CalendarCache.refresh();
        setState(() => _isCalendarEnabled = success ?? false);
      } catch (e) {
        final status = await Permission.calendar.request();
        if (status.isGranted) await CalendarCache.refresh();
        setState(() => _isCalendarEnabled = status.isGranted);
      }
    } else {
      openAppSettings();
    }
  }

  Future<void> _toggleContacts(bool value) async {
    if (value) {
      final status = await Permission.contacts.request();
      if (status.isGranted) await ContactCache.init();
      setState(() => _isContactsEnabled = status.isGranted);
    } else {
      openAppSettings();
    }
  }

  Future<void> _toggleAppSearch(bool value) async {
    await AppCache.setEnabled(value);
    setState(() => _isAppSearchEnabled = value);
  }

  Future<void> _requestAddQsTile() async {
    try {
      final int? resultCode = await _qsTileChannel.invokeMethod('requestAddQsTile');
      // 1 = TILE_ADDED, 2 = TILE_ALREADY_ADDED
      if (resultCode == 1 || resultCode == 2) {
        setState(() => _isQsTileAdded = true);
      }
    } catch (_) {}
  }

  void _showMissingCompanionDialog(String name) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.esurfacevariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.get('companion_missing_title').replaceAll('{name}', name), style: TextStyle(color: context.eonbackground)),
        content: Text(
          l10n.get('companion_missing_text').replaceAll('{name}', name),
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

  void _showInfoDialog(BuildContext context, String titleKey, String textKey) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.esurfacevariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.get(titleKey), style: TextStyle(color: context.eonbackground)),
        content: Text(
          l10n.get(textKey),
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

  Widget _buildSectionHeader(BuildContext context, String titleKey) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 16, right: 8),
      child: Text(
        l10n.get(titleKey).toUpperCase(),
        style: TextStyle(
          color: context.eonbackground.withOpacity(0.6),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildPermissionCardRow({
    required String titleKey,
    required String subtitleKey,
    required IconData icon,
    required bool isEnabled,
    required bool isInstalled,
    required Function(bool)? onChanged,
    required BorderRadius shape,
    Future<void> Function()? onClearCache,
    String? clearCacheLabelKey,
    String? clearCacheInfoKey,
    String? infoTitleKey,
    String? infoTextKey,
    required BuildContext context,
  }) {
    final l10n = AppLocalizations.of(context);
    final Color esv = context.esurfacevariant;
    final Color eonbg = context.eonbackground;
    final Color ep = context.eprimary;
    final Color eonp = context.eonprimary;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final String title = l10n.get(titleKey);

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppFallbackIcon(icon: icon, size: 40, iconSize: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: eonbg,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (infoTitleKey != null && infoTextKey != null) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _showInfoDialog(context, infoTitleKey, infoTextKey),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(Icons.info_outline, size: 18, color: eonbg.withOpacity(0.4)),
                              ),
                            ),
                          ]
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.get(subtitleKey),
                        style: TextStyle(
                          color: eonbg.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: onChanged != null ? (val) { HapticFeedback.selectionClick(); onChanged(val); } : null,
                  thumbColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected) ? esv : eonbg.withOpacity(0.4)),
                  trackColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected) ? ep : eonbg.withOpacity(0.1)),
                  trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                ),
              ],
            ),
            
            if (onClearCache != null && isEnabled) ...[
              const SizedBox(height: 16),
              Divider(color: eonbg.withOpacity(0.05), height: 1),
              const SizedBox(height: 12),
              Text(
                l10n.get(clearCacheInfoKey ?? ""),
                style: TextStyle(color: eonbg.withOpacity(0.5), fontSize: 12),
              ),
              const SizedBox(height: 12),
              Material(
                color: ep.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: esv,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        title: Text(l10n.get('cache_clear_title'), style: TextStyle(color: eonbg)),
                        content: Text(l10n.get('cache_clear_confirm').replaceAll('{title}', title), style: TextStyle(color: eonbg.withOpacity(0.7))),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.get('cache_clear_cancel'), style: TextStyle(color: eonbg.withOpacity(0.5)))),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.get('cache_clear_delete'), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await onClearCache();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.get('cache_clear_success').replaceAll('{title}', title), style: TextStyle(color: eonp)),
                            backgroundColor: ep,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_sweep_outlined, size: 16, color: ep),
                        const SizedBox(width: 8),
                        Text(
                          l10n.get(clearCacheLabelKey ?? ""),
                          style: TextStyle(color: ep, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            if (!isInstalled)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.get('companion_missing_banner'),
                                style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: ep.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          // TODO: Implement actual download link
                          HapticFeedback.lightImpact();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.download_rounded, size: 16, color: ep),
                              const SizedBox(width: 6),
                              Text(
                                l10n.get('btn_download'),
                                style: TextStyle(color: ep, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (titleKey == 'perm_file_title' || titleKey == 'perm_internet_title')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.get('companion_installed_banner'),
                          style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticInfoCard({
    required String titleKey,
    required String subtitleKey,
    required IconData icon,
    required BorderRadius shape,
    String? infoTitleKey,
    String? infoTextKey,
    bool? isAdded,
    VoidCallback? onTap,
    required BuildContext context,
  }) {
    final l10n = AppLocalizations.of(context);
    final Color esv = context.esurfacevariant;
    final Color eonbg = context.eonbackground;
    final Color ep = context.eprimary;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final bool tappable = onTap != null && isAdded == false;

    Widget trailing;
    if (isAdded == null) {
      trailing = const SizedBox.shrink();
    } else if (isAdded) {
      trailing = Icon(Icons.check_circle_rounded, color: ep, size: 22);
    } else {
      trailing = Icon(Icons.add_circle_outline_rounded, color: ep, size: 22);
    }

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppFallbackIcon(icon: icon, size: 40, iconSize: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          l10n.get(titleKey),
                          style: TextStyle(
                            color: eonbg,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (infoTitleKey != null && infoTextKey != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showInfoDialog(context, infoTitleKey, infoTextKey),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(Icons.info_outline, size: 18, color: eonbg.withOpacity(0.4)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.get(subtitleKey),
                    style: TextStyle(color: eonbg.withOpacity(0.6), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          trailing,
        ],
      ),
    );

    return Container(
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
      child: tappable
          ? Material(
              color: Colors.transparent,
              borderRadius: shape,
              child: InkWell(
                borderRadius: shape,
                onTap: onTap,
                child: content,
              ),
            )
          : content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final designController = Provider.of<DesignEngineController>(context);
    final bool isDark = designController.isEffectiveDark(context);

    final Color ebg = context.ebackground;     
    final Color eonbg = context.eonbackground; 

    const topShape = BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4));
    const botShape = BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4), bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28));
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
          icon: Icon(Icons.arrow_back, color: eonbg),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.get('permissions_title'), style: TextStyle(color: eonbg, fontWeight: FontWeight.w600)),
        actions: <Widget>[
          IconButton(
            onPressed: () => openAppSettings(),
            icon: Icon(Icons.info_outline, color: eonbg.withOpacity(0.7)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  children: <Widget>[
                    _buildSectionHeader(context, 'permissions_companion_header'),
                    _buildPermissionCardRow(
                      titleKey: 'perm_file_title',
                      subtitleKey: 'perm_file_subtitle',
                      icon: Icons.folder_shared,
                      isEnabled: _isFileAccessEnabled,
                      isInstalled: _isFileCompanionInstalled,
                      onChanged: _toggleFileAccess,
                      shape: topShape,
                      onClearCache: () async {
                        await FileCache.clear();
                      },
                      clearCacheLabelKey: 'cache_file_label',
                      clearCacheInfoKey: 'cache_file_info',
                      context: context,
                    ),
                    const SizedBox(height: 3),
                    _buildPermissionCardRow(
                      titleKey: 'perm_internet_title',
                      subtitleKey: 'perm_internet_subtitle',
                      icon: Icons.public,
                      isEnabled: _isInternetAccessEnabled,
                      isInstalled: _isInternetCompanionInstalled,
                      onChanged: _toggleInternetAccess,
                      shape: botShape,
                      context: context,
                    ),
                    
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'permissions_system_header'),
                    _buildPermissionCardRow(
                      titleKey: 'calendar_title',
                      subtitleKey: 'perm_calendar_subtitle',
                      icon: Icons.calendar_today,
                      isEnabled: _isCalendarEnabled,
                      isInstalled: true,
                      onChanged: _toggleCalendar,
                      shape: topShape,
                      onClearCache: () async {
                        await CalendarCache.clear();
                        await CalendarCache.refresh();
                      },
                      clearCacheLabelKey: 'cache_calendar_label',
                      clearCacheInfoKey: 'cache_calendar_info',
                      context: context,
                    ),
                    const SizedBox(height: 3),
                    _buildPermissionCardRow(
                      titleKey: 'contacts_title',
                      subtitleKey: 'perm_contacts_subtitle',
                      icon: Icons.contacts,
                      isEnabled: _isContactsEnabled,
                      isInstalled: true,
                      onChanged: _toggleContacts,
                      shape: botShape,
                      onClearCache: () async {
                        await ContactCache.clear();
                        await ContactCache.refresh();
                      },
                      clearCacheLabelKey: 'cache_contact_label',
                      clearCacheInfoKey: 'cache_contact_info',
                      context: context,
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'permissions_privacy_header'),
                    _buildPermissionCardRow(
                      titleKey: 'perm_apps_title',
                      subtitleKey: 'perm_apps_subtitle',
                      icon: Icons.apps,
                      isEnabled: _isAppSearchEnabled,
                      isInstalled: true,
                      onChanged: _toggleAppSearch,
                      shape: topShape,
                      onClearCache: () async {
                        await AppCache.clear();
                        await AppCache.refresh();
                      },
                      clearCacheLabelKey: 'cache_app_label',
                      clearCacheInfoKey: 'cache_app_info',
                      infoTitleKey: 'info_perm_apps_title',
                      infoTextKey: 'info_perm_apps_text',
                      context: context,
                    ),
                    const SizedBox(height: 3),
                    _buildStaticInfoCard(
                      titleKey: 'perm_qs_tile_title',
                      subtitleKey: 'perm_qs_tile_subtitle',
                      icon: Icons.grid_view_rounded,
                      shape: botShape,
                      infoTitleKey: 'info_qs_tile_title',
                      infoTextKey: 'info_qs_tile_text',
                      isAdded: _isQsTileAdded,
                      onTap: _requestAddQsTile,
                      context: context,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
