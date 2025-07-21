// signup.dart

// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/Login%20Signup/Widget/button.dart';
import 'package:mandalaarenaapp/pages/help_page.dart';
import 'package:mandalaarenaapp/pages/home_page.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart'; // <-- 1. TAMBAHKAN IMPORT
import 'package:provider/provider.dart'; // <-- 2. TAMBAHKAN IMPORT
import '../Services/authentication.dart';
import '../Widget/snackbar.dart';
import '../Widget/text_field.dart';
import 'login.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
  }

  void signupUser() async {
    setState(() {
      isLoading = true;
    });

    // Membuat user di Firebase Authentication
    String res = await AuthMethod().signupUser(
      email: emailController.text,
      password: passwordController.text,
      name: nameController.text,
      phone: phoneController.text,
    );

    if (res == "Berhasil") {
      try {
        String userId = FirebaseAuth.instance.currentUser!.uid;

        // --- PERUBAHAN DI SINI ---
        // Menambahkan field 'memberUntil' saat membuat user baru di Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'name': nameController.text,
          'email': emailController.text,
          'phone': phoneController.text,
          'profileImageUrl': 'https://via.placeholder.com/150',
          'uid': userId,
          'points': 0,
          'isAdmin': false,
          'member': false,
          'memberUntil': null, // <-- 3. TAMBAHKAN FIELD INI
        });

        // --- PERUBAHAN DI SINI ---
        // Panggil listener di UserProvider agar state aplikasi ter-update
        // dengan data pengguna yang baru daftar.
        Provider.of<UserProvider>(context, listen: false)
            .listenToUserData(userId); // <-- 4. TAMBAHKAN BARIS INI

        // Navigasi ke HomePage setelah semua proses selesai
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
          (route) => false,
        );
      } catch (e) {
        showSnackBar(context, 'Gagal menyimpan data: ${e.toString()}');
      } finally {
        // Pastikan loading indicator berhenti meskipun ada error
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } else {
      showSnackBar(context, res);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width > 500
                      ? 500
                      : double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: height / 4,
                        child: Image.asset('images/signup.jpeg'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: TextFieldInput(
                          icon: Icons.person,
                          textEditingController: nameController,
                          hintText: 'Masukan nama anda',
                          textInputType: TextInputType.text,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: TextFieldInput(
                          icon: Icons.email,
                          textEditingController: emailController,
                          hintText: 'Masukan email anda',
                          textInputType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: TextFieldInput(
                          icon: Icons.lock,
                          textEditingController: passwordController,
                          hintText: 'Masukan password anda',
                          textInputType: TextInputType.visiblePassword,
                          isPass: !isPasswordVisible,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 55),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                              child: Text(
                                isPasswordVisible
                                    ? "Sembunyikan Password"
                                    : "Tampilkan Password",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: TextFieldInput(
                          icon: Icons.phone,
                          textEditingController: phoneController,
                          hintText: 'Masukan no telepon anda',
                          textInputType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: MyButtons(onTap: signupUser, text: "Daftar"),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Sudah mempunyai akun?"),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                " Masuk",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
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
