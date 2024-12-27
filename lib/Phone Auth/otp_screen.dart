// ignore_for_file: unused_local_variable, use_build_context_synchronously, avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/pages/home_page.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;
  const OTPScreen({super.key, required this.verificationId});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  TextEditingController otpController = TextEditingController();
  // we have also add the circular profressIndicator during waiting time
  bool isLoadin = false;

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
                "OTP Verification",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "We need to register your phone number by using a one-time OTP code verification.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextField(
                  controller: otpController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "+6282117556907",
                    labelText: "Enter the Phone Number",
                  ),
                ),
              ),
              const SizedBox(height: 20),
              isLoadin
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () async {
                        setState(() {
                          isLoadin = true;
                        });
                        try {
                          final credential = PhoneAuthProvider.credential(
                            verificationId: widget.verificationId,
                            smsCode: otpController.text,
                          );
                          await FirebaseAuth.instance
                              .signInWithCredential(credential);
                          // Fetch user details after successful login
                          User? user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            final String userName =
                                user.displayName ?? "User Name";
                            final String userEmail =
                                user.email ?? "Email Not Found";
                            final String profileImageUrl = user.photoURL ??
                                "https://via.placeholder.com/150";

                            // Navigate to HomePage with the user's details
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomePage(),
                              ),
                            );
                          }
                        } catch (e) {
                          print(e);
                        }
                        setState(() {
                          isLoadin = false;
                        });
                      },
                      child: const Text(
                        "Verify OTP",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
              const SizedBox(height: 20), // Tambahan jarak jika perlu
            ],
          ),
        ),
      ),
    );
  }
}
