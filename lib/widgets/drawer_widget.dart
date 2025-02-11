// ignore_for_file: unnecessary_import, use_super_parameters, use_build_context_synchronously, unused_element

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart'; // Import provider
// import 'package:url_launcher/url_launcher.dart';
import '../cubit/navigation_cubit.dart';
import '../pages/edit_profile_page.dart';
import '../pages/welcome_page.dart';
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
          // Update data di UserProvider
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
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          userEmail.isNotEmpty
                              ? userEmail
                              : "Email tidak ditemukan",
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
          // _buildDrawerItem(
          //   context,
          //   icon: Icons.home,
          //   title: 'Beranda',
          //   navigationState: NavigationState.home,
          // ),
          // _buildDrawerItem(
          //   context,
          //   icon: Icons.photo_library,
          //   title: 'Galeri Aktivitas',
          //   navigationState: NavigationState.gallery,
          // ),
          // _buildDrawerItem(
          //   context,
          //   icon: Icons.article,
          //   title: 'Informasi Terkini',
          //   navigationState: NavigationState.information,
          // ),
          // _buildDrawerItem(
          //   context,
          //   icon: Icons.info,
          //   title: 'Tentang Aplikasi',
          //   navigationState: NavigationState.about,
          // ),
          // _buildDrawerItem(
          //   context,
          //   icon: Icons.payment,
          //   title: 'Checkout',
          //   navigationState: NavigationState.payment,
          // ),
          // const Divider(),
          // _buildDrawerItem(
          //   context,
          //   icon: Icons.sparring,
          //   title: 'Checkout',
          //   navigationState: NavigationState.sparring,
          // ),
          // const Divider(),
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
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Keluar'),
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
          // const Divider(),
          // ListTile(
          //   leading: const Icon(Icons.facebook, color: Colors.blue),
          //   title: const Text('Facebook'),
          //   onTap: () => _launchURL('https://www.facebook.com/mandala.arena'),
          // ),
          // ListTile(
          //   leading: const Icon(Icons.camera_alt, color: Colors.purple),
          //   title: const Text('Instagram'),
          //   onTap: () => _launchURL('https://www.instagram.com/mandalaarena'),
          // ),
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

  // void _launchURL(String url) async {
  //   final Uri uri = Uri.parse(url);
  //   if (await canLaunchUrl(uri)) {
  //     await launchUrl(uri, mode: LaunchMode.externalApplication);
  //   } else {
  //     debugPrint('Tidak dapat membuka URL $url');
  //   }
  // }
}
