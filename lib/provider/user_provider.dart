// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _userId = "";
  String _userName = "";
  String _userEmail = "";
  String _profileImageUrl = "";
  String _userPhone = "";
  bool _isMember = false;
  int _points = 0;
  DateTime? _memberUntil;

  String get userId => _userId;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get profileImageUrl => _profileImageUrl;
  String get userPhone => _userPhone;
  bool get isMember => _isMember;
  int get points => _points;
  DateTime? get memberUntil => _memberUntil;

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

  bool get isMembershipActive {
    if (!_isMember || _memberUntil == null) {
      return false;
    }
    // Cek apakah tanggal 'memberUntil' masih di masa depan
    return _memberUntil!.isAfter(DateTime.now());
  }

  Future<void> fetchUserData(String uid) async {
    if (uid.isEmpty) {
      clearUserData(); // Panggil clearUserData untuk mereset semua
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _userId = uid;
        _userName = data['name'] ?? 'No Name';
        _userEmail = data['email'] ?? 'No Email';
        _userPhone = data['phone'] ?? 'No Phone';
        _isMember = data['isMember'] ?? false;
        _points = data['points'] ?? 0;
        // 4. MODIFIKASI: Ambil data 'memberUntil' dari Firestore
        _memberUntil = (data['memberUntil'] as Timestamp?)?.toDate();
      }
    } catch (e) {
      print("Gagal mengambil data user: $e");
      clearUserData();
    }
    notifyListeners();
  }

  void updateMembershipStatus(bool newIsMember, DateTime newMemberUntil) {
    _isMember = newIsMember;
    _memberUntil = newMemberUntil;
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

  void updateUserPoints(int newPoints) {
    _points = newPoints;
    notifyListeners(); // <-- Kunci utama agar UI bisa refresh
    print("UserProvider: Poin diperbarui menjadi $_points");
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
    _memberUntil = null;
    notifyListeners();
  }
}
