// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cubit/navigation_cubit.dart';
import '../pages/edit_profile_page.dart'; // Tambahkan halaman edit profil
import '../pages/welcome_page.dart'; // Tambahkan halaman welcome

class DrawerWidget extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String profileImageUrl;

  const DrawerWidget({
    required this.userName,
    required this.userEmail,
    required this.profileImageUrl,
  });

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
          'userName': userData?['name'] ?? userName,
          'profileImageUrl': userData?['profileImageUrl'] ?? profileImageUrl
        };
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
    return {'phoneNumber': '', 'userName': userName, 'profileImageUrl': profileImageUrl};
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Menu Navigasi',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(profileImageUrl),
                      radius: 25,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          userEmail,
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
                    userName: userData['userName']!,
                    userEmail: userEmail,
                    profileImageUrl: userData['profileImageUrl']!,
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
