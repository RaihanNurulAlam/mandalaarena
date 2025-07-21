// login_page.dart

// ignore_for_file: use_build_context_synchronously, avoid_print, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/Login%20Signup/Widget/button.dart';
import 'package:mandalaarenaapp/Login%20With%20Google/google_auth.dart';
import 'package:mandalaarenaapp/Password%20Forgot/forgot_password.dart';
import 'package:mandalaarenaapp/Phone%20Auth/phone_login.dart';
import 'package:mandalaarenaapp/pages/admin_home_page.dart';
import 'package:mandalaarenaapp/pages/home_page.dart';
import 'package:mandalaarenaapp/pages/help_page.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart';
import '../Services/authentication.dart';
import '../Widget/snackbar.dart';
import '../Widget/text_field.dart';
import 'signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  /// Fungsi untuk login menggunakan Email & Password.
  void loginUser() async {
    setState(() {
      isLoading = true;
    });

    String res = await AuthMethod().loginUser(
      email: emailController.text,
      password: passwordController.text,
    );

    if (res == "Berhasil") {
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          // 1. Pasang listener UserProvider untuk sinkronisasi data real-time.
          Provider.of<UserProvider>(context, listen: false)
              .listenToUserData(currentUser.uid);

          // 2. Muat data keranjang belanja.
          final cartProvider = Provider.of<Cart>(context, listen: false);
          await cartProvider.loadCart(currentUser.uid);

          // 3. Cek peran user (Admin/Bukan) untuk navigasi.
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

          bool isAdmin =
              (userDoc.data() as Map<String, dynamic>)['isAdmin'] ?? false;
          Widget targetPage = isAdmin ? AdminHomePage() : HomePage();

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => targetPage),
            (route) => false,
          );
        }
      } catch (e) {
        showSnackBar(context, "Terjadi kesalahan saat mengambil data: $e");
      }
    } else {
      showSnackBar(context, res);
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Fungsi untuk login menggunakan Google.
  void loginWithGoogle() async {
    setState(() {
      isLoading = true;
    });

    final user = await FirebaseServices().signInWithGoogle(context);

    if (user != null) {
      try {
        // 1. Pasang listener UserProvider.
        Provider.of<UserProvider>(context, listen: false)
            .listenToUserData(user.uid);

        // 2. Muat data keranjang.
        final cartProvider = Provider.of<Cart>(context, listen: false);
        await cartProvider.loadCart(user.uid);

        // 3. Cek peran user untuk navigasi.
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        bool isAdmin =
            (userDoc.data() as Map<String, dynamic>)['isAdmin'] ?? false;
        Widget targetPage = isAdmin ? AdminHomePage() : HomePage();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
          (route) => false,
        );
      } catch (e) {
        showSnackBar(context, "Terjadi kesalahan: $e");
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
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
                        child: Image.asset('images/login.jpg'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          children: [
                            TextFieldInput(
                              icon: Icons.person,
                              textEditingController: emailController,
                              hintText: 'Masukan email anda',
                              textInputType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 10),
                            TextFieldInput(
                              icon: Icons.lock,
                              textEditingController: passwordController,
                              hintText: 'Masukan password anda',
                              textInputType: TextInputType.visiblePassword,
                              isPass: !isPasswordVisible,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 55.0, left: 25.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const ForgotPassword(),
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
                        child: MyButtons(onTap: loginUser, text: "Masuk"),
                      ),
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.black26),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text("atau"),
                            ),
                            Expanded(
                              child: Divider(color: Colors.black26),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                onPressed: isLoading ? null : loginWithGoogle,
                                child: Image.network(
                                  "https://ouch-cdn2.icons8.com/VGHyfDgzIiyEwg3RIll1nYupfj653vnEPRLr0AeoJ8g/rs:fit:456:456/czM6Ly9pY29uczgu/b3VjaC1wcm9kLmFz/c2V0cy9wbmcvODg2/LzRjNzU2YThjLTQx/MjgtNGZlZS04MDNl/LTAwMTM0YzEwOTMy/Ny5wbmc.png",
                                  height: 32,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: PhoneAuthentication(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Tidak punya akun? "),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const SignupScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Daftar",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Tampilkan loading indicator di tengah layar jika isLoading true
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
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
