// ignore_for_file: unnecessary_import, use_super_parameters, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../pages/edit_profile_page.dart';
import '../pages/welcome_page.dart';
import '../pages/manage_booking_page.dart';
import '../provider/user_provider.dart';

class DrawerWidget extends StatelessWidget {
  const DrawerWidget({Key? key}) : super(key: key);

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
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userName = userProvider.userName;
    final userEmail = userProvider.userEmail;
    final profileImageUrl = userProvider.profileImageUrl;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Menu Navigasi',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(profileImageUrl.isNotEmpty
                          ? profileImageUrl
                          : "https://via.placeholder.com/150"),
                      radius: 25,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName.isNotEmpty ? userName : "Tamu",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                        Text(
                          userEmail.isNotEmpty
                              ? userEmail
                              : "Email tidak ditemukan",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.orange),
            title: const Text('Ubah Profil'),
            onTap: () async {
              await _syncUserData(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EditProfilePage(
                            userName: userProvider.userName,
                            userEmail: userProvider.userEmail,
                            profileImageUrl: userProvider.profileImageUrl,
                            phoneNumber: userProvider.userPhone,
                          )));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Keluar'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const WelcomePage()));
            },
          ),
          const Divider(),

          // Kelola Booking hanya untuk admin
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
              final isAdmin = userData['isAdmin'] ??
                  false; // Ambil nilai isAdmin, default false jika tidak ada

              debugPrint("Data pengguna: $userData");
              debugPrint("isAdmin: $isAdmin");

              if (isAdmin) {
                return ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Kelola Booking'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageBookingsPage(),
                      ),
                    );
                  },
                );
              } else {
                return const SizedBox.shrink(); // Sembunyikan jika bukan admin
              }
            },
          ),
        ],
      ),
    );
  }
}
