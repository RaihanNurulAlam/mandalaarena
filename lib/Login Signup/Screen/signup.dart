// ignore_for_file: use_build_context_synchronously, unused_local_variable

// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/Login%20Signup/Widget/button.dart';
import 'package:mandalaarenaapp/pages/help_page.dart';
import 'package:mandalaarenaapp/pages/home_page.dart';
import 'package:mandalaarenaapp/pages/welcome_page.dart';
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
  final TextEditingController phoneController =
      TextEditingController(); // Controller untuk nomor telepon
  bool isLoading = false;
  bool isPasswordVisible = false;

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose(); // Dispose controller phone
  }

  void signupUser() async {
    // set is loading to true
    setState(() {
      isLoading = true;
    });

    // signup user using our authmethod
    String res = await AuthMethod().signupUser(
      email: emailController.text,
      password: passwordController.text,
      name: nameController.text,
      phone: phoneController.text,
    ); // signup user

    // if string return is success, user has been created and navigate to next screen, otherwise show error.
    if (res == "Berhasil") {
      setState(() {
        isLoading = false;
      });

      try {
        // Get the current user's UID after signup
        String userId = FirebaseAuth.instance.currentUser!.uid;

        // Create a new user document in Firestore with additional fields
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'name': nameController.text,
          'email': emailController.text,
          'phone': phoneController.text,
          'profileImageUrl': 'https://via.placeholder.com/150', // Default image
          'uid': userId,
          'points': 0, // Add the points field with default value 0
          'isAdmin': false, // Set isAdmin to false by default
          'member': false, // Set member to false by default
        });

        // Navigate to the HomePage after successful signup
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        showSnackBar(context, 'Gagal menyimpan ke firebase: ${e.toString()}');
      }
    } else {
      setState(() {
        isLoading = false;
      });
      // show error
      showSnackBar(context, res);
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: SizedBox(
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width > 500
                        ? 500
                        : double.infinity, // Batasi lebar di desktop
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Gambar Signup (diperkecil)
                        SizedBox(
                          height: height / 3.5, // Ukuran gambar diperkecil
                          child: Image.asset('images/signup.jpeg'),
                        ),
                        // Input Nama
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: TextFieldInput(
                            icon: Icons.person,
                            textEditingController: nameController,
                            hintText: 'Masukan nama anda',
                            textInputType: TextInputType.text,
                          ),
                        ),
                        const SizedBox(height: 3), // Jarak antar input
                        // Input Email
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: TextFieldInput(
                            icon: Icons.email,
                            textEditingController: emailController,
                            hintText: 'Masukan email anda',
                            textInputType: TextInputType.text,
                          ),
                        ),
                        const SizedBox(height: 3), // Jarak antar input
                        // Input Password
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: TextFieldInput(
                            icon: Icons.lock,
                            textEditingController: passwordController,
                            hintText: 'Masukan password anda',
                            textInputType: TextInputType.text,
                            isPass: !isPasswordVisible,
                          ),
                        ),
                        // Tombol "Tampilkan Password"
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
                        const SizedBox(height: 3), // Jarak antar input
                        // Input Nomor Telepon
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: TextFieldInput(
                            icon: Icons.phone,
                            textEditingController: phoneController,
                            hintText: 'Masukan no telepon anda',
                            textInputType: TextInputType.phone,
                          ),
                        ),
                        // const SizedBox(
                        //     height: 1), // Jarak sebelum tombol "Daftar"
                        // Tombol "Daftar"
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: MyButtons(onTap: signupUser, text: "Daftar"),
                        ),
                        // const SizedBox(
                        //     height: 1), // Jarak setelah tombol "Daftar"
                        // Teks "Sudah mempunyai akun?"
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
                        const SizedBox(height: 10), // Jarak bawah
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
