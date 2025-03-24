import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/pages/models/cart_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mandalaarenaapp/pages/models/lapang.dart';

class Cart extends ChangeNotifier {
  final List<CartModel> _cart = [];

  List<CartModel> get cart => _cart;

  Future<void> addToCart(
    String userId,
    String docId,
    Lapang lapangItem,
    int bookingDuration,
    String bookingDate,
    String selectedHour,
    num totalPrice,
    bool usePhotographer,
    bool useReferee,
    String teamName, // Tambahkan parameter teamName
  ) async {
    try {
      // Ambil data pengguna dari Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception("User data not found in Firestore.");
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      String userName = userData['name'] ?? 'Unknown User';
      String userPhone = userData['phone'] ?? '';

      // Konversi jamMulai ke format DateTime
      DateTime selectedTime = DateFormat('HH:mm').parse(selectedHour);
      String jamSelesai = DateFormat('HH:mm').format(
        selectedTime.add(Duration(hours: bookingDuration)),
      );

      // Simpan data booking ke Firestore dengan format yang sesuai
      await FirebaseFirestore.instance.collection('bookings').doc(docId).set({
        'lapangan': lapangItem.name,
        'tanggal': bookingDate,
        'jamMulai': selectedHour,
        'jamSelesai': jamSelesai,
        'statusBooking': 'Pending',
        'price': lapangItem.price,
        'imagePath': lapangItem.imagePath,
        'lapangId': lapangItem.id,
        'userId': userId,
        'namaPengguna': userName,
        'noWhatsapp': userPhone,
        'duration': bookingDuration.toString(),
        'usePhotographer': usePhotographer,
        'useReferee': useReferee,
        'totalPrice': totalPrice,
        'teamName': teamName, // Simpan teamName
      });

      // Tambahkan ke lokal cart
      _cart.add(
        CartModel(
          userId: userId,
          docId: docId,
          id: lapangItem.id,
          name: lapangItem.name,
          price: lapangItem.price,
          imagePath: lapangItem.imagePath,
          quantity: bookingDuration.toString(),
          bookingDate: bookingDate,
          time: selectedHour,
          duration: bookingDuration,
          namaPengguna: userName,
          noWhatsapp: userPhone,
          usePhotographer: usePhotographer,
          useReferee: useReferee,
          teamName: teamName, // Simpan teamName
        ),
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding item to cart: $e');
    }
  }

  Future<void> removeItemByDocId(String docId) async {
    try {
      final index = _cart.indexWhere((item) => item.docId == docId);
      if (index != -1) {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(docId)
            .delete();
        _cart.removeAt(index);
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

        _cart.removeWhere((cartItem) =>
            cartItem.id == item.id &&
            cartItem.bookingDate == item.bookingDate &&
            cartItem.time == item.time &&
            cartItem.duration == item.duration);
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

  Future<void> fetchCartForUser(String userId) async {
    try {
      _cart.clear();

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId) // Filter berdasarkan userId
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        _cart.add(
          CartModel(
            userId: data['userId'],
            docId: doc.id,
            id: data['lapangId'],
            name: data['lapangan'], // Sesuai dengan format baru
            price: data['price'],
            imagePath: data['imagePath'],
            quantity: data['duration'], // Durasi sebagai quantity
            bookingDate: data['tanggal'],
            time: data['jamMulai'],
            duration: int.tryParse(data['duration'].toString()) ?? 0,
            namaPengguna: data['namaPengguna'],
            noWhatsapp: data['noWhatsapp'],
            usePhotographer:
                data['usePhotographer'] ?? false, // Ambil data photographer
            useReferee: data['useReferee'] ?? false, // Ambil data wasit
          ),
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching cart data: $e');
    }
  }

  Future<void> loadCart(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();

      _cart.clear(); // Kosongkan cart sebelum memuat ulang

      for (var doc in snapshot.docs) {
        final data = doc.data();

        _cart.add(
          CartModel(
            userId: data['userId'],
            docId: doc.id,
            id: data['lapangId'],
            name: data['lapangan'], // Sesuai dengan format terbaru
            price: data['price'],
            imagePath: data['imagePath'],
            quantity: data['duration'], // Durasi sebagai quantity
            bookingDate: data['tanggal'],
            time: data['jamMulai'],
            duration: int.tryParse(data['duration'].toString()) ?? 0,
            namaPengguna: data['namaPengguna'],
            noWhatsapp: data['noWhatsapp'],
            usePhotographer:
                data['usePhotographer'] ?? false, // Ambil data photographer
            useReferee: data['useReferee'] ?? false, // Ambil data wasit
          ),
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cart: $e');
    }
  }

  double calculateTotalPrice() {
    return _cart.fold(0, (total, item) {
      final price = double.tryParse(item.price ?? '0') ?? 0;
      final quantity = int.tryParse(item.quantity ?? '0') ?? 0;
      double itemTotal = price * quantity;

      // Tambahkan biaya photographer jika digunakan
      if (item.usePhotographer ?? false) {
        itemTotal += 200000; // Biaya tambahan photographer
      }

      // Tambahkan biaya wasit jika digunakan
      if (item.useReferee ?? false) {
        itemTotal += 70000; // Biaya tambahan wasit
      }

      return total + itemTotal;
    });
  }
}
