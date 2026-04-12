import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:design_engine/layer3_logic/design_engine_controller.dart';
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

import 'package:search/features/settings/logic/home_layout_controller.dart';
import 'package:search/features/search/logic/search_settings_controller.dart';
import 'package:search/features/search/logic/file_service.dart';
import 'package:search/features/calendar/logic/calendar_service.dart';
import 'package:search/features/settings/ui/components/permission_locked_overlay.dart';
import 'package:search/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeSettingsScreen extends StatefulWidget {
  const HomeSettingsScreen({super.key});

  @override
  State<HomeSettingsScreen> createState() => _HomeSettingsScreenState();
}

class _HomeSettingsScreenState extends State<HomeSettingsScreen> {
  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final layoutController = HomeLayoutController();
    final searchController = SearchSettingsController();
    final designController = Provider.of<DesignEngineController>(context);
    final bool isDark = designController.isEffectiveDark(context);

    final Color ebg   = context.ebackground;
    final Color esv   = context.esurfacevariant;
    final Color eonbg = context.eonbackground;
    final Color eonsv = context.eonsurfacevariant;
    final Color ep    = context.eprimary;

    const topShape = BorderRadius.only(
      topLeft: Radius.circular(28), topRight: Radius.circular(28),
      bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4),
    );
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
        iconTheme: IconThemeData(color: eonbg),
        title: Text(
          l10n.get('home_settings_title'),
          style: TextStyle(color: eonbg, fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListenableBuilder(
            listenable: layoutController,
            builder: (context, _) {
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: [

                  // --- Keyboard section ---
                  _SectionHeader(text: l10n.get('keyboard_section_title'), color: eonbg),
                  _SectionCard(shape: topShape, esv: esv,
                    child: _SwitchRow(
                      title: l10n.get('keyboard_auto_title'),
                      subtitle: l10n.get('keyboard_auto_subtitle'),
                      value: layoutController.keyboardAuto,
                      onChanged: (val) { HapticFeedback.selectionClick(); layoutController.setKeyboardAuto(val); },
                      eonbg: eonbg, eonsv: eonsv, ep: ep, esv: esv,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _SectionCard(shape: botShape, esv: esv,
                    child: _SwitchRow(
                      title: l10n.get('keyboard_start_title'),
                      subtitle: l10n.get('keyboard_start_subtitle'),
                      value: layoutController.keyboardOnStart,
                      onChanged: (val) { HapticFeedback.selectionClick(); layoutController.setKeyboardOnStart(val); },
                      eonbg: eonbg, eonsv: eonsv, ep: ep, esv: esv,
                    ),
                  ),

                  // --- Widget order section ---
                  _SectionHeader(text: l10n.get('widget_order_section_title'), color: eonbg),

                  _SectionCard(
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
                              l10n.get('home_settings_info'),
                              style: TextStyle(color: eonbg.withOpacity(0.6), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 3),

                  // --- Reorderable widget list ---
                  Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: layoutController.widgetOrder.length,
                      onReorder: layoutController.reorder,
                      itemBuilder: (context, index) {
                        final id = layoutController.widgetOrder[index];
                        final isVisible = layoutController.isVisible(id);
                        final total = layoutController.widgetOrder.length;
                        final shape = index == total - 1 ? botShape : const BorderRadius.all(Radius.circular(4));

                        String title;
                        IconData icon;
                        Future<bool> permFuture;
                        String featName;
                        String featDesc;

                        switch (id) {
                          case 'calendar':
                            title = l10n.get('calendar_agenda_title');
                            icon = Icons.calendar_today;
                            permFuture = CalendarService.checkPermission();
                            featName = l10n.get('calendar_title');
                            featDesc = l10n.get('perm_calendar_desc');
                            break;
                          case 'apps':
                            title = l10n.get('frequent_apps_title');
                            icon = Icons.apps;
                            permFuture = Future.value(true);
                            featName = '';
                            featDesc = '';
                            break;
                          case 'contacts':
                            title = l10n.get('frequent_contacts_title');
                            icon = Icons.person_search_outlined;
                            permFuture = Permission.contacts.isGranted;
                            featName = l10n.get('contacts_title');
                            featDesc = l10n.get('perm_contacts_desc');
                            break;
                          case 'files':
                          default:
                            title = l10n.get('frequent_files_title');
                            icon = Icons.folder_open;
                            permFuture = FileService.hasPermission();
                            featName = l10n.get('perm_files_name');
                            featDesc = l10n.get('perm_files_desc');
                        }

                        return FutureBuilder<bool>(
                          key: ValueKey(id),
                          future: permFuture,
                          builder: (context, snapshot) {
                            final hasPerm = snapshot.data ?? true;

                            return PermissionLockedOverlay(
                              isLocked: !hasPerm && id != 'apps',
                              onRefresh: _refresh,
                              featureName: featName,
                              description: featDesc,
                              child: Opacity(
                                opacity: isVisible ? 1.0 : 0.5,
                                child: Container(
                                  margin: EdgeInsets.only(bottom: index < total - 1 ? 3 : 0),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    child: Row(
                                      children: [
                                        Icon(icon, color: eonbg, size: 22),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: Text(
                                              title,
                                              style: TextStyle(
                                                color: eonbg,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                decoration: isVisible ? null : TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Switch(
                                          value: isVisible,
                                          onChanged: (_) { HapticFeedback.selectionClick(); layoutController.toggleVisibility(id); },
                                          thumbColor: WidgetStateProperty.resolveWith((states) =>
                                              states.contains(WidgetState.selected) ? esv : eonsv),
                                          trackColor: WidgetStateProperty.resolveWith((states) =>
                                              states.contains(WidgetState.selected) ? ep : eonbg.withOpacity(0.1)),
                                          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                                        ),
                                        ReorderableDragStartListener(
                                          index: index,
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 4),
                                            child: Icon(Icons.drag_handle_rounded, color: eonbg.withOpacity(0.3)),
                                          ),
                                        ),
                                      ],
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

                  // --- File widget limit ---
                  ListenableBuilder(
                    listenable: searchController,
                    builder: (context, _) {
                      if (!layoutController.isVisible('files')) return const SizedBox.shrink();

                      return FutureBuilder<bool>(
                        future: FileService.hasPermission(),
                        builder: (context, snapshot) {
                          final hasPerm = snapshot.data ?? false;
                          return PermissionLockedOverlay(
                            isLocked: !hasPerm,
                            onRefresh: _refresh,
                            featureName: l10n.get('perm_files_name'),
                            description: l10n.get('perm_files_widget_desc'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                _SectionHeader(text: l10n.get('file_widget_settings_header'), color: eonbg),
                                _SectionCard(
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
                                            Text(
                                              l10n.get('file_widget_limit_label'),
                                              style: TextStyle(color: eonbg, fontSize: 15, fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              '${searchController.fileWidgetLimit}',
                                              style: TextStyle(color: eonsv, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            thumbColor: ep,
                                            activeTrackColor: ep,
                                            inactiveTrackColor: eonbg.withOpacity(0.1),
                                            overlayColor: ep.withOpacity(0.1),
                                          ),
                                          child: Slider(
                                            value: searchController.fileWidgetLimit.toDouble(),
                                            min: 1,
                                            max: 5,
                                            divisions: 4,
                                            onChanged: (val) => searchController.setFileWidgetLimit(val.toInt()),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// --- Shared widgets ---

class _SectionHeader extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onInfo;

  const _SectionHeader({required this.text, required this.color, this.onInfo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 16, right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: color.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          if (onInfo != null)
            InkWell(
              onTap: onInfo,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.info_outline, size: 18, color: color.withOpacity(0.4)),
              ),
            ),
        ],
      ),
    );
  }
}

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
              padding: const EdgeInsets.only(right: 16),
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

// --- Shape helper (reusable for grouped lists) ---

BorderRadius shapeForIndex(int index, int total) {
  if (total == 1) {
    return const BorderRadius.all(Radius.circular(28));
  }
  if (index == 0) {
    return const BorderRadius.only(
      topLeft: Radius.circular(28), topRight: Radius.circular(28),
      bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4),
    );
  }
  if (index == total - 1) {
    return const BorderRadius.only(
      topLeft: Radius.circular(4), topRight: Radius.circular(4),
      bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28),
    );
  }
  return const BorderRadius.all(Radius.circular(4));
}
