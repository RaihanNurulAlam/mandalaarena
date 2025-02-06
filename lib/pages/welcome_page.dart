// ignore_for_file: deprecated_member_use, library_private_types_in_public_api
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mandalaarenaapp/Login%20Signup/Screen/login.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool isExpanded = false;

  void _toggleMenu() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
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

                  // Tombol "Book Now"
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
                ],
              ),
            ),
          ),

          // Floating Social Media Button
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // WhatsApp
                Visibility(
                  visible: isExpanded,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: FloatingActionButton(
                      heroTag: "whatsapp",
                      onPressed: () =>
                          _launchURL('https://wa.me/6282117556907'),
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.phone, color: Colors.white),
                    ),
                  ),
                ),

                // Facebook
                Visibility(
                  visible: isExpanded,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: FloatingActionButton(
                      heroTag: "facebook",
                      onPressed: () =>
                          _launchURL('https://www.facebook.com/mandala.arena'),
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.facebook, color: Colors.white),
                    ),
                  ),
                ),

                // Instagram
                Visibility(
                  visible: isExpanded,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: FloatingActionButton(
                      heroTag: "instagram",
                      onPressed: () =>
                          _launchURL('https://www.instagram.com/mandalaarena'),
                      backgroundColor: Colors.purple,
                      child: const Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
                ),

                // Email
                Visibility(
                  visible: isExpanded,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: FloatingActionButton(
                      heroTag: "email",
                      onPressed: () =>
                          _launchURL('mailto:mandalaarena@gmail.com'),
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.email, color: Colors.white),
                    ),
                  ),
                ),

                // Tombol Utama (Menu)
                FloatingActionButton(
                  heroTag: "toggle",
                  onPressed: _toggleMenu,
                  backgroundColor: Colors.black,
                  child: Icon(isExpanded ? Icons.close : Icons.add_comment,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
