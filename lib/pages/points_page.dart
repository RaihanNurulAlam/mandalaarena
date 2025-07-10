// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously

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
    final points = userProvider.points;

    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Poin Anda'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    'Total Poin: $points', // Gunakan data poin dari provider
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // Banner Penukaran 10 Poin
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Card(
                      elevation: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/minisoccer.jpg'),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.5),
                              BlendMode.darken,
                            ),
                          ),
                        ),
                        child: ListTile(
                          title: const Text(
                            'Tukar 10 Poin - Gratis 1 Jam',
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
                            // Logika penukaran tetap sama
                            onPressed: points >= 10
                                ? () => showRedeemConfirmationDialog(
                                      context,
                                      userId,
                                      10,
                                      'Gratis 1 Jam',
                                      'assets/minisoccer.jpg',
                                    )
                                : () => showInsufficientPointsDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Banner Penukaran 3 Poin
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Card(
                      elevation: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/coffee.jpg'),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.5),
                              BlendMode.darken,
                            ),
                          ),
                        ),
                        child: ListTile(
                          title: const Text(
                            'Tukar 3 Poin - Voucher Kopi',
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
                            onPressed: points >= 3
                                ? () => showRedeemConfirmationDialog(
                                    context,
                                    userId,
                                    3,
                                    'Voucher Kopi',
                                    'assets/coffee.jpg')
                                : () => showInsufficientPointsDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  late Stream<QuerySnapshot> _transactionsStream;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    _transactionsStream = FirebaseFirestore.instance
        .collection('points')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi Poin'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _transactionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada transaksi poin.'));
          }

          var transactions = snapshot.data!.docs;
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              var data = transactions[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: data['imageUrl'] != null
                      ? Image.asset(
                          data['imageUrl'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : null,
                  title: Text(data['description']),
                  subtitle: Text(
                    _formatDate(data['timestamp'].toDate()),
                  ),
                  trailing: Text(
                    '${data['points']} Poin',
                    style: TextStyle(
                      color: data['points'] > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

Future<void> redeemPoints(BuildContext context, String userId, int cost,
    String reward, String imageUrl) async {
  try {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    // Gunakan transaction untuk operasi atomic
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) {
        throw Exception("User tidak ditemukan");
      }

      int currentPoints = userDoc.data()?['points'] ?? 0;
      if (currentPoints < cost) {
        showInsufficientPointsDialog(context);
        throw Exception("Poin tidak cukup");
      }

      // Update poin user
      transaction.update(userRef, {'points': currentPoints - cost});

      // Tambahkan riwayat transaksi
      final transactionRef =
          FirebaseFirestore.instance.collection('points').doc();
      transaction.set(transactionRef, {
        'userId': userId,
        'points': -cost,
        'description': 'Menukar $reward',
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'rewardDetails': reward,
        'status': 'Berhasil',
        'type': 'redeemed',
      });
    });

    showSuccessDialog(context, () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const TransactionHistoryPage(),
        ),
      );
    });
  } catch (e) {
    print('Terjadi kesalahan saat menukarkan poin: $e');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text('Gagal menukarkan poin: ${e.toString()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

void showInsufficientPointsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Poin Tidak Cukup'),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: const Text(
          'Anda tidak memiliki cukup poin untuk melakukan penukaran.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

void showRedeemConfirmationDialog(BuildContext context, String userId, int cost,
    String reward, String imageUrl) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Konfirmasi Penukaran'),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content:
          Text('Apakah Anda yakin ingin menukar $cost poin untuk $reward?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          child: const Text('Tidak'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context); // Tutup popup konfirmasi
            await redeemPoints(context, userId, cost, reward, imageUrl);
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          child: const Text('Ya'),
        ),
      ],
    ),
  );
}

void showSuccessDialog(BuildContext context, VoidCallback onClose) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Penukaran Berhasil'),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
              onClose();
            },
          ),
        ],
      ),
      content: const Text('Selamat! Anda berhasil menukarkan poin.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onClose();
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          child: const Text('Lihat Riwayat'),
        ),
      ],
    ),
  );
}
