// profile_page.dart
// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/user_provider.dart';
import '../pages/edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userName = userProvider.userName;
    final userEmail = userProvider.userEmail;
    final profileImageUrl = userProvider.profileImageUrl;
    final phoneNumber = userProvider.userPhone;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(profileImageUrl.isNotEmpty
                  ? profileImageUrl
                  : "https://via.placeholder.com/150"),
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
              phoneNumber.isNotEmpty ? phoneNumber : "Nomor telepon tidak tersedia",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
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
              },
              child: const Text("Edit Profil"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Warna tombol logout
              ),
              child: const Text("Keluar"),
            ),
          ],
        ),
      ),
    );
  }
}
