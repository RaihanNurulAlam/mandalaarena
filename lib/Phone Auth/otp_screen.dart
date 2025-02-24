// ignore_for_file: unused_local_variable, use_build_context_synchronously, avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30), // ✅ Padding horizontal 30
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width > 500
                        ? 500
                        : double.infinity,
                    child: Column(
                      children: [
                        Image.asset(
                          "images/otpimage.jpg",
                          width: 180, // ✅ Ukuran gambar lebih besar
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
                          width: 200, // ✅ Kolom input lebih kecil
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
                                    if (kIsWeb &&
                                        widget.confirmationResult != null) {
                                      await widget.confirmationResult!
                                          .confirm(otpController.text);
                                    } else {
                                      final credential =
                                          PhoneAuthProvider.credential(
                                        verificationId: widget.verificationId,
                                        smsCode: otpController.text,
                                      );
                                      await FirebaseAuth.instance
                                          .signInWithCredential(credential);
                                    }

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => HomePage()),
                                    );
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
            ),
            // Tombol kembali dan bantuan
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
}
