import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

// --- FEATURE IMPORTE ---
import 'package:search/features/search/logic/search_settings_controller.dart';
import 'package:search/features/search/data/search_engines.dart';
import 'package:search/features/calendar/logic/calendar_service.dart';
import 'package:search/features/calendar/logic/calendar_cache.dart';
import 'package:search/features/search/logic/file_service.dart';
import 'package:search/features/search/logic/internet_service.dart';
import 'package:search/features/settings/logic/home_layout_controller.dart';
import 'package:search/features/settings/ui/components/permission_locked_overlay.dart';

// --- NEUE DESIGN ENGINE IMPORTE ---
import 'package:design_engine/layer3_logic/design_engine_controller.dart';
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

// --- LOCALIZATION ---
import 'package:search/l10n/app_localizations.dart';

import 'package:search/features/search/ui/components/engine_switcher_sheet.dart';

import 'package:search/features/search/logic/quick_search_controller.dart';
import 'package:search/features/search/domain/models/quick_search_provider.dart';

class SearchSettingsUI extends StatefulWidget {
  const SearchSettingsUI({super.key});

  @override
  State<SearchSettingsUI> createState() => _SearchSettingsUIState();
}

class _SearchSettingsUIState extends State<SearchSettingsUI> {
  void _refresh() {
    if (mounted) setState(() {});
  }

