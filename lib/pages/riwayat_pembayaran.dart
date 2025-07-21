import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  // Fungsi untuk memformat tanggal
  String _formatBookingDate(String dateStr) {
    if (dateStr.isEmpty) return 'Tanggal tidak valid';
    try {
      final date = DateTime.parse(dateStr);
      // Menggunakan locale 'id' untuk format bahasa Indonesia
      return DateFormat('d MMMM yyyy', 'id').format(date);
    } catch (e) {
      return dateStr; // Kembalikan string asli jika format gagal
    }
  }

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

          // Filter dokumen dengan status selain "Pending"
          final bookings = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['statusBooking'] ?? '';
            return status != 'Pending';
          }).toList();

          if (bookings.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada riwayat pembayaran yang selesai.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final bookingData =
                  bookings[index].data() as Map<String, dynamic>;
              final items = bookingData['items'] as List<dynamic>? ?? [];

              // Jika tidak ada item dalam booking, tampilkan pesan error
              if (items.isEmpty) {
                return const Card(
                    child:
                        ListTile(title: Text('Data booking tidak lengkap.')));
              }

              final firstItem = items[0];

              // --- Mengambil data dari dokumen booking utama ---
              final namaPengguna = bookingData['userName'] ?? 'Tidak Diketahui';
              final noWhatsapp = bookingData['userPhone'] ?? '-';
              final status = bookingData['statusBooking'] ?? 'Pending';
              final totalAmount = bookingData['totalAmount'] ?? 0;
              final originalTotal =
                  bookingData['originalTotalAmount']; // Bisa jadi null
              // [FIX] Mengambil status member dari data booking utama, bukan dari item
              final isMember = bookingData['isMember'] ?? false;

              // --- Mengambil data dari item pertama ---
              final lapangan = firstItem['name'] ?? 'Lapangan Tidak Diketahui';
              final bookingDate = firstItem['bookingDate'] ?? '';
              final time = firstItem['time'] ?? '';
              final duration = firstItem['quantity'] ?? 1; // Durasi booking
              final imagePath = firstItem['imagePath'] ?? '';
              final teamName = firstItem['teamName'] ?? '';

              // Layanan tambahan
              final usePhotographer = firstItem['usePhotographer'] ?? false;
              final useReferee = firstItem['useReferee'] ?? false;
              final useIceBath = firstItem['useIceBath'] ?? false;
              final photographerPrice =
                  firstItem['photographerPrice'] ?? 200000;
              final refereePrice = firstItem['refereePrice'] ?? 70000;
              final iceBathPrice = firstItem['iceBathPrice'] ?? 50000;
              final priceLapang = (totalAmount -
                  (usePhotographer ? photographerPrice : 0) -
                  (useReferee ? refereePrice : 0) -
                  (useIceBath ? iceBathPrice : 0));

              // --- Logika untuk status (warna dan ikon) ---
              Color statusColor = Colors.grey;
              IconData statusIcon = Icons.access_time;

              if (status.contains('Sudah Bayar')) {
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
              } else if (status.contains('Booking')) {
                statusColor = Colors.blue;
                statusIcon = Icons.calendar_today;
              } else if (status.contains('Gagal') ||
                  status.toLowerCase().contains('expire')) {
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
                                  'Tanggal: ${_formatBookingDate(bookingDate)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  'Jam: $time ($duration jam)',
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
                      const SizedBox(height: 8),

                      // --- Detail Pemesan ---
                      Text('Detail Pemesan:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700])),
                      const SizedBox(height: 4),
                      Text('Nama: $namaPengguna'),
                      Text('No. WhatsApp: $noWhatsapp'),
                      if (teamName.isNotEmpty) Text('Atas Nama: $teamName'),
                      Text('Status Member: ${isMember ? 'Ya' : 'Tidak'}'),
                      const SizedBox(height: 16),

                      // --- Detail Layanan ---
                      Text('Detail Layanan:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700])),
                      const SizedBox(height: 4),
                      Text(
                          'Harga Lapang ($duration jam): Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(priceLapang)}'),
                      if (usePhotographer)
                        Text(
                            'Photographer: Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(photographerPrice)}'),
                      if (useReferee)
                        Text(
                            'Wasit: Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(refereePrice)}'),
                      if (useIceBath)
                        Text(
                            'Ice Bath: Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(iceBathPrice)}'),

                      const SizedBox(height: 16),

                      // --- Total Harga ---
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
                              if (isMember &&
                                  originalTotal != null &&
                                  originalTotal != totalAmount)
                                Text(
                                  'Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(originalTotal)}',
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              Text(
                                'Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(totalAmount)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (isMember &&
                                  originalTotal != null &&
                                  originalTotal > totalAmount)
                                Text(
                                  'Anda hemat Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(originalTotal - totalAmount)}',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
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
