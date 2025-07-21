// ignore_for_file: avoid_print, unnecessary_brace_in_string_interps

import 'dart:async';
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
  bool _isAdmin = false;

  StreamSubscription<DocumentSnapshot>? _userSubscription;

  String get userId => _userId;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get profileImageUrl => _profileImageUrl;
  String get userPhone => _userPhone;
  bool get isMember => _isMember;
  int get points => _points;
  DateTime? get memberUntil => _memberUntil;
  bool get isAdmin => _isAdmin;

  bool get isMembershipActive {
    if (!_isMember || _memberUntil == null) {
      return false;
    }
    return _memberUntil!.isAfter(DateTime.now());
  }

  void listenToUserData(String uid) {
    _userSubscription?.cancel();

    if (uid.isEmpty) {
      clearUserData();
      return;
    }

    print("--- Memasang Listener untuk User ID: $uid ---");

    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        print("===================================");
        print("🔥 Listener Firestore Menerima Data Baru 🔥");
        print("Data mentah: $data");

        _userId = uid;
        _isMember = data['member'] ?? false;
        _memberUntil = (data['memberUntil'] as Timestamp?)?.toDate();
        _isAdmin = data['isAdmin'] ?? false;

        print("✅ isMember di-set menjadi: $_isMember");
        print("✅ memberUntil di-set menjadi: $_memberUntil");
        print("💡 Status isMembershipActive: ${isMembershipActive}");
        print("===================================");

        _userName = data['name'] ?? 'No Name';
        _userEmail = data['email'] ?? 'No Email';
        _userPhone = data['phone'] ?? 'No Phone';
        _profileImageUrl = data['profileImageUrl'] ?? '';
        _points = data['points'] ?? 0;

        notifyListeners();
      } else {
        print("Dokumen user tidak ditemukan.");
      }
    }, onError: (error) {
      print("Error pada listener: $error");
    });
  }

  void clearUserData() {
    print("--- Membersihkan data user dan membatalkan listener ---");
    _userSubscription?.cancel();
    _userId = "";
    _userName = "";
    _userEmail = "";
    _profileImageUrl = "";
    _userPhone = "";
    _isMember = false;
    _points = 0;
    _memberUntil = null;
    _isAdmin = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  void setUserData({
    required String userId,
    required String userName,
    required String userEmail,
    required String profileImageUrl,
    required String userPhone,
    required bool isMember,
    required int points,
    required DateTime? memberUntil,
  }) {
    _userId = userId;
    _userName = userName;
    _userEmail = userEmail;
    _profileImageUrl = profileImageUrl;
    _userPhone = userPhone;
    _isMember = isMember;
    _points = points;
    _memberUntil = memberUntil;
    notifyListeners();
  }

  /// Mengambil data terbaru dari Firestore dan memperbarui provider.
  Future<void> fetchUserData(String uid) async {
    if (uid.isEmpty) {
      clearUserData();
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
        _isMember = data['member'] ?? false;
        _points = data['points'] ?? 0;
        _memberUntil = (data['memberUntil'] as Timestamp?)?.toDate();
      }
    } catch (e) {
      print("Gagal mengambil data user: $e");
      clearUserData();
    }
    notifyListeners();
  }

  /// Memperbarui status membership secara spesifik.
  void updateMembershipStatus(bool newIsMember, DateTime newMemberUntil) {
    _isMember = newIsMember;
    _memberUntil = newMemberUntil;
    notifyListeners();
  }

  /// Method untuk memperbarui sebagian data pengguna (profil).
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
    notifyListeners();
  }

  /// Memperbarui poin pengguna.
  void updateUserPoints(int newPoints) {
    _points = newPoints;
    notifyListeners();
    print("UserProvider: Poin diperbarui menjadi $_points");
  }
}
