// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/user_provider.dart';
import '../pages/edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    String userName = userProvider.userName;
    String userEmail = userProvider.userEmail;
    String profileImageUrl = userProvider.profileImageUrl;
    String phoneNumber = userProvider.userPhone;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                profileImageUrl.isNotEmpty
                    ? profileImageUrl
                    : "https://via.placeholder.com/150", // Placeholder jika foto kosong
              ),
              radius: 50,
            ),
            const SizedBox(height: 16),
            Text(
              userName.isNotEmpty ? userName : "Nama tidak tersedia",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              userEmail.isNotEmpty ? userEmail : "Email tidak tersedia",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              phoneNumber.isNotEmpty
                  ? phoneNumber
                  : "Nomor telepon tidak tersedia",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                // Navigasi ke halaman EditProfilePage
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(
                      userName: userName,
                      userEmail: userEmail,
                      profileImageUrl: profileImageUrl,
                      phoneNumber: phoneNumber,
                    ),
                  ),
                );

                // Perbarui profil jika ada perubahan
                if (result != null && mounted) {
                  setState(() {
                    userName = result['userName'] ?? userName;
                    userEmail = result['userEmail'] ?? userEmail;
                    profileImageUrl =
                        result['profileImageUrl'] ?? profileImageUrl;
                    phoneNumber = result['phoneNumber'] ?? phoneNumber;
                  });
                }
              },
              child: const Text("Edit Profil"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Warna tombol keluar
              ),
              child: const Text("Keluar"),
            ),
          ],
        ),
      ),
    );
  }
}
