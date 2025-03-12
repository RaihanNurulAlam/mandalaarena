import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _userId = ""; // Tambahkan userId
  String _userName = "";
  String _userEmail = "";
  String _profileImageUrl = "";
  String _userPhone = "";
  bool _isMember = false;

  String get userId => _userId;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get profileImageUrl => _profileImageUrl;
  String get userPhone => _userPhone;
  bool get isMember => _isMember;

  // Method untuk mengatur data pengguna saat login
  void setUserData({
    required String userId, // Tambahkan userId
    required String userName,
    required String userEmail,
    required String profileImageUrl,
    required String userPhone,
    required bool isMember,
  }) {
    _userId = userId; // Simpan userId
    _userName = userName;
    _userEmail = userEmail;
    _profileImageUrl = profileImageUrl;
    _userPhone = userPhone;
    _isMember = isMember;
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
    _isMember = isMember;
    notifyListeners();
  }
}
