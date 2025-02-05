// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/Login%20Signup/Screen/login.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/welcome.jpg',
              alignment: Alignment.topCenter,
              width: MediaQuery.of(context).size.width, // Sesuaikan lebar layar
              height:
                  MediaQuery.of(context).size.height, // Sesuaikan tinggi layar
              fit: BoxFit
                  .cover, // Pastikan gambar menutupi layar tanpa terpotong
            ),
          ),
          // Overlay Gradient (Opsional)
          // Container(
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //       begin: Alignment.topCenter,
          //       end: Alignment.bottomCenter,
          //       colors: [
          //         Colors.black.withOpacity(0.2),
          //         Colors.black.withOpacity(0.6),
          //       ],
          //     ),
          //   ),
          // ),
          // Konten dengan ScrollView
          SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context)
                  .size
                  .height, // Pastikan scroll bisa bekerja
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 50),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50), // Spasi agar bisa discroll

                  // Tombol "Mulai" di tengah bawah
                  Align(
                    alignment:
                        Alignment.center, // Pastikan tombol berada di tengah
                    child: CupertinoButton(
                      color: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12), // Perbesar padding tombol
                      borderRadius: BorderRadius.circular(50),
                      minSize: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Mulai',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            CupertinoIcons.arrow_right,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
