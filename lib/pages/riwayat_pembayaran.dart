import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pembayaran'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada riwayat pembayaran.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final bookings = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['statusBooking'] ?? '';
            return status != 'Pending'; // Filter status "Pending"
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index].data() as Map<String, dynamic>;
              final items = booking['items'] as List<dynamic>? ?? [];
              final firstItem = items.isNotEmpty ? items[0] : {};

              final lapangan = firstItem['name'] ?? 'Lapangan Tidak Diketahui';
              final bookingDate = firstItem['bookingDate'] ?? '';
              final time = firstItem['time'] ?? '';
              final status = booking['statusBooking'] ?? 'Pending';
              final totalAmount = booking['totalAmount'] ?? 0;
              final originalTotal =
                  booking['originalTotalAmount'] ?? totalAmount;
              final namaPengguna = booking['userName'] ?? 'Tidak Diketahui';
              final noWhatsapp = booking['userPhone'] ?? '-';
              final imagePath = firstItem['imagePath'] ?? '';
              final teamName = firstItem['teamName'] ?? '';
              final usePhotographer = firstItem['usePhotographer'] ?? false;
              final useReferee = firstItem['useReferee'] ?? false;
              final isMember = firstItem['isMember'] ?? false;
              final originalPrice =
                  firstItem['originalPrice'] ?? firstItem['price'];
              final discountedPrice =
                  firstItem['discountedPrice'] ?? firstItem['price'];

              Color statusColor = Colors.grey;
              IconData statusIcon = Icons.access_time;

              if (status.contains('Sudah Bayar')) {
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
              } else if (status.contains('Booking')) {
                statusColor = Colors.blue;
                statusIcon = Icons.calendar_today;
              } else if (status.contains('Gagal') ||
                  status.contains('expire')) {
                statusColor = Colors.red;
                statusIcon = Icons.error;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: imagePath.isNotEmpty
                                  ? DecorationImage(
                                      image: AssetImage(imagePath),
                                      fit: BoxFit.cover,
                                    )
                                  : const DecorationImage(
                                      image: AssetImage(
                                          'assets/images/placeholder.png'),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lapangan,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tanggal: $bookingDate',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  'Jam: $time',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(statusIcon,
                                        size: 16, color: statusColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detail Pemesan:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Nama: $namaPengguna'),
                          Text('No. WhatsApp: $noWhatsapp'),
                          if (teamName.isNotEmpty) Text('Atas Nama: $teamName'),
                          Text('Status Member: ${isMember ? 'Ya' : 'Tidak'}'),
                          const SizedBox(height: 16),
                          Text(
                            'Detail Layanan:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (isMember)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Harga Asli: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(double.tryParse(originalPrice.toString()) ?? 0)} per jam'),
                                Text(
                                    'Harga Member: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(double.tryParse(discountedPrice.toString()) ?? 0)} per jam'),
                              ],
                            )
                          else
                            Text(
                                'Harga: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(double.tryParse(originalPrice.toString()) ?? 0)} per jam'),
                          if (usePhotographer)
                            const Text('Photographer: Rp 200,000'),
                          if (useReferee) const Text('Wasit: Rp 70,000'),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Harga:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (isMember && originalTotal != totalAmount)
                                    Text(
                                      'Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(originalTotal)}',
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  Text(
                                    'Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(totalAmount)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (isMember && originalTotal != totalAmount)
                                    Text(
                                      'Anda hemat Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(originalTotal - totalAmount)}',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
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
