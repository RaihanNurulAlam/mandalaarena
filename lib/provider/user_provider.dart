import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _userId = "";
  String _userName = "";
  String _userEmail = "";
  String _profileImageUrl = "";
  String _userPhone = "";
  bool _isMember = false;
  int _points = 0;

  String get userId => _userId;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get profileImageUrl => _profileImageUrl;
  String get userPhone => _userPhone;
  bool get isMember => _isMember;
  int get points => _points;

  // Method untuk mengatur data pengguna saat login
  void setUserData({
    required String userId,
    required String userName,
    required String userEmail,
    required String profileImageUrl,
    required String userPhone,
    required bool isMember,
    required int points,
  }) {
    _userId = userId;
    _userName = userName;
    _userEmail = userEmail;
    _profileImageUrl = profileImageUrl;
    _userPhone = userPhone;
    _isMember = isMember;
    _points = points;
    notifyListeners();
  }

  // Method untuk memperbarui sebagian data pengguna
  void updateUserData({
    required String userName,
    required String userEmail,
    required String profileImageUrl,
    required String userPhone,
  }) {
    _userName = userName;
    _userEmail = userEmail;
    _profileImageUrl = profileImageUrl;
    _userPhone = userPhone;
    // _isMember tidak diubah di sini karena tidak termasuk dalam parameter
    notifyListeners();
  }

  /// Membersihkan data pengguna saat logout.
  /// Method ini akan mereset semua state ke nilai default.
  void clearUserData() {
    _userId = "";
    _userName = "";
    _userEmail = "";
    _profileImageUrl = "";
    _userPhone = "";
    _isMember = false;
    _points = 0;
    notifyListeners();
  }
}
