// ignore_for_file: avoid_print, deprecated_member_use

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/pages/home_page.dart'; // Import halaman home
import 'package:mandalaarenaapp/pages/points_page.dart'; // Halaman poin
import 'package:mandalaarenaapp/pages/riwayat_pembayaran.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? transactionStatus;

  String getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:5001/mandalaarenaapp-95d0d/us-central1/api'; // Emulator
    } else {
      return 'https://us-central1-mandalaarenaapp-95d0d.cloudfunctions.net/api'; // Production
    }
  }

  Future<void> updateBookingStatus(String orderId, String status) async {
    try {
      final bookingRef =
          FirebaseFirestore.instance.collection('bookings').doc(orderId);
      await bookingRef.update({'statusBooking': status});
    } catch (e) {
      print('Error updating booking status: $e');
    }
  }

  Future<void> saveUserPointsTransaction(
      String userId, int earnedPoints, String orderId) async {
    try {
      final pointsRef = FirebaseFirestore.instance.collection('points').doc();

      await pointsRef.set({
        'userId': userId,
        'points': earnedPoints,
        'orderId': orderId,
        'type': 'earned', // Menandakan poin diperoleh
        'timestamp': FieldValue.serverTimestamp(),
        'description': 'Poin dari pembayaran booking',
      });

      print('Poin berhasil disimpan');
    } catch (e) {
      print('Error menyimpan poin: $e');
    }
  }

  Future<void> updateUserPoints(String userId, int earnedPoints) async {
    if (userId.isEmpty) return; // Pastikan userId tidak kosong

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (userDoc.exists) {
        int currentPoints = userDoc.data()?['points'] ?? 0;

        // Update total poin di Firestore
        await userRef.update({'points': currentPoints + earnedPoints});
        print('Poin user berhasil diperbarui.');
      } else {
        print('User tidak ditemukan.');
      }
    } catch (e) {
      print('Error updating user points: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final cart = Provider.of<Cart>(context);

    // Hitung total harga dari keranjang dengan diskon jika member
    double totalPrice = cart.cart.fold(
      0,
      (previousValue, cartModel) {
        double price = double.tryParse(cartModel.price ?? '0') ?? 0;
        if (userProvider.isMember) {
          price = price * 0.4; // Diskon 60% untuk member
        }

        // Tambahkan biaya photographer jika dipilih
        if (cartModel.usePhotographer ?? false) {
          price += 200000; // Biaya photographer
        }

        // Tambahkan biaya wasit jika dipilih
        if (cartModel.useReferee ?? false) {
          price += 70000; // Biaya wasit
        }

        return previousValue + (price * int.parse(cartModel.quantity!));
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi', style: TextStyle(color: Colors.black)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: IconButton(
              icon: const Icon(Icons.history, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryPaymentPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (transactionStatus != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: transactionStatus == 'settlement'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        transactionStatus == 'settlement'
                            ? Icons.check_circle
                            : Icons.error,
                        color: transactionStatus == 'settlement'
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Status Transaksi: $transactionStatus',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: transactionStatus == 'settlement'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Informasi jumlah item di keranjang
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.black54),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cart.cart.isNotEmpty
                            ? 'Jumlah Item: ${cart.cart.length}'
                            : 'Tidak ada item',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (cart.cart.isEmpty)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomePage(),
                            ),
                          );
                        },
                        child: const Text('Lakukan Booking',
                            style: TextStyle(color: Colors.black)),
                      ),
                  ],
                ),
              ),

              // Tampilkan daftar item dalam keranjang
              if (cart.cart.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Text(
                    'Item di keranjang:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cart.cart.length,
                  itemBuilder: (context, index) {
                    final item = cart.cart[index];
                    double price = double.tryParse(item.price ?? '0') ?? 0;
                    if (userProvider.isMember) {
                      price = price * 0.4; // Diskon 60% untuk member
                    }

                    // Tambahkan biaya photographer jika dipilih
                    if (item.usePhotographer ?? false) {
                      price += 200000; // Biaya photographer
                    }

                    // Tambahkan biaya wasit jika dipilih
                    if (item.useReferee ?? false) {
                      price += 70000; // Biaya wasit
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              item.imagePath ?? 'assets/images/placeholder.png',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name ?? 'Item tidak diketahui',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Harga: Rp. ${price.toString()} x ${item.quantity} Jam',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tanggal: ${item.bookingDate} - Jam: ${item.time}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                if (item.usePhotographer ?? false)
                                  Text(
                                    'Layanan: Photographer (+Rp 200,000)',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                if (item.useReferee ?? false)
                                  Text(
                                    'Layanan: Wasit (+Rp 70,000)',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
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
                const Divider(height: 32),

                // Tampilkan total harga
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Harga:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total: Rp. ${NumberFormat.currency(locale: 'id', symbol: '').format(totalPrice)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol pembayaran
                if (transactionStatus == null)
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      onPressed: () async {
                        try {
                          final fullName = userProvider.userName.split(' ');
                          final firstName =
                              fullName.isNotEmpty ? fullName[0] : '';
                          final lastName = fullName.length > 1
                              ? fullName.sublist(1).join(' ')
                              : '';

                          final baseUrl = getBaseUrl();

                          final response = await http.post(
                            Uri.parse('$baseUrl/pay'),
                            headers: {'Content-Type': 'application/json'},
                            body: json.encode({
                              'orderId':
                                  'order-${DateTime.now().millisecondsSinceEpoch}',
                              'grossAmount': totalPrice.toString(),
                              'firstName': firstName,
                              'lastName': lastName,
                              'email': userProvider.userEmail,
                              'phone': userProvider.userPhone,
                            }),
                          );

                          if (response.statusCode == 200) {
                            final data = json.decode(response.body);
                            final transactionToken = data['transactionToken'];

                            if (transactionToken != null) {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaymentWebView(
                                    transactionToken: transactionToken,
                                    orderId: data['orderId'],
                                  ),
                                ),
                              );

                              if (result == true) {
                                final statusResponse = await http.get(
                                  Uri.parse(
                                      '$baseUrl/transaction-status?orderId=${data['orderId']}'),
                                );

                                if (statusResponse.statusCode == 200) {
                                  final statusData =
                                      json.decode(statusResponse.body);
                                  setState(() {
                                    transactionStatus =
                                        statusData['transaction_status'];
                                  });
                                  // Jika transaksi berhasil, update status booking dan navigasi ke histori pembayaran
                                  if (transactionStatus == 'settlement' ||
                                      transactionStatus == 'capture') {
                                    await updateBookingStatus(
                                        data['orderId'], 'Sudah Bayar');
                                    int earnedPoints =
                                        int.parse(cart.cart.first.quantity!) *
                                            10; // 10 poin per jam
                                    await updateUserPoints(
                                        userProvider.userId, earnedPoints);
                                    await saveUserPointsTransaction(
                                        userProvider.userId,
                                        earnedPoints,
                                        data['orderId']);

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const TransactionHistoryPage(),
                                      ),
                                    );
                                  } else {
                                    // Jika transaksi gagal, arahkan kembali ke payment page
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PaymentPage(),
                                      ),
                                    );
                                  }
                                }
                              }
                            }
                          }
                        } catch (e) {
                          print('Error: $e');
                        }
                      },
                      child: const Text(
                        'Lakukan Pembayaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentWebView extends StatelessWidget {
  final String transactionToken;
  final String orderId;

  const PaymentWebView({
    super.key,
    required this.transactionToken,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(
            'https://app.sandbox.midtrans.com/snap/v2/vtweb/$transactionToken',
          ),
        ),
        onLoadStop: (controller, url) async {
          try {
            final uri = Uri.parse(url.toString());

            if (uri.queryParameters.containsKey('transaction_status')) {
              final status = uri.queryParameters['transaction_status'];

              // Navigate back to PaymentPage with the status and orderId
              Navigator.pop(context, {'status': status, 'orderId': orderId});
            }
          } catch (e) {
            print('Error processing URL: $e');
            Navigator.pop(context, {'status': 'error', 'orderId': orderId});
          }
        },
      ),
    );
  }
}
