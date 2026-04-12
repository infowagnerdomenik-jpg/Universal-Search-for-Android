import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

// --- NEUE DESIGN ENGINE IMPORTE ---
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

import 'package:search/features/home/logic/contact_launch_tracker.dart';
import 'package:search/features/search/logic/contact_cache.dart';
import 'package:search/l10n/app_localizations.dart';

class FrequentContactsWidget extends StatefulWidget {
  const FrequentContactsWidget({super.key});

  @override
  State<FrequentContactsWidget> createState() => _FrequentContactsWidgetState();
}

class _FrequentContactsWidgetState extends State<FrequentContactsWidget> with WidgetsBindingObserver {
  List<String> _displayContactIds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ContactCache.init();
    _refreshContactList();
    ContactCache.contactsNotifier.addListener(_onCacheChanged);
  }

  @override
  void dispose() {
    ContactCache.contactsNotifier.removeListener(_onCacheChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onCacheChanged() {
    if (ContactCache.contactsNotifier.value.isEmpty) {
      if (mounted) setState(() => _displayContactIds = []);
    }
    _refreshContactList();
  }

  Future<void> _refreshContactList() async {
    if (!await Permission.contacts.isGranted) {
      if (mounted) setState(() => _displayContactIds = []);
      return;
    }

    final realTopIds = await ContactLaunchTracker.getTopContacts(8);

    if (realTopIds.length >= 8) {
      if (mounted) setState(() => _displayContactIds = realTopIds);
      return;
    }

    final allCachedContacts = ContactCache.contactsNotifier.value;

    if (allCachedContacts.isNotEmpty) {
      List<CachedContact> shuffled = List.from(allCachedContacts)..shuffle(Random());
      List<String> combined = List.from(realTopIds);

      for (var contact in shuffled) {
        if (combined.length >= 8) break;
        if (!combined.contains(contact.id)) {
          combined.add(contact.id);
        }
      }

      if (mounted) {
        setState(() {
          _displayContactIds = combined;
        });
      }
    } else {
      if (mounted) setState(() => _displayContactIds = realTopIds);
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

    return FutureBuilder<PermissionStatus>(
      future: Permission.contacts.status,
      builder: (context, snapshot) {
        if (snapshot.data != PermissionStatus.granted) return const SizedBox.shrink();

        return ValueListenableBuilder<List<CachedContact>>(
          valueListenable: ContactCache.contactsNotifier,
          builder: (context, allContacts, child) {
            if (allContacts.isEmpty) {
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
                        l10n.get('frequent_contacts_loading'),
                        style: TextStyle(color: eonsv, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (_displayContactIds.isEmpty) {
              Future.microtask(() => _refreshContactList());
            }

            List<CachedContact> matchedContacts = [];
            for (String id in _displayContactIds) {
              try {
                final contact = allContacts.firstWhere((c) => c.id == id);
                matchedContacts.add(contact);
              } catch (e) {}
            }

            if (matchedContacts.isEmpty) return const SizedBox.shrink();

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
                      l10n.get('frequent_contacts_title'),
                      style: TextStyle(color: eonsv, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TweenAnimationBuilder<double>(
                      key: ValueKey(_displayContactIds.join(',')),
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
                        itemCount: matchedContacts.length,
                        itemBuilder: (context, index) {
                          final contact = matchedContacts[index];
                          return _buildContactItem(contact, eonsv, eprimary);
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

  Widget _buildContactItem(CachedContact contact, Color eonsv, Color eprimary) {
    return GestureDetector(
      key: ValueKey(contact.id),
      onTap: () async {
        HapticFeedback.mediumImpact();
        await ContactLaunchTracker.recordContactLaunch(contact.id);
        final Uri contactUri = Uri.parse("content://com.android.contacts/contacts/${contact.id}");
        try {
          await launchUrl(contactUri, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint("Fehler beim Öffnen des Kontakts: $e");
        }
        _refreshContactList();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: eprimary.withOpacity(0.1),
            backgroundImage: contact.photo != null ? MemoryImage(contact.photo!) : null,
            child: contact.photo == null
            ? const AppFallbackIcon(icon: Icons.person_outline, size: 56, iconSize: 28)
            : null,
          ),
          const SizedBox(height: 4),
          Text(
            contact.name,
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
