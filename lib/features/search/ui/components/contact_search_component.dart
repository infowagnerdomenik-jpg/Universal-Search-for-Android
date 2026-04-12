import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// --- NEUE DESIGN ENGINE IMPORTE ---
import 'package:design_engine/layer3_logic/design_engine_controller.dart';
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

import 'package:search/features/search/logic/contact_cache.dart';
import 'package:search/features/search/logic/search_status_controller.dart';
import 'package:search/features/home/logic/contact_launch_tracker.dart';
import 'package:search/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactSearchComponent extends StatelessWidget {
  final String query;

  const ContactSearchComponent({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) return const SizedBox.shrink();

    return FutureBuilder<PermissionStatus>(
      future: Permission.contacts.status,
      builder: (context, snapshot) {
        if (snapshot.data != PermissionStatus.granted) return const SizedBox.shrink();

        // --- DESIGN ENGINE FARBEN ---
        final Color eonbg = context.eonbackground; // ehemals txt1
        final Color esv = context.esurfacevariant; // ehemals cf2
        final Color ep = context.eprimary;         // ehemals cf3
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        return ValueListenableBuilder<List<CachedContact>>(
          valueListenable: ContactCache.contactsNotifier,
          builder: (context, allContacts, child) {
            if (allContacts.isEmpty) return const SizedBox.shrink();

            final q = query.toLowerCase().trim();
            var results = allContacts.where((contact) {
              return contact.name.toLowerCase().contains(q) || contact.phones.any((p) => p.contains(q));
            }).toList();

            if (results.length > 8) results = results.sublist(0, 8);
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              SearchStatusController().reportResults('contacts', results.length);
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
                      AppLocalizations.of(context).get('contacts_title'),
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
                        final contact = results[index];
                        return GestureDetector(
                          onTap: () async {
                            HapticFeedback.mediumImpact();
                            await ContactLaunchTracker.recordContactLaunch(contact.id);
                            final Uri contactUri = Uri.parse("content://com.android.contacts/contacts/${contact.id}");
                            try { await launchUrl(contactUri, mode: LaunchMode.externalApplication); } catch (_) {}
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 28, 
                                backgroundColor: ep.withOpacity(0.1),
                                backgroundImage: contact.photo != null ? MemoryImage(contact.photo!) : null,
                                child: contact.photo == null
                                    ? const AppFallbackIcon(icon: Icons.person_outline, size: 56, iconSize: 28)
                                    : null,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                contact.name,
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
