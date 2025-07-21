// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously, avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/pages/models/cart_model.dart';
import 'package:mandalaarenaapp/pages/payment_page.dart';
import 'package:mandalaarenaapp/pages/home_page.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart';

class CartPage extends StatefulWidget {
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Helper function untuk menghitung harga per jam (sama seperti di PaymentPage)
  int _getPriceForHour(int hour, String lapangName, int basePrice) {
    if (lapangName == "Lapang Minisoccer") {
      if (hour >= 7 && hour < 14) return basePrice; // Pagi
      if (hour >= 14 && hour < 18) return basePrice + 100000; // Siang
      if (hour >= 18 && hour < 23) return basePrice + 200000; // Malam
    } else if (lapangName == "Lapang Basket Vynil") {
      if (hour >= 7 && hour < 14) return basePrice; // Pagi
      if (hour >= 14 && hour < 18) return basePrice + 50000; // Siang
      if (hour >= 18 && hour < 23) return basePrice + 100000; // Malam
    } else if (lapangName == "Lapang Basket Karet") {
      if (hour >= 7 && hour < 14) return basePrice; // Pagi
      if (hour >= 14 && hour < 18) return basePrice + 25000; // Siang
      if (hour >= 18 && hour < 23) return basePrice + 50000; // Malam
    }
    return basePrice;
  }

  @override
  void initState() {
    super.initState();
    _loadCartData();
  }

  Future<void> _loadCartData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cart = Provider.of<Cart>(context, listen: false);
      await cart.loadCart(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final cart = context.watch<Cart>();
    final currencyFormatter =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    List<Map<String, dynamic>> detailedItems = [];
    double grandTotal = 0;

    // --- LOGIKA PERHITUNGAN HARGA KONSISTEN ---
    for (final item in cart.cart) {
      int baseBookingPrice = 0;
      final int startHour = int.tryParse(item.time?.split(":")[0] ?? '0') ?? 0;
      final int duration = int.tryParse(item.quantity ?? '1') ?? 1;
      final int basePricePerHour = int.tryParse(item.price ?? '0') ?? 0;

      for (int i = 0; i < duration; i++) {
        baseBookingPrice +=
            _getPriceForHour(startHour + i, item.name ?? '', basePricePerHour);
      }

      double discountAmount = 0;
      if (userProvider.isMember) {
        discountAmount = baseBookingPrice * 0.10; // Diskon 10%
      }

      double addonsTotalPrice = 0;
      if (item.usePhotographer ?? false) addonsTotalPrice += 200000;
      if (item.useReferee ?? false) addonsTotalPrice += 70000;
      if (item.useIceBath ?? false) addonsTotalPrice += 50000;

      double finalItemPrice =
          (baseBookingPrice - discountAmount) + addonsTotalPrice;
      grandTotal += finalItemPrice;

      detailedItems.add({
        'item': item,
        'baseBookingPrice': baseBookingPrice.toDouble(),
        'discountAmount': discountAmount,
        'addonsPrice': addonsTotalPrice,
        'finalPrice': finalItemPrice,
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        actions: [
          if (cart.cart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: () async {
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Konfirmasi'),
                      content: const Text(
                          'Yakin ingin menghapus semua item di keranjang?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Hapus Semua'),
                        ),
                      ],
                    ),
                  );

                  if (shouldDelete == true) {
                    await cart.clearCart();
                  }
                },
                child: const Text('Hapus Semua',
                    style: TextStyle(color: Colors.red)),
              ),
            ),
        ],
      ),
      body: cart.cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Keranjang Kosong',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  CupertinoButton(
                    color: Colors.black,
                    child: const Text('Lakukan Booking',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage()),
                        (route) => false),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Daftar item yang ada di keranjang
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: detailedItems.length,
                    itemBuilder: (context, index) {
                      final details = detailedItems[index];
                      final CartModel item = details['item'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.asset(item.imagePath ?? '',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name ?? 'Nama Lapang',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(
                                            'Jadwal: ${item.bookingDate}, ${item.time} (${item.quantity} jam)'),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () async {
                                      await cart.deleteItemCart(item);
                                    },
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              const Text('Rincian Harga',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              _buildPriceRow(
                                  'Harga Booking', details['baseBookingPrice']),
                              if (details['discountAmount'] > 0)
                                _buildPriceRow('Diskon Member (10%)',
                                    -details['discountAmount'],
                                    isDiscount: true),
                              if (details['addonsPrice'] > 0)
                                _buildPriceRow(
                                    'Layanan Tambahan', details['addonsPrice']),
                              const Divider(thickness: 1, height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal Item',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text(
                                    currencyFormatter
                                        .format(details['finalPrice']),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- FITUR YANG DITAMBAHKAN KEMBALI ---
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Tambah Booking Lain'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => HomePage()),
                          (route) => false);
                    },
                  ),
                  const SizedBox(height: 20), // Memberi jarak ke bottom bar
                ],
              ),
            ),
      bottomNavigationBar: grandTotal == 0
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Harga',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                      Text(currencyFormatter.format(grandTotal),
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(
                    height: 50,
                    child: CupertinoButton(
                      color: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      borderRadius: BorderRadius.circular(50),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PaymentPage())),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Bayar Sekarang',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(CupertinoIcons.arrow_right,
                              color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPriceRow(String title, double amount,
      {bool isDiscount = false}) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    final Color color = isDiscount ? Colors.green : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: color)),
          Text(
            currencyFormatter.format(amount),
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
