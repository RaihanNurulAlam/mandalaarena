// ignore_for_file: use_build_context_synchronously, unused_local_variable

// import 'package:cloud_firestore/cloud_firestore.dart';
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

      // // Ambil data pengguna setelah signup
      // final String userName = nameController.text;
      // final String userEmail = emailController.text;
      // final String phoneNumber = phoneController.text; // Ambil nomor telepon
      // final String profileImageUrl = "https://via.placeholder.com/150";

      // // Ambil userId setelah signup
      // final String userId = AuthMethod()
      //     .getUserId(); // Ambil userId dari Firebase Auth (gunakan cred.user!.uid)
      // if (userId.isEmpty) {
      //   setState(() {
      //     isLoading = false;
      //   });
      //   showSnackBar(context, 'ID User kosong');
      //   return;
      // }

      // // Menyimpan data pengguna ke Firebase Firestore
      // try {
      //   await FirebaseFirestore.instance.collection('users').doc(userId).set({
      //     'name': userName,
      //     'email': userEmail,
      //     'phone': phoneNumber,
      //     'profileImageUrl': profileImageUrl,
      //     'uid': userId,
      //   });

      // Navigate to the next screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );
      // } catch (e) {
      //   setState(() {
      //     isLoading = false;
      //   });
      //   showSnackBar(context, 'Gagal menyimpan ke firebase: ${e.toString()}');
      // }
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
                      hintText: 'Masukan nama anda',
                      textInputType: TextInputType.text,
                    ),
                    TextFieldInput(
                      icon: Icons.email,
                      textEditingController: emailController,
                      hintText: 'Masukan email anda',
                      textInputType: TextInputType.text,
                    ),
                    TextFieldInput(
                      icon: Icons.lock,
                      textEditingController: passwordController,
                      hintText: 'Masukan password anda',
                      textInputType: TextInputType.text,
                      isPass: !isPasswordVisible,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(),
                        Padding(
                          padding: const EdgeInsets.only(right: 30.0),
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
                    TextFieldInput(
                      icon: Icons.phone,
                      textEditingController: phoneController,
                      hintText: 'Masukan no telepon anda',
                      textInputType: TextInputType.phone,
                    ),
                    MyButtons(onTap: signupUser, text: "Daftar"),
                    const SizedBox(height: 10),
                    Row(
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
                  ],
                ),
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
