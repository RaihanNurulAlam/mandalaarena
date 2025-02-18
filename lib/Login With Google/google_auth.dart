// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/foundation.dart'; // Tambahkan ini untuk deteksi platform

class FirebaseServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Instance Firestore

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Autentikasi Google untuk Web
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        UserCredential userCredential =
            await _auth.signInWithPopup(googleProvider);
        await _saveUserToFirestore(userCredential.user); // Simpan ke Firestore
        return userCredential.user;
      } else {
        // Autentikasi Google untuk Android & iOS
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;

          final OAuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          UserCredential userCredential =
              await _auth.signInWithCredential(credential);
          await _saveUserToFirestore(
              userCredential.user); // Simpan ke Firestore
          return userCredential.user;
        }
      }
    } catch (e) {
      print("Kesalahan Masuk Google: $e");
    }
    return null;
  }

  Future<void> _saveUserToFirestore(User? user) async {
    if (user != null) {
      // Mengambil data pengguna
      String uid = user.uid; // UID dari Firebase Authentication
      String email = user.email ?? '';
      String name = user.displayName ?? 'User Name';
      String phone =
          user.phoneNumber ?? ''; // Jika tidak ada nomor telepon, kosongkan

      // Menambahkan data pengguna ke Firestore
      await _firestore.collection('users').doc(uid).set({
        'uid': uid, // Menyimpan UID
        'email': email,
        'isAdmin': false,
        'name': name,
        'phone': phone, // Biarkan kosong jika tidak ada
      }).catchError((e) {
        print("Error menyimpan data ke Firestore: $e");
      });
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  googleSignOut() {}
}
