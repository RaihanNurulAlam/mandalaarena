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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundImage: userProvider.profileImageUrl.isNotEmpty
                      ? NetworkImage(userProvider.profileImageUrl)
                          as ImageProvider
                      : const AssetImage('assets/default_avatar.png'),
                  radius: 50,
                ),
                const SizedBox(height: 16),
                Text(
                  userProvider.userName.isNotEmpty
                      ? userProvider.userName
                      : "Nama tidak tersedia",
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  userProvider.userEmail.isNotEmpty
                      ? userProvider.userEmail
                      : "Email tidak tersedia",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  userProvider.userPhone.isNotEmpty
                      ? userProvider.userPhone
                      : "Nomor telepon tidak tersedia",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePage(
                          userName: userProvider.userName,
                          userEmail: userProvider.userEmail,
                          profileImageUrl: userProvider
                              .profileImageUrl, // Kirim URL gambar lama
                          phoneNumber: userProvider.userPhone,
                        ),
                      ),
                    );

                    if (result != null && mounted) {
                      userProvider.updateUserData(
                        userName: result['userName'] ?? userProvider.userName,
                        userEmail:
                            result['userEmail'] ?? userProvider.userEmail,
                        profileImageUrl: result['profileImageUrl'] ??
                            userProvider.profileImageUrl,
                        userPhone:
                            result['phoneNumber'] ?? userProvider.userPhone,
                      );
                    }
                  },
                  child: const Text("Edit Profil"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text("Keluar"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
