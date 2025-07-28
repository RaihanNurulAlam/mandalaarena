// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';

class PointsPage extends StatelessWidget {
  const PointsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Kita tetap butuh userId dari provider untuk tahu dokumen mana yang harus didengarkan
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    // Jika karena suatu hal userId kosong, tampilkan halaman kosong untuk mencegah error
    if (userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Poin Anda')),
        body: const Center(
            child: Text('User tidak ditemukan. Silakan login kembali.')),
      );
    }

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
      // StreamBuilder akan mendengarkan perubahan pada dokumen user secara real-time
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          // Tampilkan loading indicator saat data sedang diambil
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Tampilkan pesan error jika terjadi masalah
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          // Tampilkan pesan jika user tidak ditemukan di database
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data poin tidak ditemukan.'));
          }

          // Ambil data poin terbaru langsung dari snapshot
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final points = data['points'] ?? 0;

          // Bangun UI dengan data poin yang sudah real-time
          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Total Poin: $points', // Gunakan data poin dari snapshot
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
                                image:
                                    const AssetImage('assets/minisoccer.jpg'),
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
                                // Logika penukaran poin menggunakan data real-time
                                onPressed: points >= 10
                                    ? () => showRedeemConfirmationDialog(
                                          context,
                                          userId,
                                          10,
                                          'Gratis 1 Jam',
                                          'assets/minisoccer.jpg',
                                        )
                                    : () =>
                                        showInsufficientPointsDialog(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: points >= 10
                                      ? Colors.blue.withOpacity(0.8)
                                      : Colors.grey,
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
                                image: const AssetImage('assets/coffee.jpg'),
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
                                    : () =>
                                        showInsufficientPointsDialog(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: points >= 3
                                      ? Colors.orange.withOpacity(0.8)
                                      : Colors.grey,
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
          );
        },
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
              var pointsValue = data['points'] as num;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: data['imageUrl'] != null
                      ? Image.asset(
                          data['imageUrl'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported),
                        )
                      : const Icon(Icons.card_giftcard),
                  title: Text(data['description']),
                  subtitle: Text(
                    data['timestamp'] != null
                        ? _formatDate(data['timestamp'].toDate())
                        : 'No date',
                  ),
                  trailing: Text(
                    '${pointsValue > 0 ? '+' : ''}$pointsValue Poin',
                    style: TextStyle(
                      color: pointsValue > 0 ? Colors.green : Colors.red,
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) {
        throw Exception("User tidak ditemukan");
      }

      int currentPoints = userDoc.data()?['points'] ?? 0;
      if (currentPoints < cost) {
        throw Exception("Poin tidak cukup");
      }

      int newPoints = currentPoints - cost;

      transaction.update(userRef, {'points': newPoints});

      // Tetap update provider agar halaman lain yang tidak pakai StreamBuilder ikut update
      userProvider.updateUserPoints(newPoints);

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
      Navigator.of(context).pop(); // Cukup tutup dialog sukses
    });
  } catch (e) {
    print('Terjadi kesalahan saat menukarkan poin: $e');
    if (e.toString().contains("Poin tidak cukup")) {
      showInsufficientPointsDialog(context);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Gagal menukarkan poin: ${e.toString()}'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

void showInsufficientPointsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          const Text('Poin Tidak Cukup'),
        ],
      ),
      content: const Text(
          'Anda tidak memiliki cukup poin untuk melakukan penukaran ini.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          child: const Text('Mengerti'),
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
      title: const Text('Konfirmasi Penukaran'),
      content:
          Text('Apakah Anda yakin ingin menukar $cost poin untuk $reward?'),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await redeemPoints(context, userId, cost, reward, imageUrl);
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          child: const Text('Ya, Tukar'),
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
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 10),
          const Text('Penukaran Berhasil'),
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
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
