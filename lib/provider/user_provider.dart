import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _userName = '';
  String _userEmail = '';
  String _profileImageUrl = '';
  String _userPhone = '';

  // Getter untuk data pengguna
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get profileImageUrl => _profileImageUrl;
  String get userPhone => _userPhone;

  // Method untuk mengatur data pengguna saat pertama kali login atau data diubah
  void setUserData({
    required String userName,
    required String userEmail,
    required String profileImageUrl,
    required String userPhone,
  }) {
    _userName = userName;
    _userEmail = userEmail;
    _profileImageUrl = profileImageUrl;
    _userPhone = userPhone;
    notifyListeners();
  }

  // Method untuk memperbarui sebagian data pengguna
  void updateUserData({
    String? userName,
    String? userEmail,
    String? profileImageUrl,
    String? userPhone,
  }) {
    if (userName != null) _userName = userName;
    if (userEmail != null) _userEmail = userEmail;
    if (profileImageUrl != null) _profileImageUrl = profileImageUrl;
    if (userPhone != null) _userPhone = userPhone;
    notifyListeners();
  }
}
