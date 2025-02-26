// ignore_for_file: avoid_print, curly_braces_in_flow_control_structures, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';

class PointsPage extends StatelessWidget {
  const PointsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.userId;

    return Scaffold(
      appBar: AppBar(
        title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: const Text('Poin Anda')),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionHistoryPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData ||
              snapshot.data == null ||
              !snapshot.data!.exists) {
            return const Center(child: Text('Data tidak ditemukan.'));
          }

          Map<String, dynamic>? userData =
              snapshot.data?.data() as Map<String, dynamic>?;
          int points = userData?['points'] ?? 0;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Total Poin: $points',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    // Banner Penukaran 100 Poin
                    Card(
                      elevation: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                                'assets/minisoccer.jpg'), // Gambar lapangan
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.5),
                              BlendMode.darken,
                            ),
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            'Tukar 100 Poin - Gratis 1 Jam',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: ElevatedButton.icon(
                            icon: const Icon(Icons.card_giftcard,
                                color: Colors.white),
                            label: const Text('Tukar',
                                style: TextStyle(color: Colors.white)),
                            onPressed: points >= 100
                                ? () => redeemPoints(context, userId, 100,
                                    'Gratis 1 Jam', 'assets/minisoccer.jpg')
                                : () => showInsufficientPointsDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Banner Penukaran 30 Poin
                    Card(
                      elevation: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image:
                                AssetImage('assets/coffee.jpg'), // Gambar kopi
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.5),
                              BlendMode.darken,
                            ),
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            'Tukar 30 Poin - Voucher Kopi',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: ElevatedButton.icon(
                            icon: const Icon(Icons.card_giftcard,
                                color: Colors.white),
                            label: const Text('Tukar',
                                style: TextStyle(color: Colors.white)),
                            onPressed: points >= 30
                                ? () => redeemPoints(context, userId, 30,
                                    'Voucher Kopi', 'assets/coffee.jpg')
                                : () => showInsufficientPointsDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi Poin'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('points')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada transaksi poin.'));
          }
          var transactions = snapshot.data!.docs;
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              var data = transactions[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['description']),
                subtitle: Text(data['timestamp'].toDate().toString()),
                trailing: Text(
                  '${data['points'] > 0 ? '+' : ''}${data['points']} Poin',
                  style: TextStyle(
                    color: data['points'] > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> redeemPoints(BuildContext context, String userId, int cost,
    String reward, String imageUrl) async {
  try {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final userDoc = await userRef.get();
    int currentPoints = userDoc.data()?['points'] ?? 0;

    if (currentPoints >= cost) {
      await userRef.update({'points': currentPoints - cost});
      await FirebaseFirestore.instance.collection('points').add({
        'userId': userId,
        'points': -cost,
        'description': 'Menukar $reward',
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl, // Tambahkan URL gambar
        'rewardDetails': reward, // Tambahkan detail reward
        'status': 'Berhasil', // Tambahkan status
      });
      print('Transaksi berhasil disimpan ke Firestore'); // Logging
      showSuccessDialog(context);
    } else {
      print('Poin tidak cukup'); // Logging
      showInsufficientPointsDialog(context);
    }
  } catch (e) {
    print('Terjadi kesalahan saat menukarkan poin: $e'); // Logging
  }
}

void showInsufficientPointsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Poin Tidak Cukup'),
      content: const Text(
          'Anda tidak memiliki cukup poin untuk melakukan penukaran.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

void showSuccessDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Penukaran Berhasil'),
      content: const Text('Penukaran poin Anda berhasil!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