  void showInfoDialog(BuildContext context, String titleKey, String textKey, {Widget? customContent}) {
    showDialog(
      context: context,
      builder: (context) {
        final Color esv = context.esurfacevariant;
        final Color eonbg = context.eonbackground;
        final Color ep = context.eprimary;
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          backgroundColor: esv,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(l10n.get(titleKey), style: TextStyle(color: eonbg, fontWeight: FontWeight.bold)),
          content: customContent ?? Text(l10n.get(textKey), style: TextStyle(color: eonbg.withOpacity(0.8), height: 1.4)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.get('btn_ok'), style: TextStyle(color: ep, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget buildSectionHeader(BuildContext context, String titleKey, {String? infoTitleKey, String? infoTextKey, Widget? customContent}) {
    final l10n = AppLocalizations.of(context);
    final Color eonbg = context.eonbackground;
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 16, right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.get(titleKey).toUpperCase(),
            style: TextStyle(color: eonbg.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0),
          ),
          if (infoTitleKey != null && infoTextKey != null)
            InkWell(
              onTap: () => showInfoDialog(context, infoTitleKey, infoTextKey, customContent: customContent),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.info_outline, size: 18, color: eonbg.withOpacity(0.4)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required BuildContext context, required BorderRadius shape, required Color esv, required Widget child}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: esv,
        borderRadius: shape,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.0 : 0.08), blurRadius: 3, offset: const Offset(0, 1)),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchController = SearchSettingsController(); 
    final designController = Provider.of<DesignEngineController>(context);
    final bool isDark = designController.isEffectiveDark(context);

    const topShape = BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4));
    const botShape = BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4), bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28));
    const singleShape = BorderRadius.all(Radius.circular(28));

    BorderRadius shapeForIndex(int index, int total) {
      if (total == 1) return singleShape;
      if (index == 0) return topShape;
      if (index == total - 1) return botShape;
      return const BorderRadius.all(Radius.circular(4));
    }

    void showEngineSwitcher(BuildContext context) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => const EngineSwitcherSheet(),
      );
    }

    void showCalendarSelector(BuildContext context) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          final Color esv = context.esurfacevariant;
          final Color eonbg = context.eonbackground;
          final Color ep = context.eprimary;

          return Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
                child: const SizedBox.expand(),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxWidth: 700, maxHeight: MediaQuery.of(context).size.height * 0.85),
                  decoration: BoxDecoration(color: esv, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
                  child: SafeArea(
                    bottom: true, top: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: eonbg.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context).get('calendar_selection_label'), style: TextStyle(color: eonbg, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              ValueListenableBuilder<bool>(
                                valueListenable: CalendarCache.loadingNotifier,
                                builder: (context, isLoading, child) {
                                  if (isLoading) return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()));
                                  return ValueListenableBuilder<List<NativeCalendar>>(
                                    valueListenable: CalendarCache.availableCalendarsNotifier,
                                    builder: (context, calendars, child) {
                                      if (calendars.isEmpty) return Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text(AppLocalizations.of(context).get('no_calendars_found'), style: TextStyle(color: eonbg.withOpacity(0.5))));
                                      final Map<String, List<NativeCalendar>> grouped = {};
                                      for (var cal in calendars) grouped.putIfAbsent(cal.account, () => []).add(cal);
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: grouped.entries.map((entry) {
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (entry.key.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
                                                  child: Text(entry.key.toUpperCase(), style: TextStyle(color: ep, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                                                ),
                                              ...entry.value.map((cal) {
                                                return ListenableBuilder(
                                                  listenable: searchController,
                                                  builder: (context, child) {
                                                    final isEnabled = searchController.enabledCalendarIds.contains(cal.id);
                                                    return CheckboxListTile(
                                                      title: Text(cal.name, style: TextStyle(color: eonbg, fontSize: 16, fontWeight: FontWeight.w500)),
                                                      value: isEnabled,
                                                      activeColor: ep,
                                                      contentPadding: EdgeInsets.zero,
                                                      onChanged: (_) => searchController.toggleCalendarId(cal.id),
                                                    );
                                                  },
                                                );
                                              }).toList(),
                                              const SizedBox(height: 4),
                                              Divider(color: eonbg.withOpacity(0.15), thickness: 1),
                                            ],
                                          );
                                        }).toList(),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
              ),
            ],
          );
        },
      );
    }

    void showPrivacySourceSelector(BuildContext context) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          final Color esv = context.esurfacevariant;
          final Color eonbg = context.eonbackground;
          final Color ep = context.eprimary;
          final l10n = AppLocalizations.of(context);
          return ListenableBuilder(
            listenable: searchController,
            builder: (context, child) {
              final selected = searchController.privacySource;
              Widget buildPopupItem({required String id, required String label, String? iconPath, required bool isSelected}) {
                return ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: iconPath != null ? SvgPicture.asset(iconPath, width: 24, height: 24) : Icon(Icons.block, color: eonbg.withOpacity(0.5), size: 24),
                  ),
                  title: Text(label, style: TextStyle(color: eonbg, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSelected ? Icon(Icons.check_circle, color: ep) : null,
                  onTap: () { searchController.setPrivacySource(id); Navigator.pop(context); },
                );
              }
              return Stack(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context),
                    child: const SizedBox.expand(),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 700),
                  decoration: BoxDecoration(color: esv, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: eonbg.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Text(l10n.get('privacy_selection_label'), style: TextStyle(color: eonbg, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        buildPopupItem(id: 'none', label: l10n.get('opt_none'), isSelected: selected == 'none'),
                        buildPopupItem(id: 'qwant', label: l10n.get('name_qwant'), iconPath: 'assets/icons/original/Qwant_new_logo_2018.svg', isSelected: selected == 'qwant'),
                        buildPopupItem(id: 'brave', label: l10n.get('opt_brave'), iconPath: 'assets/icons/original/brave_logo.svg', isSelected: selected == 'brave'),
                        buildPopupItem(id: 'google', label: l10n.get('opt_google'), iconPath: 'assets/icons/original/Google_Favicon_2025.svg', isSelected: selected == 'google'),
                        buildPopupItem(id: 'bing', label: l10n.get('opt_bing'), iconPath: 'assets/icons/original/Bing_Fluent_Logo.svg', isSelected: selected == 'bing'),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
          },
        );
        },
      );
    }

    void showQuickSearchSelector(BuildContext context) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          final Color esv = context.esurfacevariant;
          final Color eonsv = context.eonsurfacevariant;
          final Color ebg = context.ebackground;
          final Color ep = context.eprimary;
          final Color eonbg = context.eonbackground;
          final Color ebgInverse = context.ebackground;
          final l10n = AppLocalizations.of(context);
          return Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
                child: const SizedBox.expand(),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
              constraints: BoxConstraints(maxWidth: 700, maxHeight: MediaQuery.of(context).size.height * 0.85),
              decoration: BoxDecoration(color: esv, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: eonbg.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(l10n.get('quick_search_header'), style: TextStyle(color: eonbg, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Flexible(
                      child: ListenableBuilder(
                        listenable: QuickSearchController(),
                        builder: (context, child) {
                          final controller = QuickSearchController();
                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SwitchListTile(
                                  title: Text(l10n.get('quick_search_open_in_app_label'), style: TextStyle(color: eonbg, fontWeight: FontWeight.bold, fontSize: 15)),
                                  subtitle: Text(l10n.get('quick_search_open_in_app_info'), style: TextStyle(color: eonbg.withOpacity(0.6), fontSize: 12)),
                                  value: controller.openInApp,
                                  thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? esv : eonsv),
                                  trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? ep : eonbg.withOpacity(0.1)),
                                  trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (val) { HapticFeedback.selectionClick(); controller.setOpenInApp(val); },
                                ),
                                const Divider(),
                                Theme(
                                  data: Theme.of(context).copyWith(canvasColor: Colors.transparent, shadowColor: Colors.transparent),
                                  child: ReorderableListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    buildDefaultDragHandles: false,
                                    itemCount: controller.providerOrder.length,
                                    onReorder: (oldIndex, newIndex) => controller.reorderProviders(oldIndex, newIndex),
                                    itemBuilder: (context, index) {
                                      final id = controller.providerOrder[index];
                                      final provider = QuickSearchProvider.all.firstWhere((p) => p.id == id);
                                      final isEnabled = controller.isEnabled(provider.id);
                                      return Padding(
                                        key: ValueKey(id),
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          children: [
                                            if (provider.id == 'chatgpt')
                                              Container(width: 36, height: 36, decoration: BoxDecoration(color: eonbg, shape: BoxShape.circle), padding: const EdgeInsets.all(4), child: SvgPicture.asset(provider.assetIcon, colorFilter: ColorFilter.mode(ebgInverse, BlendMode.srcIn), fit: BoxFit.contain))
                                            else
                                              Container(width: 36, height: 36, decoration: BoxDecoration(color: provider.id == 'amazon' ? Colors.white : ebg, shape: BoxShape.circle), padding: EdgeInsets.all(provider.id == 'youtube' ? 7 : (provider.id == 'maps' || provider.id == 'osm') ? 8 : 6), child: SvgPicture.asset(provider.assetIcon, colorFilter: provider.id == 'spotify' ? const ColorFilter.mode(Color(0xFF1ED760), BlendMode.srcIn) : null, fit: BoxFit.contain)),
                                            const SizedBox(width: 12),
                                            Expanded(child: Text(provider.name, style: TextStyle(color: eonbg, fontSize: 15, fontWeight: isEnabled ? FontWeight.w500 : FontWeight.normal))),
                                            Switch(
                                              value: isEnabled,
                                              thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? esv : eonsv),
                                              trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? ep : eonbg.withOpacity(0.1)),
                                              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                                              onChanged: (_) { HapticFeedback.selectionClick(); controller.toggleProvider(provider.id); },
                                            ),
                                            ReorderableDragStartListener(index: index, child: Padding(padding: const EdgeInsets.all(12), child: Icon(Icons.drag_handle_rounded, color: eonbg.withOpacity(0.3)))),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
              ),
            ],
          );
        },
      );
    }

    return ListenableBuilder(
      listenable: searchController,
      builder: (context, child) {
        final Color ebg = context.ebackground;
        final Color esv = context.esurfacevariant;
        final Color eonsv = context.eonsurfacevariant;
        final Color ep = context.eprimary;
        final Color eonbg = context.eonbackground;
        final l10n = AppLocalizations.of(context);
        final selectedSource = searchController.privacySource;
        final activeEngine = searchController.activeEngine;

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
            leading: IconButton(icon: const Icon(Icons.arrow_back), color: eonbg, onPressed: () => Navigator.of(context).pop()),
            title: Text(l10n.get('search_title'), style: TextStyle(color: eonbg, fontWeight: FontWeight.w600)),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: [
                  buildSectionHeader(context, 'active_engine_header', infoTitleKey: 'active_engine_header', infoTextKey: 'active_engine_info'),
                  _buildSectionCard(
                    context: context,
                    shape: singleShape,
                    esv: esv,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: singleShape,
                        onTap: () => showEngineSwitcher(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              SizedBox(width: 28, height: 28, child: SvgPicture.asset(activeEngine.assetIcon, colorFilter: activeEngine.id == 'perplexity' ? const ColorFilter.mode(Color(0xFF20808D), BlendMode.srcIn) : null)),                              
                              const SizedBox(width: 16),
                              Expanded(child: Text(activeEngine.name, style: TextStyle(color: eonbg, fontSize: 16, fontWeight: FontWeight.w600))),
                              Icon(Icons.unfold_more_rounded, color: eonbg.withOpacity(0.3)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  buildSectionHeader(context, 'quick_search_header', infoTitleKey: 'info_quick_search_title', infoTextKey: 'info_quick_search_text'),
                  _buildSectionCard(
                    context: context,
                    shape: singleShape,
                    esv: esv,
                    child: ListenableBuilder(
                      listenable: QuickSearchController(),
                      builder: (context, child) {
                        final controller = QuickSearchController();
                        final Color ebgInverse = context.ebackground;
                        final activeProviders = controller.providerOrder.map((id) => QuickSearchProvider.all.firstWhere((p) => p.id == id)).where((p) => controller.isEnabled(p.id)).toList();

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: singleShape,
                            onTap: () => showQuickSearchSelector(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(l10n.get('quick_search_header'), style: TextStyle(color: eonbg, fontSize: 16, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 6),
                                        if (activeProviders.isEmpty)
                                          Text(l10n.get('disabled'), style: TextStyle(color: eonbg.withOpacity(0.5), fontSize: 13))
                                        else
                                          SizedBox(
                                            height: 24,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              shrinkWrap: true,
                                              itemCount: activeProviders.length,
                                              itemBuilder: (context, i) {
                                                final p = activeProviders[i];
                                                return Padding(
                                                  padding: const EdgeInsets.only(right: 6),
                                                  child: p.id == 'chatgpt' 
                                                    ? Container(width: 24, height: 24, decoration: BoxDecoration(color: eonbg, shape: BoxShape.circle), padding: const EdgeInsets.all(3), child: SvgPicture.asset(p.assetIcon, colorFilter: ColorFilter.mode(ebgInverse, BlendMode.srcIn), fit: BoxFit.contain))
                                                    : Container(width: 24, height: 24, decoration: BoxDecoration(color: p.id == 'amazon' ? Colors.white : ebg, shape: BoxShape.circle), padding: EdgeInsets.all(p.id == 'youtube' ? 3 : (p.id == 'maps' || p.id == 'osm') ? 5 : 4), child: SvgPicture.asset(p.assetIcon, colorFilter: p.id == 'spotify' ? const ColorFilter.mode(Color(0xFF1ED760), BlendMode.srcIn) : null, fit: BoxFit.contain)),
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.unfold_more_rounded, color: eonbg.withOpacity(0.3)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  buildSectionHeader(context, 'search_order_header'),
                  _buildSectionCard(
                    context: context,
                    shape: topShape,
                    esv: esv,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: ep, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.get('info_search_order_text'),
                              style: TextStyle(color: eonbg.withOpacity(0.6), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Theme(
                    data: Theme.of(context).copyWith(canvasColor: Colors.transparent, shadowColor: Colors.transparent),
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: searchController.searchOrder.length,
                      onReorder: (oldIndex, newIndex) => searchController.reorderSearch(oldIndex, newIndex),
                      itemBuilder: (context, index) {
                        final id = searchController.searchOrder[index];
                        final isVisible = searchController.isVisible(id);
                        final total = searchController.searchOrder.length;
                        final shape = index == total - 1 ? botShape : const BorderRadius.all(Radius.circular(4)); // midShape

                        String title; IconData icon; Future<bool> permFuture; String featName; String featDesc;
                        switch (id) {
                          case 'calendar': title = l10n.get('calendar_title'); icon = Icons.calendar_month_outlined; permFuture = CalendarService.checkPermission(); featName = l10n.get('calendar_title'); featDesc = l10n.get('perm_calendar_desc'); break;
                          case 'shortcuts': title = l10n.get('shortcuts_title'); icon = Icons.bolt; permFuture = Future.value(true); featName = ""; featDesc = ""; break;
                          case 'apps': title = l10n.get('apps_title'); icon = Icons.apps; permFuture = Future.value(true); featName = ""; featDesc = ""; break;
                          case 'contacts': title = l10n.get('contacts_title'); icon = Icons.person_search_outlined; permFuture = Permission.contacts.isGranted; featName = l10n.get('contacts_title'); featDesc = l10n.get('perm_contacts_desc'); break;
                          case 'files': title = l10n.get('files_title'); icon = Icons.folder_open; permFuture = FileService.hasPermission(); featName = l10n.get('perm_files_name'); featDesc = l10n.get('perm_files_desc'); break;
                          default: title = l10n.get('text_results_title'); icon = Icons.text_fields_rounded; permFuture = Future.value(true); featName = ""; featDesc = ""; break;
                        }

                        return FutureBuilder<bool>(
                          key: ValueKey(id),
                          future: permFuture,
                          builder: (context, snapshot) {
                            final hasPerm = snapshot.data ?? true;
                            return PermissionLockedOverlay(
                              isLocked: !hasPerm, onRefresh: _refresh, featureName: featName, description: featDesc,
                              child: Container(
                                margin: EdgeInsets.only(bottom: index < total - 1 ? 3 : 0),
                                child: _buildSectionCard(
                                  context: context,
                                  shape: shape,
                                  esv: esv,
                                  child: Opacity(
                                    opacity: isVisible ? 1.0 : 0.5,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      child: Row(
                                        children: [
                                          AppFallbackIcon(icon: icon, size: 32, iconSize: 18),
                                          const SizedBox(width: 16),
                                          Expanded(child: Text(title, style: TextStyle(color: eonbg, fontSize: 15, fontWeight: FontWeight.w600, decoration: isVisible ? null : TextDecoration.lineThrough))),
                                          Switch(
                                            value: isVisible,
                                            thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? esv : eonsv),
                                            trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? ep : eonbg.withOpacity(0.1)),
                                            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                                            onChanged: (_) { HapticFeedback.selectionClick(); searchController.toggleSearchVisibility(id); },
                                          ),
                                          ReorderableDragStartListener(index: index, child: Padding(padding: const EdgeInsets.only(left: 4), child: Icon(Icons.drag_handle_rounded, color: eonbg.withOpacity(0.3)))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  buildSectionHeader(context, 'file_search_settings_header', infoTitleKey: 'info_file_search_title', infoTextKey: 'info_file_search_text'),
                  FutureBuilder<bool>(
                    future: FileService.hasPermission(),
                    builder: (context, snapshot) {
                      final hasPerm = snapshot.data ?? false;
                      return PermissionLockedOverlay(
                        isLocked: !hasPerm, onRefresh: _refresh, featureName: l10n.get('perm_files_name'), description: l10n.get('perm_files_desc'),
                        child: _buildSectionCard(
                          context: context,
                          shape: singleShape,
                          esv: esv,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(l10n.get('file_search_limit_label'), style: TextStyle(color: eonbg, fontSize: 15, fontWeight: FontWeight.w600)),
                                    Text('${searchController.fileSearchLimit}', style: TextStyle(color: eonbg.withOpacity(0.7), fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(thumbColor: ep, activeTrackColor: ep, inactiveTrackColor: eonbg.withOpacity(0.1), overlayColor: ep.withOpacity(0.1)),
                                  child: Slider(
                                    value: searchController.fileSearchLimit.toDouble(),
                                    min: 1, max: 5, divisions: 4,
                                    onChanged: searchController.isVisible('files') ? (val) => searchController.setFileSearchLimit(val.toInt()) : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  buildSectionHeader(context, 'calendar_settings_header', infoTitleKey: 'info_calendar_title', infoTextKey: 'info_calendar_text'),
                  FutureBuilder<bool>(
                    future: CalendarService.checkPermission(),
                    builder: (context, snapshot) {
                      final hasPerm = snapshot.data ?? false;
                      return PermissionLockedOverlay(
                        isLocked: !hasPerm, onRefresh: _refresh, featureName: l10n.get('calendar_title'), description: l10n.get('perm_calendar_desc'),
                        child: Column(
                          children: [
                            _buildSectionCard(
                              context: context,
                              shape: topShape,
                              esv: esv,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(l10n.get('calendar_limit_label'), style: TextStyle(color: eonbg, fontSize: 15, fontWeight: FontWeight.w600)),
                                        Text('${searchController.calendarLimit}', style: TextStyle(color: eonbg.withOpacity(0.7), fontSize: 13)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(thumbColor: ep, activeTrackColor: ep, inactiveTrackColor: eonbg.withOpacity(0.1), overlayColor: ep.withOpacity(0.1)),
                                      child: Slider(
                                        value: searchController.calendarLimit.toDouble(),
                                        min: 3, max: 15, divisions: 12,
                                        onChanged: searchController.isVisible('calendar') ? (val) => searchController.setCalendarLimit(val.toInt()) : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            _buildSectionCard(
                              context: context,
                              shape: botShape,
                              esv: esv,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: botShape,
                                  onTap: searchController.isVisible('calendar') ? () => showCalendarSelector(context) : null,
                                  child: Opacity(
                                    opacity: searchController.isVisible('calendar') ? 1.0 : 0.5,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      child: Row(
                                        children: [
                                          AppFallbackIcon(icon: Icons.calendar_view_day_outlined, size: 36, iconSize: 18),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(l10n.get('calendar_selection_label'), style: TextStyle(color: eonbg, fontSize: 16, fontWeight: FontWeight.w600)),
                                                if (searchController.enabledCalendarIds.isEmpty && searchController.isVisible('calendar'))
                                                  Text(l10n.get('calendar_none_selected'), style: TextStyle(color: Colors.orange.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.chevron_right, color: eonbg.withOpacity(0.3), size: 20),
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
                    },
                  ),

                  buildSectionHeader(
                    context, 
                    'privacy_header', 
                    infoTitleKey: 'info_privacy_title', 
                    infoTextKey: 'info_privacy_text',
                    customContent: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.get('info_privacy_text'), style: TextStyle(color: eonbg.withOpacity(0.8), height: 1.4)),
                        const SizedBox(height: 16),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text("${l10n.get('privacy_for')} ", style: TextStyle(color: eonbg.withOpacity(0.8), height: 1.4)),
                            Container(width: 18, height: 18, padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: SvgPicture.asset('assets/icons/original/startpage-icon.svg')),
                            Text(" ${l10n.get('name_startpage')}, ", style: TextStyle(color: eonbg.withOpacity(0.8), height: 1.4)),
                            SvgPicture.asset('assets/icons/original/duckduckgo-icon.svg', width: 16, height: 16),
                            Text(" ${l10n.get('name_duckduckgo')} ${l10n.get('symbol_and')} ", style: TextStyle(color: eonbg.withOpacity(0.8), height: 1.4)),
                            SvgPicture.asset('assets/icons/dynamic/Pure White.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(Color(0xFF20808D), BlendMode.srcIn)),
                            Text(" ${l10n.get('name_perplexity')}", style: TextStyle(color: eonbg.withOpacity(0.8), height: 1.4)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SvgPicture.asset('assets/icons/original/Ecosia-like_logo.svg', width: 14, height: 14),
                            Text(" ${l10n.get('name_ecosia')} ${l10n.get('ecosia_note_mid')} ", style: TextStyle(color: eonbg.withOpacity(0.8), height: 1.4)),
                            SvgPicture.asset('assets/icons/original/Qwant_new_logo_2018.svg', width: 14, height: 14),
                            Text(" ${l10n.get('name_qwant')}.", style: TextStyle(color: eonbg.withOpacity(0.8), height: 1.4)),
                          ],
                        ),
                      ],
                    )
                  ),
                  FutureBuilder<bool>(
                    future: Future.wait([InternetService.isEnabled(), InternetService.isCompanionInstalled()]).then((results) async {
                      final enabled = results[0]; final installed = results[1];
                      if (!enabled || !installed) return false;
                      const String perm = "de.search.companion.internet.dw.INTERNET_ACCESS";
                      return await const MethodChannel('de.search.dw.search/permissions').invokeMethod('checkPermission', {'permission': perm}) ?? false;
                    }),
                    builder: (context, snapshot) {
                      final hasPerm = snapshot.data ?? false;
                      return PermissionLockedOverlay(
                        isLocked: !hasPerm, onRefresh: _refresh, featureName: l10n.get('internet_companion_name'), description: l10n.get('internet_companion_desc'),
                        child: _buildSectionCard(
                          context: context,
                          shape: singleShape,
                          esv: esv,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: singleShape,
                              onTap: () => showPrivacySourceSelector(context),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Row(
                                  children: [
                                    if (selectedSource == 'none') 
                                      Icon(Icons.block, color: eonbg.withOpacity(0.5), size: 28)
                                    else if (selectedSource == 'qwant')
                                      SvgPicture.asset('assets/icons/original/Qwant_new_logo_2018.svg', width: 28, height: 28)
                                    else if (selectedSource == 'brave')
                                      SvgPicture.asset('assets/icons/original/brave_logo.svg', width: 28, height: 28)
                                    else if (selectedSource == 'google')
                                      SvgPicture.asset('assets/icons/original/Google_Favicon_2025.svg', width: 28, height: 28)
                                    else if (selectedSource == 'bing')
                                      SvgPicture.asset('assets/icons/original/Bing_Fluent_Logo.svg', width: 28, height: 28),
                                    
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(l10n.get('privacy_selection_label'), style: TextStyle(color: eonbg, fontSize: 16, fontWeight: FontWeight.w600)),
                                          Text(
                                            selectedSource == 'none' ? l10n.get('opt_none') :
                                            selectedSource == 'qwant' ? l10n.get('name_qwant') :
                                            selectedSource == 'brave' ? l10n.get('opt_brave') :
                                            selectedSource == 'google' ? l10n.get('opt_google') :
                                            selectedSource == 'bing' ? l10n.get('opt_bing') : selectedSource,
                                            style: TextStyle(color: eonbg.withOpacity(0.7), fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, color: eonbg.withOpacity(0.3), size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
