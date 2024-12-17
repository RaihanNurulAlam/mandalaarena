import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/pages/models/cart_model.dart';
import 'package:mandalaarenaapp/pages/models/lapang.dart';

class Cart extends ChangeNotifier {
  // List untuk menyimpan item dalam bentuk CartModel
  final List<CartModel> _cart = [];
  final List<String> _items = [];

  // Getter untuk CartModel
  List<CartModel> get cart => _cart;

  // Getter untuk item sederhana
  List<String> get items => _items;

  // Tambahkan item ke dalam keranjang dengan objek Lapang
  void addToCart(Lapang lapangItem, int qty) {
    _cart.add(
      CartModel(
        name: lapangItem.name,
        price: lapangItem.price,
        imagePath: lapangItem.imagePath,
        quantity: qty.toString(),
      ),
    );
    notifyListeners();
  }

  // Tambahkan item sederhana berupa String
  void addItem(String item) {
    _items.add(item);
    notifyListeners();
  }

  // Hapus item sederhana dari keranjang
  void removeItem(String item) {
    _items.remove(item);
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
    _items.clear();
    notifyListeners();
  }
}
