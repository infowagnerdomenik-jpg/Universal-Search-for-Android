import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:search/features/search/logic/system_cache_service.dart';
import 'package:search/features/home/logic/contact_launch_tracker.dart';

class CachedContact {
  final String id;
  final String name;
  final List<String> phones;
  final Uint8List? photo;

  CachedContact({
    required this.id,
    required this.name,
    required this.phones,
    this.photo,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedContact &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          listEquals(phones, other.phones) &&
          listEquals(photo, other.photo);

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ phones.hashCode ^ photo.hashCode;
}

class ContactCache {
  static final ValueNotifier<List<CachedContact>> contactsNotifier = ValueNotifier([]);
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) {
      if (contactsNotifier.value.isEmpty) await refresh();
      return;
    }
    
    final status = await Permission.contacts.status;
    if (!status.isGranted) {
      contactsNotifier.value = [];
      return;
    }

    _isInitialized = true;
    final cachedData = await SystemCacheService.load('contact_cache_v2');

    if (cachedData != null) {
      contactsNotifier.value = _decode(cachedData);
      refresh();
    } else {
      await refresh();
    }
  }

  static Future<void> clear() async {
    await SystemCacheService.clear('contact_cache_v2');
    await ContactLaunchTracker.clear(); // NEU: Nutzungsdaten löschen
    contactsNotifier.value = [];
  }

  static Future<void> refresh() async {
    try {
      final status = await Permission.contacts.status;
      if (!status.isGranted) return;

      final List<Contact> contacts = await FastContacts.getAllContacts();

      List<CachedContact> newContacts = [];
      
      for (var c in contacts) {
        Uint8List? image;
        try {
           image = await FastContacts.getContactImage(c.id);
        } catch (_) {}

        newContacts.add(CachedContact(
          id: c.id,
          name: c.displayName,
          phones: c.phones.map((p) => p.number).toList(),
          photo: image,
        ));
      }

      newContacts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      contactsNotifier.value = newContacts;
      await SystemCacheService.save('contact_cache_v2', _encode(newContacts));
    } catch (e) {
      debugPrint("Fehler beim Kontakt-Update: $e");
    }
  }

  static String _encode(List<CachedContact> contacts) {
    List<Map<String, dynamic>> list = contacts.map((c) => {
      'id': c.id,
      'n': c.name,
      'p': c.phones,
      'i': c.photo != null ? base64Encode(c.photo!) : null,
    }).toList();
    return jsonEncode(list);
  }

  static List<CachedContact> _decode(String jsonStr) {
    try {
      List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => CachedContact(
        id: item['id'] ?? '',
        name: item['n'] ?? '',
        phones: List<String>.from(item['p'] ?? []),
        photo: item['i'] != null ? base64Decode(item['i']) : null,
      )).toList();
    } catch (e) {
      return [];
    }
  }
}
