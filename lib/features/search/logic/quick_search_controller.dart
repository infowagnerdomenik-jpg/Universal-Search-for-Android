import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/quick_search_provider.dart';

class QuickSearchController extends ChangeNotifier {
  static final QuickSearchController _instance = QuickSearchController._internal();
  factory QuickSearchController() => _instance;

  QuickSearchController._internal();

  static const String _keyOpenInApp = 'quick_search_open_in_app';
  static const String _keyProviderPrefix = 'quick_search_enabled_';
  static const String _keyOrder = 'quick_search_order';

  bool _openInApp = false;
  bool get openInApp => _openInApp;

  final Map<String, bool> _enabledProviders = {};
  List<String> _providerOrder = [];
  List<String> get providerOrder => _providerOrder;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    _openInApp = prefs.getBool(_keyOpenInApp) ?? false;

    for (var provider in QuickSearchProvider.all) {
      _enabledProviders[provider.id] = prefs.getBool(_keyProviderPrefix + provider.id) ?? true;
    }

    _providerOrder = prefs.getStringList(_keyOrder) ?? 
        QuickSearchProvider.all.map((e) => e.id).toList();
    
    // Sicherstellen, dass neue Anbieter in der Liste landen
    for (var p in QuickSearchProvider.all) {
      if (!_providerOrder.contains(p.id)) _providerOrder.add(p.id);
    }
    
    notifyListeners();
  }

  bool isEnabled(String id) => _enabledProviders[id] ?? true;

  Future<void> reorderProviders(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _providerOrder.removeAt(oldIndex);
    _providerOrder.insert(newIndex, item);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyOrder, _providerOrder);
  }

  Future<void> setOpenInApp(bool value) async {
    if (_openInApp == value) return;
    _openInApp = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOpenInApp, value);
  }

  Future<void> toggleProvider(String id) async {
    final currentValue = _enabledProviders[id] ?? true;
    _enabledProviders[id] = !currentValue;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyProviderPrefix + id, !currentValue);
  }
}
