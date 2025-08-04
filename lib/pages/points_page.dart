// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';

class PointsPage extends StatelessWidget {
  const PointsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    if (userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Poin Anda')),
        body: const Center(
            child: Text('User tidak ditemukan. Silakan login kembali.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Poin Anda'),
        actions: [
          IconButton(
            tooltip: 'Riwayat Poin',
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
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data poin tidak ditemukan.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final points = data['points'] ?? 0;

          // Menggunakan Align dan ConstrainedBox untuk layout responsif
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: 1000), // Lebar maksimum konten
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // --- Bagian Total Poin ---
                    Text(
                      'Total Poin: $points',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),

                    // --- Bagian Kupon Penukaran ---
                    // Menggunakan Wrap agar responsif
                    Wrap(
                      spacing: 16.0,
                      runSpacing: 16.0,
                      alignment: WrapAlignment.center,
                      children: [
                        // Kupon 1 (Tukar 10 Poin)
                        _buildCouponCard(
                          context: context,
                          userId: userId,
                          pointsCost: 10,
                          userPoints: points,
                          title: 'Tukar 10 Poin - Gratis 1 Jam',
                          assetImage: 'assets/minisoccer.jpg',
                          reward: 'Gratis 1 Jam',
                          buttonColor: Colors.blue,
                        ),

                        // Kupon 2 (Tukar 3 Poin)
                        _buildCouponCard(
                          context: context,
                          userId: userId,
                          pointsCost: 3,
                          userPoints: points,
                          title: 'Tukar 3 Poin - Voucher Kopi',
                          assetImage: 'assets/coffee.jpg',
                          reward: 'Voucher Kopi',
                          buttonColor: Colors.orange,
                        ),
                        // Tambahkan kupon lain di sini jika perlu
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget helper untuk membuat kartu kupon, agar kode lebih rapi
  Widget _buildCouponCard({
    required BuildContext context,
    required String userId,
    required int pointsCost,
    required int userPoints,
    required String title,
    required String assetImage,
    required String reward,
    required Color buttonColor,
  }) {
    final bool canRedeem = userPoints >= pointsCost;

    return SizedBox(
      width: 450, // Lebar tetap untuk setiap kartu
      child: Card(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(assetImage),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5),
                BlendMode.darken,
              ),
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            trailing: ElevatedButton(
              onPressed: canRedeem
                  ? () => showRedeemConfirmationDialog(
                      context, userId, pointsCost, reward, assetImage)
                  : () => showInsufficientPointsDialog(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canRedeem ? buttonColor.withOpacity(0.8) : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30))),
              child: const Text('Tukar'),
            ),
          ),
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: StreamBuilder<QuerySnapshot>(
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
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// --- FUNGSI HELPER (DIALOG DAN LOGIKA PENUKARAN) TIDAK DIUBAH ---

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
      Navigator.of(context).pop();
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
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 10),
          Text('Poin Tidak Cukup'),
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(context);
            await redeemPoints(context, userId, cost, reward, imageUrl);
          },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black,
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
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 10),
          Text('Penukaran Berhasil'),
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
