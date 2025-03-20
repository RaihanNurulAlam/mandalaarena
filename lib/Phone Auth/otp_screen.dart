// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mandalaarenaapp/pages/admin_home_page.dart';
import 'package:mandalaarenaapp/pages/home_page.dart';
import 'package:mandalaarenaapp/pages/welcome_page.dart';
import 'package:mandalaarenaapp/pages/help_page.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final ConfirmationResult? confirmationResult;

  const OTPScreen(
      {super.key, required this.verificationId, this.confirmationResult});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  TextEditingController otpController = TextEditingController();
  bool isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width > 500 ? 500 : double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Konten di tengah vertikal
                    crossAxisAlignment: CrossAxisAlignment.center, // Konten di tengah horizontal
                    children: [
                      Image.asset(
                        "images/otpimage.jpg",
                        width: 180,
                        height: 180,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Verifikasi OTP",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Masukkan kode OTP yang telah dikirim ke nomor Anda.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 200,
                        child: TextField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: "Masukkan Kode OTP",
                            labelText: "Kode OTP",
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () async {
                                setState(() {
                                  isLoading = true;
                                });

                                try {
                                  UserCredential userCredential;
                                  if (kIsWeb &&
                                      widget.confirmationResult != null) {
                                    userCredential = await widget
                                        .confirmationResult!
                                        .confirm(otpController.text);
                                  } else {
                                    final credential =
                                        PhoneAuthProvider.credential(
                                      verificationId: widget.verificationId,
                                      smsCode: otpController.text,
                                    );
                                    userCredential = await _auth
                                        .signInWithCredential(credential);
                                  }

                                  User? user = userCredential.user;
                                  if (user != null) {
                                    await _saveUserToFirestore(user);
                                    await _navigateUser(user.uid);
                                  }
                                } catch (e) {
                                  print("Error OTP: $e");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Kode OTP salah atau sudah kedaluwarsa."),
                                    ),
                                  );
                                }

                                setState(() {
                                  isLoading = false;
                                });
                              },
                              child: const Text(
                                "Verifikasi Kode OTP",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white),
                              ),
                            ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            // Tombol kembali ke WelcomePage
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WelcomePage(),
                    ),
                  );
                },
              ),
            ),
            // Tombol bantuan (HelpPage)
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.help),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveUserToFirestore(User user) async {
    String uid = user.uid;
    String phone = user.phoneNumber ?? '';

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      // Jika pengguna baru, tambahkan field points = 0
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'phone': phone,
        'isAdmin': false, // Default pengguna bukan admin
        'points': 0, // Menambahkan field points dengan nilai awal 0
        'member': false,
      }).catchError((e) {
        print("Error menyimpan data ke Firestore: $e");
      });
    } else {
      // Jika pengguna sudah ada, pastikan field points ada
      Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;

      if (data != null && !data.containsKey('points')) {
        await _firestore.collection('users').doc(uid).update({
          'points': 0, // Jika field points belum ada, tambahkan
        }).catchError((e) {
          print("Error menambahkan field points: $e");
        });
      }

      if (data!.containsKey('member')) {
        await _firestore.collection('users').doc(uid).update({
          'member': false, // Jika field member belum ada, tambahkan
        }).catchError((e) {
          print("Error menambahkan field member: $e");
        });
      }
    }
  }

  Future<void> _navigateUser(String uid) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(uid).get();

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      bool isAdmin = data['isAdmin'] ?? false;

      print("User role: ${isAdmin ? 'Admin' : 'User'}");

      if (isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminHomePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } else {
      print("User document not found in Firestore");
    }
  }
}