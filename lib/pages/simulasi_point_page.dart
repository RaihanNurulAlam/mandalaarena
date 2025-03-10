// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';

class SimulasiTransactionHistoryPointPage extends StatelessWidget {
  const SimulasiTransactionHistoryPointPage({super.key});

  // Fungsi untuk simulasi penambahan poin
  Future<void> simulateAddPoints(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    // Simulasi data transaksi poin
    final pointsData = {
      'userId': userId,
      'points': 10, // Poin yang diperoleh
      'description': 'Poin dari simulasi pembayaran',
      'type': 'earned', // Tipe transaksi
      'timestamp': FieldValue.serverTimestamp(), // Waktu transaksi
    };

    // Simpan data ke Firestore
    await FirebaseFirestore.instance.collection('points').add(pointsData);

    // Tampilkan pesan sukses
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Poin berhasil ditambahkan (Simulasi)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi Poin'),
        actions: [
          // Tombol untuk simulasi penambahan poin
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () => simulateAddPoints(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('points')
            .where('userId', isEqualTo: userId) // Filter berdasarkan userId
            .orderBy('timestamp',
                descending: true) // Urutkan berdasarkan timestamp
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada transaksi poin.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final transactions = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final data = transactions[index].data() as Map<String, dynamic>;
              final description = data['description'];
              final points = data['points'];
              final timestamp = (data['timestamp'] as Timestamp).toDate();
              final type = data['type']; // 'earned' atau 'redeemed'

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Icon(
                    type == 'earned' ? Icons.add_circle : Icons.remove_circle,
                    color: type == 'earned' ? Colors.green : Colors.red,
                    size: 40,
                  ),
                  title: Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${points > 0 ? '+' : ''}$points Poin',
                    style: TextStyle(
                      fontSize: 14,
                      color: points > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  trailing: Text(
                    '${timestamp.day}/${timestamp.month}/${timestamp.year}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
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
