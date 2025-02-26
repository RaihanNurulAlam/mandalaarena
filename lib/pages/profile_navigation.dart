// ignore_for_file: unnecessary_import, use_super_parameters, use_build_context_synchronously, unused_element

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  const ProfilePageNavigation({Key? key}) : super(key: key);

  @override
  State<ProfilePageNavigation> createState() => _ProfilePageNavigationState();
}

class _ProfilePageNavigationState extends State<ProfilePageNavigation> {
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
          Provider.of<UserProvider>(context, listen: false).setUserData(
            userId: user.uid, // Tambahkan userId dari Firebase Authentication
            userName: userData['name'] ?? '',
            userEmail: user.email ?? '',
            profileImageUrl: userData['profileImageUrl'] ?? '',
            userPhone: userData['phone'] ?? '',
          );
        }
      }
    } catch (e) {
      debugPrint('Kesalahan sinkronisasi data pengguna: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncUserData(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userName = userProvider.userName;
    final userEmail = userProvider.userEmail;
    final profileImageUrl = userProvider.profileImageUrl;

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text(''),
      //   backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
      //   elevation: 0,
      // ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 5),
              CircleAvatar(
                backgroundImage: NetworkImage(profileImageUrl.isNotEmpty
                    ? profileImageUrl
                    : "https://via.placeholder.com/150"),
                radius: 50,
              ),
              const SizedBox(height: 10),
              Text(
                userName.isNotEmpty ? userName : "Tamu",
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                userEmail.isNotEmpty ? userEmail : "Email tidak ditemukan",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 10),
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
              _buildButton(context, 'Galeri', Icons.photo_library, Colors.black,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GalleryPage()),
                );
              }),
              _buildButton(context, 'Artikel', Icons.info, Colors.black, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InformationPage()),
                );
              }),
              _buildButton(context, 'Tentang', Icons.help, Colors.black, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutPage()),
                );
              }),
              _buildButton(context, 'Transaksi', Icons.payment, Colors.black,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PaymentPage()),
                );
              }),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    debugPrint("Error: ${snapshot.error}");
                    return const Text('Gagal memuat data pengguna');
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    debugPrint("Dokumen pengguna tidak ditemukan");
                    return const Text('Data pengguna tidak ditemukan');
                  }

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
                            builder: (context) => ManageBookingsPage(),
                          ),
                        );
                      },
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
              _buildButton(context, 'Keluar', Icons.logout, Colors.black,
                  () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomePage()),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onPressed) {
    return Container(
      // width: MediaQuery.of(context).size.width * 0.3, // Lebar tombol diperkecil
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: SizedBox(
        width: 180,
        child: ElevatedButton.icon(
          icon: Icon(icon, color: Colors.white),
          label: Text(title, style: const TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                color, // Warna background tombol diubah menjadi hitam
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
