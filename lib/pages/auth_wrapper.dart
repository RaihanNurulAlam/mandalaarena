// lib/pages/auth_wrapper.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mandalaarenaapp/pages/admin_home_page.dart';
import 'package:mandalaarenaapp/pages/home_page.dart';
import 'package:mandalaarenaapp/pages/welcome_page.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder akan otomatis 'mendengarkan' perubahan status login/logout
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Menunggu koneksi
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Jika user sudah login (snapshot punya data)
        if (snapshot.hasData) {
          // Arahkan ke UserDataLoader untuk mengambil data sebelum menampilkan UI
          return UserDataLoader(userId: snapshot.data!.uid);
        }

        // 3. Jika user belum login
        return const WelcomePage();
      },
    );
  }
}

class UserDataLoader extends StatefulWidget {
  final String userId;
  const UserDataLoader({super.key, required this.userId});

  @override
  State<UserDataLoader> createState() => _UserDataLoaderState();
}

class _UserDataLoaderState extends State<UserDataLoader> {
  @override
  void initState() {
    super.initState();
    _loadAllUserDataAndNavigate();
  }

  Future<void> _loadAllUserDataAndNavigate() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final cartProvider = Provider.of<Cart>(context, listen: false);

      // 1. Ambil data dokumen user dari Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      // Jika dokumen tidak ada, handle error (misal: logout)
      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        // Navigasi kembali ke welcome page jika data user tidak ditemukan
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
          (route) => false,
        );
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // 2. Set data ke UserProvider (mirip seperti di ProfileSlider)
      userProvider.setUserData(
        userId: widget.userId,
        userName: userData['name'] ?? '',
        userEmail: userData['email'] ?? '', // Ambil dari firestore atau auth
        profileImageUrl: userData['profileImageUrl'] ?? '',
        userPhone: userData['phone'] ?? '',
        isMember: userData['isMember'] ?? false,
        points: userData['points'] ?? 0,
        memberUntil: (userData['memberUntil'] as Timestamp?)?.toDate(),
        membershipType: userData['membershipType'],
      );

      // 3. Load data keranjang (cart)
      await cartProvider.loadCart(widget.userId);

      // 4. Cek apakah user adalah admin
      bool isAdmin = userData['isAdmin'] ?? false;

      // 5. Tentukan halaman tujuan
      Widget targetPage = isAdmin ? AdminHomePage() : HomePage();

      // 6. Navigasi ke halaman yang sesuai setelah semua data siap
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => targetPage),
        (route) => false,
      );
    } catch (e) {
      // Jika terjadi error, logout dan kembali ke halaman welcome
      debugPrint("Error saat memuat data pengguna: $e");
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Selama proses loading data, tampilkan loading indicator
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Memuat data Anda..."),
          ],
        ),
      ),
    );
  }
}
