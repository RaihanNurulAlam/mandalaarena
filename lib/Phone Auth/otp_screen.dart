// ignore_for_file: unused_local_variable, use_build_context_synchronously, avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mandalaarenaapp/pages/home_page.dart';

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
        child: SingleChildScrollView(
          child: Column(
            children: [
              Image.asset("images/otpimage.jpg"),
              const SizedBox(height: 20),
              const Text(
                "Verifikasi OTP",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Masukkan kode OTP yang telah dikirim ke nomor Anda.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
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
                          if (kIsWeb && widget.confirmationResult != null) {
                            // Untuk Web
                            await widget.confirmationResult!
                                .confirm(otpController.text);
                          } else {
                            // Untuk Mobile (Android/iOS)
                            final credential = PhoneAuthProvider.credential(
                              verificationId: widget.verificationId,
                              smsCode: otpController.text,
                            );
                            await FirebaseAuth.instance
                                .signInWithCredential(credential);
                          }

                          // Berhasil, arahkan ke HomePage
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => HomePage()),
                          );
                        } catch (e) {
                          print("Error OTP: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    "Kode OTP salah atau sudah kedaluwarsa.")),
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
    );
  }
}
