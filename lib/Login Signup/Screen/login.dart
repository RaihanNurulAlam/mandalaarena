// ignore_for_file: avoid_print

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

  // Email and password auth method
  void loginUser() async {
    setState(() {
      isLoading = true;
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
          DocumentReference userRef = FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid);

          DocumentSnapshot userDoc = await userRef.get();

          if (userDoc.exists) {
            if (!userDoc.data().toString().contains('member')) {
              await userRef.update({'member': false});
              print("Field `member` berhasil ditambahkan ke Firestore.");
            }
            if (!userDoc.data().toString().contains('points')) {
              await userRef.update({'points': 0});
              print("Field `points` berhasil ditambahkan ke Firestore.");
            }
            bool isAdmin = userDoc.get('isAdmin') ?? false;
            bool isMember = userDoc.get('member') ?? false;
            Widget targetPage = isAdmin ? AdminHomePage() : HomePage();

            print("User is admin: $isAdmin");
            print("User is member: $isMember");
            print("Navigating to: ${targetPage.runtimeType}");

            final cartProvider = Provider.of<Cart>(context, listen: false);
            await cartProvider.loadCart(currentUser.uid);

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => targetPage),
              (route) => false,
            );

            final userData = userDoc.data() as Map<String, dynamic>;
            final String userName = userData['name'] ?? "Nama User";
            final String userEmail =
                userData['email'] ?? "Email tidak ditemukan";
            final String profileImageUrl = userData['profileImageUrl'] ??
                "https://via.placeholder.com/150";
            final String userPhone = userData['phone'] ?? "";
            final int userPoints = userData['points'] ?? 0;

            if (mounted) {
              Provider.of<UserProvider>(context, listen: false).setUserData(
                userId: currentUser.uid,
                userName: userName,
                userEmail: userEmail,
                profileImageUrl: profileImageUrl,
                userPhone: userPhone,
                isMember: isMember,
                points: userPoints,
              );
            }
          } else {
            showSnackBar(context, "Data pengguna tidak ditemukan.");
          }
        }
      } catch (e) {
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
            Center(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width > 500
                      ? 500
                      : double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment
                        .center, // Konten berada di tengah secara vertikal
                    crossAxisAlignment: CrossAxisAlignment
                        .center, // Konten berada di tengah secara horizontal
                    children: [
                      SizedBox(
                        height: height / 4, // Sesuaikan tinggi gambar
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          children: [
                            Expanded(
                              child:
                                  Container(height: 1, color: Colors.black26),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text("atau"),
                            ),
                            Expanded(
                              child:
                                  Container(height: 1, color: Colors.black26),
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
                                onPressed: () async {
                                  final user = await FirebaseServices()
                                      .signInWithGoogle(context);
                                  if (user != null) {
                                    final String userName =
                                        user.displayName ?? "Nama User";
                                    final String userEmail =
                                        user.email ?? "Email tidak ditemukan";
                                    final String profileImageUrl =
                                        user.photoURL ??
                                            "https://via.placeholder.com/150";
                                    final String userPhone = user.phoneNumber ??
                                        "Nomor telepon tidak ditemukan";

                                    DocumentReference userRef =
                                        FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(user.uid);
                                    DocumentSnapshot userDoc =
                                        await userRef.get();

                                    if (!userDoc.exists) {
                                      await userRef.set({
                                        'name': userName,
                                        'email': userEmail,
                                        'profileImageUrl': profileImageUrl,
                                        'phone': userPhone,
                                        'uid': user.uid,
                                        'points': 0,
                                        'isAdmin': false,
                                        'member': false,
                                      });
                                    }

                                    bool isMember =
                                        userDoc.get('member') ?? false;

                                    if (mounted) {
                                      Provider.of<UserProvider>(context,
                                              listen: false)
                                          .setUserData(
                                        userId: user.uid,
                                        userName: userName,
                                        userEmail: userEmail,
                                        profileImageUrl: profileImageUrl,
                                        userPhone: userPhone,
                                        isMember: isMember,
                                        points: userDoc.get('points') ?? 0,
                                      );

                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => HomePage(),
                                        ),
                                        (route) => false,
                                      );
                                    }
                                  }
                                },
                                child: Image.network(
                                  "https://ouch-cdn2.icons8.com/VGHyfDgzIiyEwg3RIll1nYupfj653vnEPRLr0AeoJ8g/rs:fit:456:456/czM6Ly9pY29uczgu/b3VjaC1wcm9kLmFz/c2V0cy9wbmcvODg2/LzRjNzU2YThjLTQx/MjgtNGZlZS04MDNl/LTAwMTM0YzEwOTMy/Ny5wbmc.png",
                                  height: 32,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: const PhoneAuthentication(),
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
            // Tombol kembali yang dinamis
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // Gunakan ini untuk kembali ke halaman sebelumnya
                  Navigator.pop(context);
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
}
