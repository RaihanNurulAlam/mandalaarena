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
        title: Text(
          'KPM Corp',
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        height: MediaQuery.sizeOf(context).height,
        width: MediaQuery.sizeOf(context).width,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/minisoccer.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.darken,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat Datang di Aplikasi Mandala Arena',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
              Text(
                'Dirancang untuk memudahkan sewa lapang Mandala Arena',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: CupertinoButton(
                  color: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  borderRadius: BorderRadius.circular(50),
                  minSize: 0, // Agar ukuran minimal tombol tidak terlalu besar
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min, // Menyesuaikan ukuran dengan konten
                    children: const [
                      Text(
                        'Mulai',
                        style: TextStyle(
                          fontSize: 16, // Ukuran font yang lebih kecil
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        CupertinoIcons.arrow_right,
                        color: Colors.white,
                        size: 18, // Ukuran ikon lebih kecil
                      ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
