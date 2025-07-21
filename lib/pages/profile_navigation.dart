// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mandalaarenaapp/Login%20Signup/Screen/login.dart';
import 'package:mandalaarenaapp/pages/galery_page.dart';
import 'package:provider/provider.dart';
import '../pages/edit_profile_page.dart';
import '../pages/welcome_page.dart';
import '../pages/manage_booking_page.dart';
import '../pages/information_page.dart';
import '../pages/about_page.dart';
import '../pages/payment_page.dart';
import '../provider/user_provider.dart';

class ProfilePageNavigation extends StatefulWidget {
  const ProfilePageNavigation({super.key});

  @override
  State<ProfilePageNavigation> createState() => _ProfilePageNavigationState();
}

class _ProfilePageNavigationState extends State<ProfilePageNavigation> {
  // Fungsi _syncUserData tidak perlu diubah, biarkan seperti aslinya
  Future<void> _syncUserData(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userData = userDoc.data();
        if (userData != null) {
          bool isMember = userData['member'] ?? false;
          Provider.of<UserProvider>(context, listen: false).setUserData(
            userId: user.uid,
            userName: userData['name'] ?? '',
            userEmail: user.email ?? '',
            profileImageUrl: userData['profileImageUrl'] ?? '',
            userPhone: userData['phone'] ?? '',
            isMember: isMember,
            points: userData['points'] ?? 0,
          );
        }
      }
    } catch (e) {
      debugPrint('Kesalahan sinkronisasi data pengguna: $e');
    }
  }

  // Fungsi initState tidak perlu diubah
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncUserData(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Dapatkan status user saat ini dari Firebase Auth
    final user = FirebaseAuth.instance.currentUser;

    // 2. Periksa apakah user sudah login atau belum
    if (user == null) {
      // --- TAMPILAN JIKA PENGGUNA BELUM LOGIN ---
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_off_outlined,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                "Anda Belum Login",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Silakan login untuk mengakses profil Anda.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.login, color: Colors.white),
                label: const Text("Login Sekarang"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      );
    } else {
      // --- TAMPILAN JIKA PENGGUNA SUDAH LOGIN (Kode Asli Anda) ---
      final userProvider = Provider.of<UserProvider>(context);
      final userName = userProvider.userName;
      final userEmail = userProvider.userEmail;
      final profileImageUrl = userProvider.profileImageUrl;
      final screenWidth = MediaQuery.of(context).size.width;

      return Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                CircleAvatar(
                  backgroundImage: NetworkImage(profileImageUrl.isNotEmpty
                      ? profileImageUrl
                      : "https://via.placeholder.com/150"),
                  radius: screenWidth * 0.12,
                ),
                const SizedBox(height: 8),
                Text(
                  userName.isNotEmpty ? userName : "Pengguna",
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                Text(
                  userEmail.isNotEmpty ? userEmail : "Email tidak ditemukan",
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                _buildButton(context, 'Ubah Profil', Icons.edit, Colors.black,
                    () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(
                        userName: userProvider.userName,
                        userEmail: userProvider.userEmail,
                        profileImageUrl: userProvider.profileImageUrl,
                        phoneNumber: userProvider.userPhone,
                      ),
                    ),
                  );
                  if (result != null) {
                    _syncUserData(context);
                  }
                }),
                _buildButton(
                    context, 'Galeri', Icons.photo_library, Colors.black, () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => GalleryPage()));
                }),
                _buildButton(context, 'Artikel', Icons.info, Colors.black, () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => InformationPage()));
                }),
                _buildButton(context, 'Tentang', Icons.help, Colors.black, () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => AboutPage()));
                }),
                _buildButton(context, 'Transaksi', Icons.payment, Colors.black,
                    () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => PaymentPage()));
                }),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final isAdmin = userData['isAdmin'] ?? false;
                      if (isAdmin) {
                        return _buildButton(
                          context,
                          'Kelola Booking',
                          Icons.settings,
                          Colors.black,
                          () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ManageBookingsPage()));
                          },
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),
                _buildButton(context, 'Keluar', Icons.logout, Colors.black,
                    () async {
                  await FirebaseAuth.instance.signOut();
                  // Reset data di UserProvider
                  Provider.of<UserProvider>(context, listen: false)
                      .clearUserData();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WelcomePage()),
                    (route) => false,
                  );
                }),
              ],
            ),
          ),
        ),
      );
    }
  }

  // Fungsi _buildButton tidak perlu diubah
  Widget _buildButton(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onPressed) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: SizedBox(
        width: screenWidth * 0.4,
        child: ElevatedButton.icon(
          icon: Icon(icon, color: Colors.white, size: screenWidth * 0.05),
          label: Text(
            title,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
