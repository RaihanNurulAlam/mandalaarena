// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    // Inisialisasi locale 'id' untuk format tanggal dan mata uang
    Intl.defaultLocale = 'id_ID';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pembayaran'),
        elevation: 1,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Silakan login untuk melihat riwayat pembayaran.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('userId', isEqualTo: user.uid)
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
                  return status.toLowerCase() != 'pending';
                }).toList();

                if (bookings.isEmpty) {
                  return const Center(
                    child: Text(
                      'Tidak ada riwayat pembayaran yang selesai.',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                // --- Tampilan utama menggunakan Wrap ---
                return SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 24.0,
                        runSpacing: 24.0,
                        children: bookings.map((doc) {
                          final bookingData =
                              doc.data() as Map<String, dynamic>;
                          return Container(
                            constraints: const BoxConstraints(maxWidth: 550),
                            child: _TransactionCard(bookingData: bookingData),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Widget terpisah untuk kartu riwayat agar kode lebih rapi
class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const _TransactionCard({required this.bookingData});

  String _formatBookingDate(String dateStr) {
    if (dateStr.isEmpty) return 'Tanggal tidak valid';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  // Fungsi ini disalin dari BookingSummaryPage untuk konsistensi harga
  int _getPriceForHour(int hour, String lapangName) {
    const int basePriceMinisoccer = 450000;
    const int basePriceBasketA = 150000;
    const int basePriceBasketB = 75000;

    if (lapangName == "Lapang Minisoccer") {
      if (hour >= 7 && hour < 14) return basePriceMinisoccer;
      if (hour >= 14 && hour < 18) return basePriceMinisoccer + 100000;
      if (hour >= 18 && hour < 23) return basePriceMinisoccer + 200000;
      return basePriceMinisoccer;
    } else if (lapangName == "Lapang Basket A") {
      if (hour >= 7 && hour < 14) return basePriceBasketA;
      if (hour >= 14 && hour < 18) return basePriceBasketA + 50000;
      if (hour >= 18 && hour < 23) return basePriceBasketA + 100000;
      return basePriceBasketA;
    } else if (lapangName == "Lapang Basket B") {
      if (hour >= 7 && hour < 14) return basePriceBasketB;
      if (hour >= 14 && hour < 18) return basePriceBasketB + 25000;
      if (hour >= 18 && hour < 23) return basePriceBasketB + 50000;
      return basePriceBasketB;
    }
    return 0; // Default price jika nama lapangan tidak cocok
  }

  @override
  Widget build(BuildContext context) {
    final items = bookingData['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) {
      return const Card(
          child: ListTile(title: Text('Data booking tidak lengkap.')));
    }

    final firstItem = items[0];
    final status = bookingData['statusBooking'] ?? 'Pending';
    final imagePath = firstItem['imagePath'] ?? 'assets/minsoc.jpg';

    // --- EKSTRAKSI DATA LENGKAP DARI DOKUMEN BOOKING ---
    final isMember = bookingData['isMember'] ?? false;
    final totalAmount = bookingData['totalAmount'] ?? 0;

    // Layanan Tambahan
    final usePhotographer = firstItem['usePhotographer'] ?? false;
    final useReferee = firstItem['useReferee'] ?? false;
    final useIceBath = firstItem['useIceBath'] ?? false;
    const photographerPrice = 200000;
    const refereePrice = 70000;
    const iceBathPrice = 50000;

    double addonsPrice = 0;
    if (usePhotographer) addonsPrice += photographerPrice;
    if (useReferee) addonsPrice += refereePrice;
    if (useIceBath) addonsPrice += iceBathPrice;

    // Kalkulasi ulang harga dasar lapang dari total
    // Ini mengasumsikan totalAmount = harga asli lapang - diskon + addons
    // Maka, harga asli lapang = totalAmount + diskon - addons

    // Untuk mendapatkan harga lapang sebelum diskon, kita hitung ulang.
    final int startHour =
        int.tryParse(firstItem['time']?.split(":")[0] ?? '0') ?? 0;
    final int duration = int.tryParse(firstItem['quantity'] ?? '1') ?? 1;
    double originalLapangPrice = 0;
    for (int i = 0; i < duration; i++) {
      originalLapangPrice +=
          _getPriceForHour(startHour + i, firstItem['name'] ?? '');
    }

    final double discountAmount = isMember ? originalLapangPrice * 0.10 : 0;
    final double lapangPriceAfterDiscount =
        originalLapangPrice - discountAmount;

    // --- Logika untuk status (warna dan ikon) ---
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.access_time;
    if (status.contains('Sudah Bayar')) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (status.toUpperCase().contains('DP')) {
      statusColor = Colors.orange.shade800;
      statusIcon = Icons.inventory;
    } else if (status.contains('Gagal') ||
        status.toLowerCase().contains('expire')) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else if (status.contains('Booking')) {
      statusColor = Colors.blue;
      statusIcon = Icons.bookmark;
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- BAGIAN HEADER ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.asset(
                    imagePath,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported,
                        size: 80,
                        color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstItem['name'] ?? 'Lapangan Tidak Diketahui',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                          'Tanggal: ${_formatBookingDate(firstItem['bookingDate'] ?? '')}'),
                      Text(
                          'Jam: ${firstItem['time'] ?? ''} (${firstItem['quantity'] ?? 1} jam)'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // --- RINCIAN HARGA ---
            Text('Rincian Harga',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Harga Lapang & Diskon Member
            _buildPriceRow(label: 'Harga Lapang', amount: originalLapangPrice),
            if (isMember && discountAmount > 0)
              _buildPriceRow(
                label: 'Diskon Member (10%)',
                amount: -discountAmount, // Tampilkan sebagai pengurang
                isDiscount: true,
              ),

            // Layanan Tambahan (jika ada)
            if (addonsPrice > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Layanan Tambahan:',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.black54)),
              ),
            if (usePhotographer)
              _buildPriceRow(
                  label: '  - Photographer',
                  amount: photographerPrice.toDouble()),
            if (useReferee)
              _buildPriceRow(
                  label: '  - Wasit', amount: refereePrice.toDouble()),
            if (useIceBath)
              _buildPriceRow(
                  label: '  - Ice Bath', amount: iceBathPrice.toDouble()),

            const Divider(height: 24),

            // --- BAGIAN TOTAL HARGA ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Total Dibayar:',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0)
                      .format(totalAmount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        // DIUBAH: Ukuran disamakan
                        fontWeight: FontWeight.bold,
                        color: Colors.black87, // DIUBAH: Warna menjadi hitam
                      ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Helper widget untuk membuat baris harga
  Widget _buildPriceRow(
      {required String label,
      required double amount,
      bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  TextStyle(color: isDiscount ? Colors.green : Colors.black87)),
          Text(
            NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0)
                .format(amount),
            style: TextStyle(
                color: isDiscount ? Colors.green : Colors.black87,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
