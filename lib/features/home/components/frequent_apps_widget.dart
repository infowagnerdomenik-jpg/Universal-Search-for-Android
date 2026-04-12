import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';

// --- NEUE DESIGN ENGINE IMPORTE ---
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

import 'package:search/features/home/logic/app_launch_tracker.dart';
import 'package:search/features/search/logic/app_cache.dart';
import 'package:search/l10n/app_localizations.dart';

class FrequentAppsWidget extends StatefulWidget {
  const FrequentAppsWidget({super.key});

  @override
  State<FrequentAppsWidget> createState() => _FrequentAppsWidgetState();
}

class _FrequentAppsWidgetState extends State<FrequentAppsWidget> with WidgetsBindingObserver {
  List<String> _displayPackageNames = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppCache.init();
    _refreshAppList();
    AppCache.appsNotifier.addListener(_onCacheChanged);
  }

  @override
  void dispose() {
    AppCache.appsNotifier.removeListener(_onCacheChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onCacheChanged() {
    if (AppCache.appsNotifier.value.isEmpty) {
      if (mounted) setState(() => _displayPackageNames = []);
    }
    _refreshAppList();
  }

  Future<void> _refreshAppList() async {
    final realTopPkgs = await AppLaunchTracker.getTopApps(8);

    if (realTopPkgs.length >= 8) {
      if (mounted) setState(() => _displayPackageNames = realTopPkgs);
      return;
    }

    final allCachedApps = AppCache.appsNotifier.value;

    if (allCachedApps.isNotEmpty) {
      List<CachedApp> shuffled = List.from(allCachedApps)..shuffle(Random());
      List<String> combined = List.from(realTopPkgs);

      for (var app in shuffled) {
        if (combined.length >= 8) break;
        if (!combined.contains(app.packageName)) {
          combined.add(app.packageName);
        }
      }

      if (mounted) {
        setState(() {
          _displayPackageNames = combined;
        });
      }
    } else {
      if (mounted) setState(() => _displayPackageNames = realTopPkgs);
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- DESIGN ENGINE FARBEN ---
    final Color esv = context.esurfacevariant;         // ehemals cf2
    final Color eprimary = context.eprimary;           // ehemals cf3
    final Color eonsv = context.eonsurfacevariant;     // ehemals txt1
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final l10n = AppLocalizations.of(context);

    return FutureBuilder<bool>(
      future: AppCache.isEnabled(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();

        return ValueListenableBuilder<List<CachedApp>>(
          valueListenable: AppCache.appsNotifier,
          builder: (context, allApps, child) {
            if (allApps.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: esv,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(eprimary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        l10n.get('frequent_apps_loading'),
                        style: TextStyle(color: eonsv, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }

            List<CachedApp> matchedApps = [];
            for (String packageName in _displayPackageNames) {
              try {
                final app = allApps.firstWhere((a) => a.packageName == packageName);
                matchedApps.add(app);
              } catch (e) {}
            }

            if (matchedApps.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4), // Minimaler Abstand unten
                decoration: BoxDecoration(
                  color: esv,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.0 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.get('frequent_apps_title'),
                      style: TextStyle(color: eonsv, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TweenAnimationBuilder<double>(
                      key: ValueKey(_displayPackageNames.join(',')),
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 0,
                          crossAxisSpacing: 8,
                          mainAxisExtent: 90,
                        ),
                        itemCount: matchedApps.length,
                        itemBuilder: (context, index) {
                          final app = matchedApps[index];
                          return _buildAppItem(app, eonsv);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAppItem(CachedApp app, Color eonsv) {
    return GestureDetector(
      key: ValueKey(app.packageName),
      onTap: () async {
        HapticFeedback.mediumImpact();
        await AppLaunchTracker.recordAppLaunch(app.packageName);
        InstalledApps.startApp(app.packageName);
        _refreshAppList();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (app.icon != null)
            Image.memory(app.icon!, width: 56, height: 56)
            else
              Icon(Icons.android, color: eonsv, size: 56),

              const SizedBox(height: 4),
              Text(
                app.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: eonsv, fontSize: 11, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
        ],
      ),
    );
  }
}
