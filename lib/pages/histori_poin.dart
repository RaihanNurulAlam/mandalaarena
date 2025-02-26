import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart';

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
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: Image.asset(data['imageUrl']), // Tampilkan gambar
                  title: Text(data['description']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tanggal: ${data['timestamp'].toDate().toString()}'),
                      Text('Status: ${data['status']}'),
                      Text('Detail: ${data['rewardDetails']}'),
                    ],
                  ),
                  trailing: Text(
                    '${data['points'] > 0 ? '+' : ''}${data['points']} Poin',
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
}
