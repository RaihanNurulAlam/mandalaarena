// google_auth.dart

// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Class ini bertanggung jawab untuk semua layanan yang terkait dengan
/// otentikasi Firebase, khususnya untuk Google Sign-In.
class FirebaseServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Melakukan proses Sign In dengan Google.
  /// Jika berhasil, akan menyimpan data user ke Firestore (jika user baru)
  /// dan mengembalikan objek User. Jika gagal, mengembalikan null.
  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      UserCredential userCredential;

      // Proses otentikasi untuk Web atau Mobile
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null; // User membatalkan login

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      // Pastikan data pengguna tersimpan di Firestore setelah login
      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!);
      }

      // Kembalikan objek User agar bisa digunakan di UI
      return userCredential.user;
    } catch (e) {
      print("Kesalahan Masuk Google: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal masuk dengan Google: $e")),
      );
      return null;
    }
  }

  /// Menyimpan data pengguna ke Firestore jika dokumen belum ada.
  /// Memastikan semua field default (termasuk member dan memberUntil) ada.
  Future<void> _saveUserToFirestore(User user) async {
    DocumentReference userDocRef = _firestore.collection('users').doc(user.uid);
    DocumentSnapshot userDoc = await userDocRef.get();

    // Hanya buat dokumen baru jika benar-benar belum ada
    if (!userDoc.exists) {
      print("User Google baru terdeteksi, menyimpan ke Firestore...");
      await userDocRef.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'name': user.displayName ?? 'User Tanpa Nama',
        'phone': user.phoneNumber ?? '',
        'profileImageUrl': user.photoURL ?? 'https://via.placeholder.com/150',
        'isAdmin': false,
        'points': 0,
        'isMember': false,
        'memberUntil': null,
      });
    }
  }

  /// Fungsi untuk logout dari Google dan Firebase.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      print("User berhasil logout.");
    } catch (e) {
      print("Error saat sign out: $e");
    }
  }
}
