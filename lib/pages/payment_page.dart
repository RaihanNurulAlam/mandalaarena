// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

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
              if (cart.cart.isNotEmpty)
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
                        final firstName = fullName.isNotEmpty ? fullName[0] : '';
                        final lastName =
                            fullName.length > 1 ? fullName.sublist(1).join(' ') : '';

                        // Kirim data transaksi ke backend
                        final response = await http.post(
                          Uri.parse('http://localhost:3000/pay'), // Endpoint backend
                          headers: {'Content-Type': 'application/json'},
                          body: json.encode({
                            'orderId':
                                'order-${DateTime.now().millisecondsSinceEpoch}', // Unique order ID
                            'grossAmount': totalPrice.toString(), // Total harga
                            'firstName': firstName, // Nama depan
                            'lastName': lastName, // Nama belakang
                            'email': userProvider.userEmail, // Email
                            'phone': userProvider.userPhone, // Nomor telepon
                          }),
                        );

                        if (response.statusCode == 200) {
                          final data = json.decode(response.body);
                          final transactionToken = data['transactionToken'];
                          if (transactionToken != null) {
                            // Buka popup Midtrans dengan token transaksi
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentWebView(
                                  transactionToken: transactionToken,
                                ),
                              ),
                            );
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
      ),
    );
  }
}
