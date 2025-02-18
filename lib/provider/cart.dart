// ignore_for_file: cast_from_null_always_fails, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/pages/models/cart_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mandalaarenaapp/pages/models/lapang.dart';

class Cart extends ChangeNotifier {
  final List<CartModel> _cart = [];

  List<CartModel> get cart => _cart;

  Future<void> addToCart(
    String docId,
    Lapang lapangItem,
    int bookingDuration,
    String bookingDate,
    String selectedHour,
    num totalPrice, // Bisa menampung int maupun double
  ) async {
    try {
      _cart.add(
        CartModel(
          docId: docId,
          id: lapangItem.id,
          name: lapangItem.name,
          price: lapangItem.price, // Simpan sebagai string di model
          imagePath: lapangItem.imagePath,
          quantity: bookingDuration.toString(),
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

  /// Menghapus item dari cart berdasarkan docId
  Future<void> removeItemByDocId(String docId) async {
    try {
      // Temukan item di cart yang docId-nya sama
      final itemToRemove = _cart.firstWhere(
        (item) => item.docId == docId,
        orElse: () => null as CartModel,
      );

      if (itemToRemove != null) {
        // Hapus dari Firestore
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(docId)
            .delete();

        // Hapus dari list cart
        _cart.remove(itemToRemove);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error removing item by docId: $e');
    }
  }

  Future<void> deleteItemCart(CartModel item) async {
    try {
      // Jika docId null, fallback pakai field lain
      if (item.docId != null && item.docId!.isNotEmpty) {
        await removeItemByDocId(item.docId!);
      } else {
        final bookingRef = FirebaseFirestore.instance
            .collection('bookings')
            .where('lapangId', isEqualTo: item.id)
            .where('tanggal', isEqualTo: item.bookingDate)
            .where('jamMulai', isEqualTo: item.time)
            .where('duration', isEqualTo: item.duration.toString());

        final snapshot = await bookingRef.get();
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }

        _cart.remove(item);
        notifyListeners();
      }
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
            .where('lapangId', isEqualTo: item.id)
            .where('tanggal', isEqualTo: item.bookingDate)
            .where('jamMulai', isEqualTo: item.time)
            .where('duration', isEqualTo: item.duration.toString());

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
