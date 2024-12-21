import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/pages/models/cart_model.dart';
import 'package:mandalaarenaapp/pages/models/lapang.dart';

class Cart extends ChangeNotifier {
  // List untuk menyimpan item dalam bentuk CartModel
  final List<CartModel> _cart = [];

  // Getter untuk keranjang (list CartModel)
  List<CartModel> get cart => _cart;

  // Tambahkan item ke dalam keranjang dengan objek Lapang
  void addToCart(Lapang lapangItem, int qty, dynamic bookingDate) {
    // Cek jika item sudah ada di keranjang
    final existingItemIndex = _cart.indexWhere((item) => item.name == lapangItem.name);
    if (existingItemIndex != -1) {
      // Update quantity jika item sudah ada
      final existingItem = _cart[existingItemIndex];
      int currentQty = int.tryParse(existingItem.quantity ?? '0') ?? 0;
      existingItem.quantity = (currentQty + qty).toString();
    } else {
      // Tambahkan item baru
      _cart.add(
        CartModel(
          name: lapangItem.name,
          price: lapangItem.price,
          imagePath: lapangItem.imagePath,
          quantity: qty.toString(),
          bookingDate: bookingDate,
        ),
      );
    }
    notifyListeners();
  }

  // Hapus satu item dalam bentuk CartModel
  void deleteItemCart(CartModel item) {
    _cart.remove(item);
    notifyListeners();
  }

  // Bersihkan semua item dari keranjang
  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // Metode untuk menghitung total harga
  double calculateTotalPrice() {
    double total = 0;
    for (var item in _cart) {
      final price = double.tryParse(item.price ?? '0') ?? 0;
      final quantity = int.tryParse(item.quantity ?? '0') ?? 0;
      total += price * quantity;
    }
    return total;
  }
}
