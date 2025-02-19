// ignore_for_file: unused_local_variable, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  @override
  void initState() {
    super.initState();

    final cartProvider = Provider.of<Cart>(context, listen: false);

    // Ambil userId dari FirebaseAuth
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      cartProvider
          .loadCart(user.uid); // Memuat data terbaru saat halaman dibuka
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final cartProvider = context.watch<Cart>();

    return Consumer<Cart>(
      builder: (context, cart, child) {
        // Menghitung total harga berdasarkan data dari cart provider
        double totalPrice = cart.cart.fold(0, (previousValue, cartModel) {
          final double price = double.tryParse(cartModel.price ?? '0') ?? 0;
          final int quantity = int.tryParse(cartModel.quantity ?? '1') ?? 1;
          return previousValue + (price * quantity);
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Keranjang'),
            actions: [
              // Tampilkan tombol "Hapus Semua" hanya jika cart tidak kosong
              if (cart.cart.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    onPressed: () async {
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Konfirmasi Hapus Semua'),
                          content: const Text(
                              'Apakah Anda yakin ingin menghapus semua item di keranjang?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Hapus Semua'),
                            ),
                          ],
                        ),
                      );

                      if (shouldDelete == true) {
                        try {
                          await cart.clearCart();
                          // Tidak perlu setState() karena notifyListeners() pada clearCart sudah trigger rebuild
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Gagal menghapus semua item. Coba lagi.')),
                          );
                        }
                      }
                    },
                    icon: const Text('Hapus Semua'),
                  ),
                ),
            ],
          ),
          body: cart.cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Keranjang Kosong',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      CupertinoButton(
                        color: Colors.black,
                        child: const Text(
                          'Lakukan Booking',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomePage(),
                            ),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: cart.cart.length,
                        itemBuilder: (context, index) {
                          final item = cart.cart[index];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                height: 50,
                                width: 50,
                                child: Image.asset(
                                  item.imagePath.toString(),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            title: Text(
                              item.name.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                    'Rp. ${item.price} x ${item.quantity} Jam'),
                              ],
                            ),
                            trailing: IconButton(
                              onPressed: () async {
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Konfirmasi Hapus'),
                                    content: const Text(
                                        'Yakin ingin menghapus item ini dari keranjang?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Batal'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldDelete == true) {
                                  try {
                                    await cart.deleteItemCart(item);
                                    // Tidak perlu setState(), karena notifyListeners() akan rebuild widget
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Gagal menghapus item. Silakan coba lagi.')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(
                                CupertinoIcons.trash_circle,
                                color: Colors.black,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 80),
                    CupertinoButton(
                      child: const Text(
                        'Tambah Booking Lapang',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
          bottomNavigationBar: totalPrice == 0
              ? null
              : Container(
                  color: Colors.black,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.black,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Harga',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              'Rp. $totalPrice',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        width: MediaQuery.of(context).size.width,
                        child: CupertinoButton(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(50),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Bayar Sekarang',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Urbanist',
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(
                                CupertinoIcons.arrow_right,
                                color: Colors.white,
                              ),
                            ],
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
