import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class SystemShortcut {
  final String title;
  final String action;
  final List<String> keywords;
  final int minSdk;
  final int? maxSdk;
  final IconData icon;

  SystemShortcut({
    required this.title,
    required this.action,
    required this.keywords,
    this.minSdk = 1,
    this.maxSdk,
    required this.icon,
  });
}

class ShortcutService {
  static const _channel = MethodChannel('de.search.dw.search/calendar'); // Wir nutzen den gleichen Kanal für Native Hilfen
  
  static int? _currentSdkVersion;

  static final List<SystemShortcut> _allShortcuts = [
    // --- DEINE LISTE ---
    SystemShortcut(title: 'Internet', action: 'android.settings.WIFI_SETTINGS', keywords: ['wifi', 'wlan', 'netzwerk', 'online'], icon: Icons.wifi),
    SystemShortcut(title: 'Einhandmodus', action: 'android.settings.ONE_HANDED_SETTINGS', keywords: ['hand', 'klein', 'einhand'], minSdk: 31, icon: Icons.front_hand_outlined),
    SystemShortcut(title: 'Datennutzung', action: 'android.settings.DATA_USAGE_SETTINGS', keywords: ['daten', 'mobile', 'verbrauch', 'traffic', 'gb'], icon: Icons.data_usage),
    SystemShortcut(title: 'WLAN-Hotspot', action: 'android.settings.TETHER_SETTINGS', keywords: ['hotspot', 'tethering', 'internet teilen', 'modem'], icon: Icons.wifi_tethering),
    SystemShortcut(title: 'VPN', action: 'android.settings.VPN_SETTINGS', keywords: ['vpn', 'tunnel', 'sicher', 'verschlüsselung'], icon: Icons.vpn_key),
    SystemShortcut(title: 'Geräte', action: 'android.settings.BLUETOOTH_SETTINGS', keywords: ['bluetooth', 'bt', 'verbindungen', 'pairing'], icon: Icons.devices),
    SystemShortcut(title: 'App-Info', action: 'android.settings.APPLICATION_SETTINGS', keywords: ['apps', 'anwendungen', 'installiert', 'deinstallieren'], icon: Icons.apps),
    SystemShortcut(title: 'Benachrichtigungen', action: 'android.settings.NOTIFICATION_SETTINGS', keywords: ['notif', 'alarm', 'stören', 'push'], icon: Icons.notifications_none),
    SystemShortcut(title: 'Display', action: 'android.settings.DISPLAY_SETTINGS', keywords: ['bildschirm', 'helligkeit', 'hintergrund', 'timeout'], icon: Icons.screenshot_monitor),
    SystemShortcut(title: 'Bildschirm automatisch drehen', action: 'android.settings.AUTO_ROTATE_SETTINGS', keywords: ['drehen', 'rotation', 'querformat', 'hochformat'], icon: Icons.screen_rotation),
    SystemShortcut(title: 'Nachtlicht', action: 'android.settings.NIGHT_DISPLAY_SETTINGS', keywords: ['nacht', 'blaufilter', 'licht', 'augen'], icon: Icons.nightlight_round),
    SystemShortcut(title: 'Dunkles Design', action: 'android.settings.DARK_THEME_SETTINGS', keywords: ['dark', 'schwarz', 'modus', 'nachtmodus'], minSdk: 29, icon: Icons.dark_mode),
    SystemShortcut(title: 'Gesten-Navigation', action: 'android.settings.GESTURE_NAVIGATION_SETTINGS', keywords: ['gesten', 'wischen', 'steuerung', 'navi'], minSdk: 29, icon: Icons.gesture),
    SystemShortcut(title: 'Bedienung über Schaltflächen', action: 'android.settings.NAVIGATION_MODE_SETTINGS', keywords: ['buttons', 'tasten', 'unten', 'steuerung'], minSdk: 29, icon: Icons.smart_button),
    SystemShortcut(title: 'Sound und Vibration', action: 'android.settings.SOUND_SETTINGS', keywords: ['ton', 'lautstärke', 'klingelton', 'vibration', 'musik'], icon: Icons.volume_up),
    SystemShortcut(title: 'Modi', action: 'android.settings.ZEN_MODE_PRIORITY_SETTINGS', keywords: ['fokus', 'ruhe', 'priorität'], maxSdk: 33, icon: Icons.do_not_disturb_on_total_silence),
    SystemShortcut(title: 'Speicher', action: 'android.settings.INTERNAL_STORAGE_SETTINGS', keywords: ['sd', 'platz', 'frei', 'dateien', 'gb'], icon: Icons.storage),
    SystemShortcut(title: 'Akku', action: 'android.intent.action.POWER_USAGE_SUMMARY', keywords: ['batterie', 'laden', 'strom', 'energie', 'prozent'], icon: Icons.battery_charging_full),
    SystemShortcut(title: 'Standort', action: 'android.settings.LOCATION_SOURCE_SETTINGS', keywords: ['gps', 'ortung', 'maps', 'position'], icon: Icons.location_on),
    SystemShortcut(title: 'Passwörter und Konten', action: 'android.settings.SYNC_SETTINGS', keywords: ['login', 'google', 'user', 'benutzer', 'synchronisation'], icon: Icons.supervisor_account),
    SystemShortcut(title: 'Bedienungshilfen', action: 'android.settings.ACCESSIBILITY_SETTINGS', keywords: ['barrierefrei', 'voice', 'hilfe', 'lupe'], icon: Icons.accessibility),
    SystemShortcut(title: 'System', action: 'android.settings.SYSTEM_SETTINGS', keywords: ['update', 'sicherung', 'backup', 'zeit'], icon: Icons.settings_suggest),
    SystemShortcut(title: 'Über das Telefon', action: 'android.settings.DEVICE_INFO_SETTINGS', keywords: ['info', 'version', 'modell', 'status', 'imei'], icon: Icons.info_outline),

    // --- MEINE ERGÄNZUNGEN ---
    SystemShortcut(title: 'Digital Wellbeing', action: 'com.google.android.apps.wellbeing.action.DASHBOARD', keywords: ['bildschirmzeit', 'fokus', 'kindersicherung', 'zeitlimit'], icon: Icons.hourglass_empty),
    SystemShortcut(title: 'NFC', action: 'android.settings.NFC_SETTINGS', keywords: ['bezahlen', 'kontaktlos', 'wallet', 'nfc'], icon: Icons.nfc),
    SystemShortcut(title: 'Entwickleroptionen', action: 'android.settings.APPLICATION_DEVELOPMENT_SETTINGS', keywords: ['usb', 'debugging', 'adb', 'oem'], icon: Icons.code),
    SystemShortcut(title: 'Benachrichtigungsverlauf', action: 'android.settings.NOTIFICATION_HISTORY', keywords: ['history', 'verlauf', 'gelöscht', 'verpasst'], minSdk: 30, icon: Icons.history),
    SystemShortcut(title: 'Nicht stören', action: 'android.settings.ZEN_MODE_PRIORITY_SETTINGS', keywords: ['dnd', 'ruhe', 'lautlos', 'fokus'], minSdk: 34, icon: Icons.do_not_disturb_on),
    SystemShortcut(title: 'Tastatur & Eingabe', action: 'android.settings.INPUT_METHOD_SETTINGS', keywords: ['keyboard', 'tippen', 'gboard', 'sprache'], icon: Icons.keyboard),
    SystemShortcut(title: 'Datum & Uhrzeit', action: 'android.settings.DATE_SETTINGS', keywords: ['zeit', 'uhr', 'wecker', 'datum'], icon: Icons.access_time),
    SystemShortcut(title: 'Sprachen', action: 'android.settings.LOCALE_SETTINGS', keywords: ['region', 'land', 'übersetzung', 'deutsch'], icon: Icons.language),
    SystemShortcut(title: 'Datenschutz', action: 'android.settings.PRIVACY_SETTINGS', keywords: ['privacy', 'tracking', 'berechtigung', 'mikrofon', 'kamera'], minSdk: 29, icon: Icons.privacy_tip),
    SystemShortcut(title: 'Standard-Apps', action: 'android.settings.MANAGE_DEFAULT_APPS_SETTINGS', keywords: ['browser', 'launcher', 'standard', 'sms'], minSdk: 28, icon: Icons.star_border),
    SystemShortcut(title: 'Cast / Übertragen', action: 'android.settings.CAST_SETTINGS', keywords: ['tv', 'monitor', 'streaming', 'spiegeln'], icon: Icons.cast),
  ];

  static Future<int> _getSdkVersion() async {
    if (_currentSdkVersion != null) return _currentSdkVersion!;
    try {
      _currentSdkVersion = await _channel.invokeMethod<int>('getSdkVersion');
    } catch (e) {
      _currentSdkVersion = 30; // Fallback
    }
    return _currentSdkVersion!;
  }

  static Future<List<SystemShortcut>> searchShortcuts(String query) async {
    final q = query.toLowerCase().trim();
    if (q.length < 2) return [];

    final sdk = await _getSdkVersion();

    return _allShortcuts.where((s) {
      // SDK Check
      if (s.minSdk > sdk) return false;
      if (s.maxSdk != null && s.maxSdk! < sdk) return false;

      // Text Check
      if (s.title.toLowerCase().contains(q)) return true;
      return s.keywords.any((k) => k.contains(q));
    }).toList();
  }

  static Future<void> launch(SystemShortcut shortcut) async {
    try {
      await _channel.invokeMethod('launchSettingsShortcut', {'action': shortcut.action});
    } catch (e) {
      debugPrint("Fehler beim Starten des Shortcuts: $e");
    }
  }
}
