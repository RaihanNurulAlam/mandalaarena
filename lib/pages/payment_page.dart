// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print, unnecessary_import

import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  String? transactionStatus;

  String getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:3000'; // Browser
    } else {
      return 'http://10.0.2.2:3000'; // Emulator Android/Desktop
    }
  }

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

    // Tanggal booking dari keranjang
    String bookingDate = cart.cart.isNotEmpty
        ? cart.cart.first.bookingDate ?? 'Tidak diketahui'
        : 'Tidak ada data';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        // backgroundColor: Colors.black,
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

              // Informasi tanggal booking
              Container(
                margin: const EdgeInsets.only(bottom: 24),
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
                    const Icon(Icons.calendar_today, color: Colors.black54),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tanggal booking: $bookingDate',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tampilkan daftar item dalam keranjang
              const Text(
                'Item di keranjang:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cart.cart.length,
                itemBuilder: (context, index) {
                  final item = cart.cart[index];
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
                                'Harga: Rp. ${item.price}, Durasi: ${item.quantity} Jam',
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
              Row(
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
                    'Rp. $totalPrice',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tombol pembayaran
              if (cart.cart.isNotEmpty && transactionStatus == null)
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
