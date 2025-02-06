// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mandalaarenaapp/Phone%20Auth/otp_screen.dart';

class PhoneAuthentication extends StatefulWidget {
  const PhoneAuthentication({super.key});

  @override
  State<PhoneAuthentication> createState() => _PhoneAuthenticationState();
}

class _PhoneAuthenticationState extends State<PhoneAuthentication> {
  TextEditingController phoneController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        onPressed: () {
          myDialogBox(context);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Image.network(
                "https://static.vecteezy.com/system/resources/thumbnails/010/829/986/small/phone-icon-in-trendy-flat-style-free-png.png",
                height: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Masuk dengan No Telepon",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }

  void myDialogBox(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(),
                    const Text(
                      "Autentikasi Telepon",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "+6281234567890",
                    labelText: "Masukkan No Telepon",
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
                          String phoneNumber = phoneController.text.trim();
                          if (!phoneNumber.startsWith("+")) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Gunakan format internasional, contoh: +6281234567890"),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isLoading = true;
                          });

                          try {
                            if (kIsWeb) {
                              ConfirmationResult confirmationResult =
                                  await FirebaseAuth.instance
                                      .signInWithPhoneNumber(phoneNumber);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OTPScreen(
                                    verificationId: phoneNumber,
                                    confirmationResult: confirmationResult,
                                  ),
                                ),
                              );
                            } else {
                              await FirebaseAuth.instance.verifyPhoneNumber(
                                phoneNumber: phoneNumber,
                                verificationCompleted: (phoneAuthCredential) {},
                                verificationFailed: (error) {
                                  print("Error: $error");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "Gagal mengirim OTP: ${error.message}")),
                                  );
                                },
                                codeSent:
                                    (verificationId, forceResendingToken) {
                                  setState(() {
                                    isLoading = false;
                                  });

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OTPScreen(
                                        verificationId: verificationId,
                                        confirmationResult: null,
                                      ),
                                    ),
                                  );
                                },
                                codeAutoRetrievalTimeout: (verificationId) {},
                              );
                            }
                          } catch (e) {
                            print("Error OTP: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Gagal mengirim OTP: $e")),
                            );
                          }

                          setState(() {
                            isLoading = false;
                          });
                        },
                        child: const Text(
                          "Kirim Kode",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}
