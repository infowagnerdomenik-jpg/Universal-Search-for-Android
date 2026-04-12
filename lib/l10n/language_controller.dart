import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends ChangeNotifier {
  static final LanguageController _instance = LanguageController._internal();
  factory LanguageController() => _instance;
  LanguageController._internal();

  String _language = 'auto';
  String get language => _language;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('app_language') ?? 'auto';
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (_language == code) return;
    _language = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', code);
    notifyListeners();
  }
}
