// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cubit/navigation_cubit.dart';

class DrawerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Menu Navigasi',
              style: TextStyle(color: Colors.white, fontSize: 24),
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
          Divider(), // Pemisah antara menu navigasi dan tombol media sosial
          ListTile(
            leading: Icon(Icons.facebook, color: Colors.blue),
            title: Text('Facebook'),
            onTap: () => _launchURL('https://www.facebook.com/mandala.arena'),
          ),
          ListTile(
            leading: Icon(Icons.camera_alt, color: Colors.purple),
            title: Text('Instagram'),
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
        mode: LaunchMode
            .externalApplication, // Pastikan menggunakan browser eksternal
      );
    } else {
      debugPrint('Could not launch $url');
    }
  }
}
