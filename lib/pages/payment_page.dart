// ignore_for_file: deprecated_member_use, unused_element, unused_local_variable, no_leading_underscores_for_local_identifiers, use_build_context_synchronously, sort_child_properties_last

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/pages/models/cart_model.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

final serverKey = dotenv.env['SERVER_KEY'];

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

    Future<void> _processPayment() async {
      final String url = "https://app.sandbox.midtrans.com/snap/v1/transactions";

      final headers = {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$serverKey:'))}',
        'Content-Type': 'application/json',
      };

      final body = {
        "transaction_details": {
          "order_id": "order-${DateTime.now().millisecondsSinceEpoch}",
          "gross_amount": totalPrice
        },
        "customer_details": {
          "first_name": userProvider.userName,
          "last_name": "", // Assuming last name is not available
          "email": userProvider.userEmail,
          "phone": "" // Assuming phone is not available
        }
      };

      try {
        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(body),
        );

        if (response.statusCode == 201) {
          final transactionData = jsonDecode(response.body);
          final snapUrl = transactionData['redirect_url'];

          // Buka Snap URL di browser atau WebView
          if (await canLaunch(snapUrl)) {
            if (kIsWeb) {
              await launch(snapUrl);
            } else if (Platform.isAndroid || Platform.isIOS) {
              await launch(snapUrl, forceSafariVC: false, forceWebView: true);
            } else {
              await launch(snapUrl);
            }
          } else {
            throw "Tidak dapat membuka Snap URL";
          }
        } else {
          throw "Gagal memproses pembayaran: ${response.body}";
        }
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Proses Pembayaran Gagal'),
            content: Text('Terjadi kesalahan: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }

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
                        'Harga: Rp. ${item.price}, Durasi: ${item.quantity} Jam', // Ubah Quantity menjadi Durasi
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
                    onPressed: _processPayment,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on CartModel {
  get bookingDate => null;
}

class PaymentConfirmationPage extends StatelessWidget {
  final double totalPrice;
  final String bookingDate;

  const PaymentConfirmationPage({
    super.key,
    required this.totalPrice,
    required this.bookingDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Pembayaran'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Tanggal booking: $bookingDate',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Total Harga: Rp. $totalPrice',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              color: Colors.black,
              child: const Text(
                'Konfirmasi dan bayar',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                // Proses pembayaran
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Proses Pembayaran Berhasil'),
                    content: const Text('Pemesanan Anda telah dikonfirmasi.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.popUntil(
                            context, (route) => route.isFirst),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}