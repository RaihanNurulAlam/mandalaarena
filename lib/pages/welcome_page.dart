// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mandalaarenaapp/Login%20Signup/Screen/login.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

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
              'assets/1.jpg',
              alignment: Alignment.topCenter,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              fit: BoxFit.cover,
            ),
          ),
          // Konten dengan ScrollView
          SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 50),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  // Tombol "Mulai"
                  Align(
                    alignment: Alignment.center,
                    child: CupertinoButton(
                      color: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      borderRadius: BorderRadius.circular(50),
                      minSize: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Book Now!',
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
                  const SizedBox(height: 20),
                  // Social Media Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.phone,
                            color: Colors.green, size: 30),
                        onPressed: () =>
                            _launchURL('https://wa.me/6282117556907'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.facebook,
                            color: Colors.blue, size: 30),
                        onPressed: () => _launchURL(
                            'https://www.facebook.com/mandala.arena'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt,
                            color: Colors.purple, size: 30),
                        onPressed: () => _launchURL(
                            'https://www.instagram.com/mandalaarena'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.email,
                            color: Colors.red, size: 30),
                        onPressed: () =>
                            _launchURL('mailto:mandalaarena@gmail.com'),
                      ),
                    ],
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
