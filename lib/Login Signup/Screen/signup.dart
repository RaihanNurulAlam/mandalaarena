// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/Login%20Signup/Widget/button.dart';
import 'package:mandalaarenaapp/pages/home_page.dart';

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
        name: nameController.text);

    // if string return is success, user has been created and navigate to next screen, otherwise show error.
    if (res == "success") {
      setState(() {
        isLoading = false;
      });

      // Ambil data pengguna setelah signup
      final String userName = nameController.text;
      final String userEmail = emailController.text;
      final String phoneNumber = phoneController.text; // Ambil nomor telepon
      final String profileImageUrl = "https://via.placeholder.com/150";

      // Ambil userId setelah signup
      final String userId = AuthMethod()
          .getUserId(); // Ambil userId dari Firebase Auth (gunakan cred.user!.uid)
      if (userId.isEmpty) {
        setState(() {
          isLoading = false;
        });
        showSnackBar(context, 'User ID is empty');
        return;
      }

      // Menyimpan data pengguna ke Firebase Firestore
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'name': userName,
          'email': userEmail,
          'phone': phoneNumber,
          'profileImageUrl': profileImageUrl,
          'uid': userId,
        });

        // Navigate to the next screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        showSnackBar(context, 'Error saving data to Firebase: ${e.toString()}');
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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          // Membungkus konten dengan SingleChildScrollView
          child: SizedBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: height / 2.8,
                  child: Image.asset('images/signup.jpeg'),
                ),
                TextFieldInput(
                  icon: Icons.person,
                  textEditingController: nameController,
                  hintText: 'Enter your name',
                  textInputType: TextInputType.text,
                ),
                TextFieldInput(
                  icon: Icons.email,
                  textEditingController: emailController,
                  hintText: 'Enter your email',
                  textInputType: TextInputType.text,
                ),
                TextFieldInput(
                  icon: Icons.lock,
                  textEditingController: passwordController,
                  hintText: 'Enter your password',
                  textInputType: TextInputType.text,
                  isPass: true,
                ),
                TextFieldInput(
                  icon: Icons.phone,
                  textEditingController: phoneController, // Nomor telepon
                  hintText: 'Enter your phone number',
                  textInputType: TextInputType.phone,
                ),
                MyButtons(onTap: signupUser, text: "Sign Up"),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        " Login",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
