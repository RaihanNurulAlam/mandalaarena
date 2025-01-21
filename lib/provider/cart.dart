// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/pages/models/cart_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mandalaarenaapp/pages/models/lapang.dart';

class Cart extends ChangeNotifier {
  final List<CartModel> _cart = [];

  List<CartModel> get cart => _cart;

  Future<void> addToCart(Lapang lapangItem, int qty, dynamic bookingDate,
      String selectedHour, int bookingDuration) async {
    try {
      final bookingRef = FirebaseFirestore.instance.collection('bookings');
      // final newBooking = {
      //   'lapangId': lapangItem.id, // Use lapangId from JSON
      //   'price': lapangItem.price,
      //   'image_path': lapangItem.imagePath,
      //   'quantity': qty.toString(),
      //   'date': bookingDate,
      //   'time': selectedHour,
      //   'duration': bookingDuration,
      // };
      // final docRef = await bookingRef.add(newBooking);

      _cart.add(
        CartModel(
          // id: docRef.id,
          id: lapangItem.id, // Use lapangId from JSON
          name: lapangItem.name,
          price: lapangItem.price,
          imagePath: lapangItem.imagePath,
          quantity: qty.toString(),
          bookingDate: bookingDate,
          time: selectedHour,
          duration: bookingDuration,
        ),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding item to cart: $e');
    }
  }

  Future<void> deleteItemCart(CartModel item) async {
    try {
      final bookingRef = FirebaseFirestore.instance
          .collection('bookings')
          .where('lapangId', isEqualTo: item.id) // Use lapangId instead of name
          .where('date', isEqualTo: item.bookingDate)
          .where('time', isEqualTo: item.time)
          .where('duration', isEqualTo: item.duration);

      final snapshot = await bookingRef.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      _cart.remove(item);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting item from Firebase: $e');
    }
  }

  Future<void> clearCart() async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (var item in _cart) {
        final bookingRef = FirebaseFirestore.instance
            .collection('bookings')
            .where('lapangId',
                isEqualTo: item.id) // Use lapangId instead of name
            .where('date', isEqualTo: item.bookingDate)
            .where('time', isEqualTo: item.time)
            .where('duration', isEqualTo: item.duration);

        final snapshot = await bookingRef.get();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();

      _cart.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing cart in Firebase: $e');
    }
  }

  double calculateTotalPrice() {
    return _cart.fold(0, (total, item) {
      final price = double.tryParse(item.price ?? '0') ?? 0;
      final quantity = int.tryParse(item.quantity ?? '0') ?? 0;
      return total + price * quantity;
    });
  }
}
