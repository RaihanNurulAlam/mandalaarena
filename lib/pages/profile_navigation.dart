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
  const ProfilePageNavigation({super.key});

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
          bool isMember = userData['member'] ?? false;
          Provider.of<UserProvider>(context, listen: false).setUserData(
            userId: user.uid, // Tambahkan userId dari Firebase Authentication
            userName: userData['name'] ?? '',
            userEmail: user.email ?? '',
            profileImageUrl: userData['profileImageUrl'] ?? '',
            userPhone: userData['phone'] ?? '',
            isMember: isMember,
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

  // Mendapatkan ukuran layar
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  return Scaffold(
    body: Center( // Pastikan semua elemen berada di tengah
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Pusatkan elemen vertikal
          children: [
            const SizedBox(height: 10),
            CircleAvatar(
              backgroundImage: NetworkImage(profileImageUrl.isNotEmpty
                  ? profileImageUrl
                  : "https://via.placeholder.com/150"),
              radius: screenWidth * 0.12, // Perkecil ukuran avatar
            ),
            const SizedBox(height: 8),
            Text(
              userName.isNotEmpty ? userName : "Tamu",
              style: TextStyle(
                fontSize: screenWidth * 0.05, // Perkecil ukuran font
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center, // Pastikan teks tetap di tengah
            ),
            const SizedBox(height: 3),
            Text(
              userEmail.isNotEmpty ? userEmail : "Email tidak ditemukan",
              style: TextStyle(
                fontSize: screenWidth * 0.035, // Perkecil ukuran font
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            _buildButton(context, 'Ubah Profil', Icons.edit, Colors.black, () async {
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
            _buildButton(context, 'Galeri', Icons.photo_library, Colors.black, () {
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
            _buildButton(context, 'Transaksi', Icons.payment, Colors.black, () {
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

                  final userData = snapshot.data!.data() as Map<String, dynamic>;
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
              _buildButton(context, 'Keluar', Icons.logout, Colors.black, () async {
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

  /// Fungsi untuk membuat tombol dengan ukuran lebih kecil
Widget _buildButton(BuildContext context, String title, IconData icon, Color color, VoidCallback onPressed) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 3), // Kurangi jarak antar tombol
    child: SizedBox(
      width: screenWidth * 0.4, // Perkecil lebar tombol
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white, size: screenWidth * 0.05), // Perkecil ikon
        label: Text(
          title,
          style: TextStyle(
            fontSize: screenWidth * 0.035, // Perkecil ukuran teks tombol
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015), // Sesuaikan padding agar lebih kecil
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