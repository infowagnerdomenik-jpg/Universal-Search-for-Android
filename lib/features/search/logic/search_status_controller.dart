import 'package:flutter/foundation.dart';

class SearchStatusController extends ChangeNotifier {
  static final SearchStatusController _instance = SearchStatusController._internal();
  factory SearchStatusController() => _instance;
  SearchStatusController._internal();

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  final Map<String, int> _results = {};

  int get totalResults {
    int sum = 0;
    for (var count in _results.values) {
      sum += count;
    }
    return sum;
  }

  void startNewSearch() {
    _isSearching = true;
    _results.clear();
    notifyListeners();
  }

  void reportResults(String componentId, int count) {
    _results[componentId] = count;
    notifyListeners();
  }

  void finishSearch() {
    _isSearching = false;
    notifyListeners();
  }
}
