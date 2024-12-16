import 'package:flutter/cupertino.dart';
import 'package:mandalaarenaapp/pages/models/cart_model.dart';
import 'package:mandalaarenaapp/pages/models/lapang.dart';

class Cart extends ChangeNotifier {
  final List<CartModel> _cart = [];

  List<CartModel> get cart => _cart;

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

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  void deleteItemCart(CartModel item) {
    _cart.remove(item);
    notifyListeners();
  }
}
