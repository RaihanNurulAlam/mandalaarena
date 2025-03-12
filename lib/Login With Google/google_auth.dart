// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mandalaarenaapp/pages/admin_home_page.dart';
import 'package:mandalaarenaapp/pages/home_page.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:provider/provider.dart';

class FirebaseServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      await _saveUserToFirestore(userCredential.user);

      if (userCredential.user != null) {
        final cartProvider = Provider.of<Cart>(context, listen: false);
        await cartProvider.loadCart(userCredential.user!.uid);
        await _navigateUser(context, userCredential.user!.uid);
      }

      return userCredential.user;
    } catch (e) {
      print("Kesalahan Masuk Google: $e");
      return null;
    }
  }

  Future<void> _saveUserToFirestore(User? user) async {
    if (user != null) {
      String uid = user.uid;
      String email = user.email ?? '';
      String name = user.displayName ?? 'User Name';
      String phone = user.phoneNumber ?? '';

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'email': email,
          'isAdmin': false,
          'name': name,
          'phone': phone,
          'points': 0,
          'member': false, // Tambahkan field member dengan nilai false
        }).catchError((e) {
          print("Error menyimpan data ke Firestore: $e");
        });
      } else {
        // Jika pengguna sudah ada, pastikan field points dan member ada
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;

        if (data != null) {
          if (!data.containsKey('points')) {
            await _firestore.collection('users').doc(uid).update({
              'points': 0, // Jika field points belum ada, tambahkan
            }).catchError((e) {
              print("Error menambahkan field points: $e");
            });
          }

          if (!data.containsKey('member')) {
            await _firestore.collection('users').doc(uid).update({
              'member': false, // Jika field member belum ada, tambahkan
            }).catchError((e) {
              print("Error menambahkan field member: $e");
            });
          }
        }
      }
    }
  }

  Future<void> _navigateUser(BuildContext context, String uid) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(uid).get();

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      bool isAdmin = data['isAdmin'] ?? false;

      print("User role: ${isAdmin ? 'Admin' : 'User'}"); // Debugging log

      if (isAdmin) {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) => AdminHomePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) => HomePage()),
        );
      }
    } else {
      print("User document not found in Firestore");
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  googleSignOut() {}
}
