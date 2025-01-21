// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool isPaymentSuccesful = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final cart = Provider.of<Cart>(context);

    // Hitung total harga dari keranjang
    double totalPrice = cart.cart.fold(
      0,
      (previousValue, cartModel) =>
          previousValue +
          int.parse(cartModel.price!) * int.parse(cartModel.quantity!),
    );

    // Ambil booking date dan durasi dari item pertama di keranjang
    String bookingDate = cart.cart.isNotEmpty
        ? cart.cart.first.bookingDate ?? 'Tidak diketahui'
        : 'Tidak ada data';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPaymentSuccesful)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Pembayaran berhasil! Terima kasih telah melakukan transaksi.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Informasi tanggal booking
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  'Tanggal booking: $bookingDate',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tampilkan daftar item dalam keranjang
              const Text(
                'Item di keranjang:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cart.cart.length,
                itemBuilder: (context, index) {
                  final item = cart.cart[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Image.asset(
                          item.imagePath ?? 'assets/images/placeholder.png'),
                      title: Text(item.name ?? 'Item tidak diketahui'),
                      subtitle: Text(
                        'Harga: Rp. ${item.price}, Durasi: ${item.quantity} Jam',
                      ),
                    ),
                  );
                },
              ),
              const Divider(),

              // Tampilkan total harga
              Text(
                'Total Harga: Rp. $totalPrice',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Tombol untuk melanjutkan pembayaran (hanya tampil jika keranjang tidak kosong)
              if (cart.cart.isNotEmpty && !isPaymentSuccesful)
                Center(
                  child: CupertinoButton(
                    color: Colors.black,
                    child: const Text(
                      'Lakukan Pembayaran',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      try {
                        // Ambil nama depan dan belakang
                        final fullName = userProvider.userName.split(' ');
                        final firstName =
                            fullName.isNotEmpty ? fullName[0] : '';
                        final lastName = fullName.length > 1
                            ? fullName.sublist(1).join(' ')
                            : '';

                        // Kirim data transaksi ke backend
                        final response = await http.post(
                          Uri.parse(
                              'http://localhost:3000/pay'), // Ganti localhost dengan 10.0.2.2
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
                            // Buka popup Midtrans dengan token transaksi
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentWebView(
                                  transactionToken: transactionToken,
                                ),
                              ),
                            );

                            if (result == true) {
                              setState(() {
                                isPaymentSuccesful = true;
                              });

                              // Tampilkan popup notifikasi sukses
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Pembayaran Berhasil'),
                                  content: const Text(
                                      'Pembayaran Anda berhasil dilakukan.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } else {
                            throw Exception('Transaction token not found');
                          }
                        } else {
                          throw Exception('Failed to create payment');
                        }
                      } catch (e) {
                        print('Error: $e');
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentWebView extends StatelessWidget {
  final String transactionToken;

  const PaymentWebView({
    super.key,
    required this.transactionToken,
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
        onLoadStop: (controller, url) {
          if (url.toString().contains('success')) {
            Navigator.pop(context, true);
          } else if (url.toString().contains('failure')) {
            Navigator.pop(context, false);
          }
        },
      ),
    );
  }
}
