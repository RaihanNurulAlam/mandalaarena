// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/Login%20Signup/Widget/button.dart';
import 'package:mandalaarenaapp/Login%20With%20Google/google_auth.dart';
import 'package:mandalaarenaapp/Password%20Forgot/forgot_password.dart';
import 'package:mandalaarenaapp/Phone%20Auth/phone_login.dart';
import 'package:mandalaarenaapp/pages/admin_home_page.dart';
import 'package:mandalaarenaapp/pages/home_page.dart';
import 'package:mandalaarenaapp/pages/welcome_page.dart';
import 'package:mandalaarenaapp/pages/help_page.dart';
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

  // Email and password auth method
  void loginUser() async {
    setState(() {
      isLoading = false;
    });

    String res = await AuthMethod().loginUser(
      email: emailController.text,
      password: passwordController.text,
    );

    setState(() {
      isLoading = false;
    });

    if (res == "Berhasil") {
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

          if (userDoc.exists) {
            bool isAdmin = userDoc.get('isAdmin') as bool;
            Widget targetPage = isAdmin ? AdminHomePage() : HomePage();

            // PINDAHKAN NAVIGATOR KE BAWAH
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => targetPage),
            );

            // Ambil data user SETELAH navigasi
            final userData = userDoc.data() as Map<String, dynamic>;
            final String userName = userData['name'] ?? "Nama User";
            final String userEmail =
                userData['email'] ?? "Email tidak ditemukan";
            final String profileImageUrl = userData['profileImageUrl'] ??
                "https://via.placeholder.com/150";
            final String userPhone =
                userData['phone'] ?? ""; // Ambil dari userDoc

            // Set user data in UserProvider setelah navigasi
            if (mounted) {
              Provider.of<UserProvider>(context, listen: false).setUserData(
                userName: userName,
                userEmail: userEmail,
                profileImageUrl: profileImageUrl,
                userPhone: userPhone,
              );
            }
          }
        } else {
          showSnackBar(context, "Data pengguna tidak ditemukan.");
        }
      } catch (e) {
        // Handle error Firestore
        print("Error Firestore: $e");
        showSnackBar(context, "Terjadi kesalahan. Silakan coba lagi.");
      }
    } else {
      showSnackBar(context, res);
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
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: height / 2.7,
                    child: Image.asset('images/login.jpg'),
                  ),
                  TextFieldInput(
                    icon: Icons.person,
                    textEditingController: emailController,
                    hintText: 'Masukan email anda',
                    textInputType: TextInputType.emailAddress,
                  ),
                  TextFieldInput(
                    icon: Icons.lock,
                    textEditingController: passwordController,
                    hintText: 'Masukan password anda',
                    textInputType: TextInputType.visiblePassword,
                    isPass: !isPasswordVisible,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const ForgotPassword(),
                      Spacer(),
                      Padding(
                        padding: EdgeInsets.only(
                            right: MediaQuery.of(context).size.width * 0.025),
                        child: TextButton(
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
                                color: Colors.blue),
                          ),
                        ),
                      ),
                    ],
                  ),
                  MyButtons(onTap: loginUser, text: "Masuk"),
                  Row(
                    children: [
                      Expanded(
                        child: Container(height: 1, color: Colors.black26),
                      ),
                      const Text("  atau  "),
                      Expanded(
                        child: Container(height: 1, color: Colors.black26),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey),
                      onPressed: () async {
                        final user =
                            await FirebaseServices().signInWithGoogle();
                        if (user != null) {
                          final String userName =
                              user.displayName ?? "Nama User";
                          final String userEmail =
                              user.email ?? "Email tidak ditemukan";
                          final String profileImageUrl = user.photoURL ??
                              "https://via.placeholder.com/150";
                          final String userPhone = user.phoneNumber ??
                              "Nomor telepon tidak ditemukan";

                          // Set user data in UserProvider
                          if (mounted) {
                            Provider.of<UserProvider>(context, listen: false)
                                .setUserData(
                              userName: userName,
                              userEmail: userEmail,
                              profileImageUrl: profileImageUrl,
                              userPhone: userPhone,
                            );

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomePage(),
                              ),
                            );
                          }
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Image.network(
                              "https://ouch-cdn2.icons8.com/VGHyfDgzIiyEwg3RIll1nYupfj653vnEPRLr0AeoJ8g/rs:fit:456:456/czM6Ly9pY29uczgu/b3VjaC1wcm9kLmFz/c2V0cy9wbmcvODg2/LzRjNzU2YThjLTQx/MjgtNGZlZS04MDNl/LTAwMTM0YzEwOTMy/Ny5wbmc.png",
                              height: 32,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Masuk dengan Google",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const PhoneAuthentication(),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 20),
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

Container socialIcon(image) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 32,
      vertical: 15,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFFedf0f8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.black45,
        width: 2,
      ),
    ),
    child: Image.network(
      image,
      height: 40,
    ),
  );
}
