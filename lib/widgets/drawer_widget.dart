// ignore_for_file: unnecessary_import, use_super_parameters, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:url_launcher/url_launcher.dart';
import '../cubit/navigation_cubit.dart';
import '../pages/edit_profile_page.dart'; // Tambahkan halaman edit profil
import '../pages/welcome_page.dart'; // Tambahkan halaman welcome

class DrawerWidget extends StatelessWidget {
  const DrawerWidget({Key? key}) : super(key: key);

  Future<Map<String, String>> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userData = userDoc.data();
        return {
          'phoneNumber': userData?['phone'] ?? '',
          'userName': userData?['name'] ?? '',
          'profileImageUrl': userData?['profileImageUrl'] ?? ''
        };
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
    return {'phoneNumber': '', 'userName': '', 'profileImageUrl': ''};
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data pengguna dari UserProvider
    final userProvider = Provider.of<UserProvider>(context);
    final userName = userProvider.userName;
    final userEmail = userProvider.userEmail;
    final profileImageUrl = userProvider.profileImageUrl;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
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
                          userName.isNotEmpty ? userName : "Guest",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          userEmail.isNotEmpty ? userEmail : "Email Not Found",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'Beranda',
            navigationState: NavigationState.home,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.photo_library,
            title: 'Galeri Aktivitas',
            navigationState: NavigationState.gallery,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.article,
            title: 'Informasi Terkini',
            navigationState: NavigationState.information,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.info,
            title: 'Tentang Aplikasi',
            navigationState: NavigationState.about,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.payment,
            title: 'Checkout',
            navigationState: NavigationState.payment,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.orange),
            title: const Text('Ubah Profil'),
            onTap: () async {
              final userData = await _fetchUserData();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(
                    userName: userData['userName']!.isNotEmpty
                        ? userData['userName']!
                        : userName,
                    userEmail: userEmail,
                    profileImageUrl: userData['profileImageUrl']!.isNotEmpty
                        ? userData['profileImageUrl']!
                        : profileImageUrl,
                    phoneNumber: userData['phoneNumber']!,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const WelcomePage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.facebook, color: Colors.blue),
            title: const Text('Facebook'),
            onTap: () => _launchURL('https://www.facebook.com/mandala.arena'),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.purple),
            title: const Text('Instagram'),
            onTap: () => _launchURL('https://www.instagram.com/mandalaarena'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required NavigationState navigationState,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        context.read<NavigationCubit>().navigateTo(navigationState);
        Navigator.pop(context);
      },
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      debugPrint('Could not launch $url');
    }
  }
}
