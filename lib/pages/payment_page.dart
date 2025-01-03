// ignore_for_file: deprecated_member_use, unused_element, unused_local_variable

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/pages/models/cart_model.dart';
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
                    onPressed: () {
                      // Lanjutkan ke konfirmasi pembayaran
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentConfirmationPage(
                            totalPrice: totalPrice,
                            bookingDate: bookingDate,
                          ),
                        ),
                      );
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
