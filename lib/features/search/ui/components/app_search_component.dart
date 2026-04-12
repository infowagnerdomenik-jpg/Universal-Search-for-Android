import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';

// --- NEUE DESIGN ENGINE IMPORTE ---
import 'package:design_engine/layer3_logic/design_engine_controller.dart';
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

import 'package:search/features/home/logic/app_launch_tracker.dart';
import 'package:search/features/search/logic/app_cache.dart';
import 'package:search/features/search/logic/search_status_controller.dart';
import 'package:search/l10n/app_localizations.dart';

class AppSearchComponent extends StatelessWidget {
  final String query;

  const AppSearchComponent({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) return const SizedBox.shrink();

    return FutureBuilder<bool>(
      future: AppCache.isEnabled(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();

        // --- DESIGN ENGINE FARBEN ---
        final Color eonbg = context.eonbackground; // ehemals txt1
        final Color esv = context.esurfacevariant; // ehemals cf2
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        return ValueListenableBuilder<List<CachedApp>>(
          valueListenable: AppCache.appsNotifier,
          builder: (context, allApps, child) {
            if (allApps.isEmpty) return const SizedBox.shrink();

            final q = query.toLowerCase().trim();
            var results = allApps.where((app) => app.name.toLowerCase().contains(q)).toList();

            if (results.length > 8) results = results.sublist(0, 8);
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              SearchStatusController().reportResults('apps', results.length);
            });

            if (results.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16), // Vereinheitlicht
                decoration: BoxDecoration(
                  color: esv,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.0 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).get('apps_title'),
                      style: TextStyle(color: eonbg, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: results.length,
                      padding: EdgeInsets.zero, // Wichtig
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 0,
                        crossAxisSpacing: 8,
                        mainAxisExtent: 82, // Vereinheitlicht
                      ),
                      itemBuilder: (context, index) {
                        final app = results[index];
                        return GestureDetector(
                          onTap: () async {
                            HapticFeedback.mediumImpact();
                            await AppLaunchTracker.recordAppLaunch(app.packageName);
                            InstalledApps.startApp(app.packageName);
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              app.icon != null
                                  ? Image.memory(app.icon!, width: 56, height: 56)
                                  : Icon(Icons.android, color: eonbg, size: 56),
                              const SizedBox(height: 4),
                              Text(
                                app.name,
                                style: TextStyle(color: eonbg, fontSize: 11, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
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
}
