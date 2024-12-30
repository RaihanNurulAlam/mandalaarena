import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoveProvider with ChangeNotifier {
  final Map<String, bool> _lovedItems = {};

  LoveProvider() {
    _loadLovedItems();
  }

  bool isLoved(String itemId) {
    return _lovedItems[itemId] ?? false;
  }

  void toggleLove(String itemId) async {
    _lovedItems[itemId] = !(_lovedItems[itemId] ?? false);
    notifyListeners();
    await _saveLovedItems();
  }

  Future<void> _loadLovedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final lovedData = prefs.getStringList('lovedItems') ?? [];
    for (var item in lovedData) {
      _lovedItems[item] = true;
    }
    notifyListeners();
  }

  Future<void> _saveLovedItems() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('lovedItems', _lovedItems.keys
        .where((key) => _lovedItems[key] == true)
        .toList());
  }
}
