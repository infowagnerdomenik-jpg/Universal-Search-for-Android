import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeLayoutController extends ChangeNotifier {
  static const String _key = 'home_layout_order';
  static const String _visKey = 'home_layout_visibility';
  static const String _kbAutoKey = 'home_keyboard_auto';
  static const String _kbStartKey = 'home_keyboard_start';
  
  List<String> _widgetOrder = ['calendar', 'apps', 'contacts', 'files'];
  Map<String, bool> _visibility = {'calendar': true, 'apps': true, 'contacts': true, 'files': true};

  bool _keyboardAuto = true;
  bool _keyboardOnStart = true;

  List<String> get widgetOrder => _widgetOrder;
  bool isVisible(String id) => _visibility[id] ?? true;
  
  bool get keyboardAuto => _keyboardAuto;
  bool get keyboardOnStart => _keyboardOnStart;

  static final HomeLayoutController _instance = HomeLayoutController._internal();
  factory HomeLayoutController() => _instance;
  HomeLayoutController._internal();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedOrder = prefs.getStringList(_key);
    final String? savedVis = prefs.getString(_visKey);
    
    if (savedOrder != null && savedOrder.isNotEmpty) {
      _widgetOrder = savedOrder;
    }

    if (!_widgetOrder.contains('calendar')) _widgetOrder.insert(0, 'calendar');
    if (!_widgetOrder.contains('files')) _widgetOrder.add('files');
    
    if (savedVis != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(savedVis);
        _visibility = decoded.map((key, value) => MapEntry(key, value as bool));
      } catch (e) {}
    }

    _keyboardAuto = prefs.getBool(_kbAutoKey) ?? true;
    _keyboardOnStart = prefs.getBool(_kbStartKey) ?? true;
    
    notifyListeners();
  }

  Future<void> setKeyboardAuto(bool value) async {
    _keyboardAuto = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kbAutoKey, value);
  }

  Future<void> setKeyboardOnStart(bool value) async {
    _keyboardOnStart = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kbStartKey, value);
  }

  Future<void> toggleVisibility(String id) async {
    _visibility[id] = !(_visibility[id] ?? true);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_visKey, jsonEncode(_visibility));
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final String item = _widgetOrder.removeAt(oldIndex);
    _widgetOrder.insert(newIndex, item);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _widgetOrder);
  }
}
