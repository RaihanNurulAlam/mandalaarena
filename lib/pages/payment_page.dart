// ignore_for_file: deprecated_member_use, avoid_print

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/pages/home_page.dart';
import 'package:mandalaarenaapp/pages/points_page.dart';
import 'package:mandalaarenaapp/pages/riwayat_pembayaran.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? transactionStatus;
  bool isProcessingPayment = false;

  String getBaseUrl() {
    const baseUrl = 'https://api-ygvy5l5oeq-uc.a.run.app';
    if (kDebugMode) {
      print('Using base URL: $baseUrl');
    }
    return baseUrl;
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
        'type': 'earned',
        'timestamp': FieldValue.serverTimestamp(),
        'description': 'Poin dari pembayaran booking',
      });

      print('Poin berhasil disimpan');
    } catch (e) {
      print('Error menyimpan poin: $e');
    }
  }

  Future<void> updateUserPoints(String userId, int earnedPoints) async {
    if (userId.isEmpty) return;

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (userDoc.exists) {
        int currentPoints = userDoc.data()?['points'] ?? 0;
        await userRef.update({'points': currentPoints + earnedPoints});
        print('Poin user berhasil diperbarui.');
      } else {
        print('User tidak ditemukan.');
      }
    } catch (e) {
      print('Error updating user points: $e');
    }
  }

  Future<void> checkTransactionStatus(String orderId) async {
    try {
      final baseUrl = getBaseUrl();
      final statusResponse = await http.get(
        Uri.parse('$baseUrl/transaction-status?orderId=$orderId'),
      );

      if (statusResponse.statusCode == 200) {
        final statusData = json.decode(statusResponse.body);
        setState(() {
          transactionStatus = statusData['transaction_status'];
        });

        if (transactionStatus == 'settlement' ||
            transactionStatus == 'capture') {
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          final cart = Provider.of<Cart>(context, listen: false);

          await updateBookingStatus(orderId, 'Sudah Bayar');
          int earnedPoints = int.parse(cart.cart.first.quantity!) * 10;
          await updateUserPoints(userProvider.userId, earnedPoints);
          await saveUserPointsTransaction(
              userProvider.userId, earnedPoints, orderId);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const TransactionHistoryPage(),
            ),
          );
        }
      }
    } catch (e) {
      print('Error checking transaction status: $e');
    }
  }

  Future<void> initiateMidtransPayment() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final cart = Provider.of<Cart>(context, listen: false);

    setState(() {
      isProcessingPayment = true;
    });

    try {
      double totalPrice = cart.cart.fold(0, (previousValue, cartModel) {
        double price = double.tryParse(cartModel.price ?? '0') ?? 0;
        if (userProvider.isMember) {
          price = price * 0.6;
        }
        final int quantity = int.tryParse(cartModel.quantity ?? '1') ?? 1;
        double itemTotal = price * quantity;

        if (cartModel.usePhotographer ?? false) {
          itemTotal += 200000;
        }

        if (cartModel.useReferee ?? false) {
          itemTotal += 70000;
        }

        return previousValue + itemTotal;
      });

      final fullName = userProvider.userName.split(' ');
      final firstName = fullName.isNotEmpty ? fullName[0] : '';
      final lastName = fullName.length > 1 ? fullName.sublist(1).join(' ') : '';

      final orderId =
          'ORDER-${DateTime.now().millisecondsSinceEpoch}-${userProvider.userId.substring(0, 5)}';

      final baseUrl = getBaseUrl();
      final url = Uri.parse('$baseUrl/pay');

      final response = await http
          .post(
            Uri.parse('$baseUrl/pay'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'orderId': orderId,
              'grossAmount': totalPrice.toString(),
              'firstName': firstName,
              'lastName': lastName,
              'email': userProvider.userEmail,
              'phone': userProvider.userPhone,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final redirectUrl = data['redirect_url'];
        final transactionToken = data['transactionToken'];

        // Untuk web
        if (kIsWeb) {
          if (await canLaunchUrl(Uri.parse(redirectUrl))) {
            await launchUrl(
              Uri.parse(redirectUrl),
              mode: LaunchMode.externalApplication,
            );
          }
        }
        // Untuk mobile
        else {
          // Tampilkan popup pembayaran Midtrans
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MidtransPaymentPopup(
                transactionToken: transactionToken,
                orderId: orderId,
              ),
            ),
          );
        }

        // Periksa status pembayaran
        await checkTransactionStatus(orderId);
      } else {
        throw Exception('Failed to create transaction: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isProcessingPayment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final cart = Provider.of<Cart>(context);

    double totalPrice = cart.cart.fold(0, (previousValue, cartModel) {
      double price = double.tryParse(cartModel.price ?? '0') ?? 0;
      if (userProvider.isMember) {
        price = price * 0.6;
      }
      final int quantity = int.tryParse(cartModel.quantity ?? '1') ?? 1;
      double itemTotal = price * quantity;

      if (cartModel.usePhotographer ?? false) {
        itemTotal += 200000;
      }

      if (cartModel.useReferee ?? false) {
        itemTotal += 70000;
      }

      return previousValue + itemTotal;
    });

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

              if (isProcessingPayment)
                const Center(
                  child: CircularProgressIndicator(),
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
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
                      price = price * 0.6;
                    }
                    final totalPrice =
                        price * (int.tryParse(item.quantity ?? '1') ?? 1);

                    if (item.usePhotographer ?? false) {
                      price += 200000;
                    }

                    if (item.useReferee ?? false) {
                      price += 70000;
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
                              width: 100,
                              height: 100,
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
                                  'Harga: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(double.tryParse(item.price ?? '0') ?? 0)} x ${item.quantity} Jam',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                if (userProvider.isMember)
                                  Text(
                                    'Diskon Member: 40%',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.green[700]),
                                  ),
                                Text(
                                  'Total setelah diskon: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(totalPrice)}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
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
                        'Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(totalPrice)}',
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
                if (transactionStatus == null && !isProcessingPayment)
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
                      onPressed: initiateMidtransPayment,
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

class MidtransPaymentPopup extends StatefulWidget {
  final String transactionToken;
  final String orderId;

  const MidtransPaymentPopup({
    super.key,
    required this.transactionToken,
    required this.orderId,
  });

  @override
  State<MidtransPaymentPopup> createState() => _MidtransPaymentPopupState();
}

class _MidtransPaymentPopupState extends State<MidtransPaymentPopup> {
  @override
  void initState() {
    super.initState();
    _openPaymentUrl();
  }

  Future<void> _openPaymentUrl() async {
    final url =
        'https://app.midtrans.com/snap/v2/vtweb/${widget.transactionToken}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      // Simulasikan pembayaran selesai setelah membuka URL
      _checkPaymentStatus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka URL pembayaran'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context, false);
    }
  }

  void _checkPaymentStatus() {
    // Simulasikan logika untuk memeriksa status pembayaran
    // Misalnya, Anda dapat memanggil API untuk memeriksa status transaksi
    Navigator.pop(context, true); // Kembali ke halaman sebelumnya
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran Midtrans'),
      ),
      body: const Center(
        child: Text('Membuka halaman pembayaran...'),
      ),
    );
  }
}
