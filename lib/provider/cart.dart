// ignore_for_file: prefer_final_fields

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/pages/models/cart_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mandalaarenaapp/pages/models/lapang.dart';

class Cart extends ChangeNotifier {
  List<CartModel> _cart = [];
  String? _currentUserId;

  List<CartModel> get cart => _cart;

  Future<void> updateUserAndLoadCart(String? newUserId) async {
    if (_currentUserId != newUserId) {
      print(
          "Auth state changed! Old User: $_currentUserId, New User: $newUserId");
      _currentUserId = newUserId;
      if (newUserId != null && newUserId.isNotEmpty) {
        await loadCart(newUserId);
      } else {
        notifyListeners();
      }
    }
  }

  // --- [MODIFIKASI] Tambahkan parameter useIceBath ---
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
    String teamName,
    bool useIceBath, // Parameter baru
  ) async {
    try {
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

      DateTime selectedTime = DateFormat('HH:mm').parse(selectedHour);
      String jamSelesai = DateFormat('HH:mm').format(
        selectedTime.add(Duration(hours: bookingDuration)),
      );

      // --- [MODIFIKASI] Simpan data useIceBath ke Firestore ---
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
        'useIceBath': useIceBath, // Simpan status ice bath
        'totalPrice': totalPrice,
        'teamName': teamName,
      });

      // --- [MODIFIKASI] Tambahkan useIceBath ke CartModel lokal ---
      // Catatan: Pastikan Anda juga menambahkan `useIceBath` di file `cart_model.dart`
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
          useIceBath: useIceBath, // Tambahkan di sini
          teamName: teamName,
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
        if (item.docId != null && item.docId!.isNotEmpty) {
          batch.delete(FirebaseFirestore.instance
              .collection('bookings')
              .doc(item.docId));
        }
      }

      await batch.commit();

      _cart.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      rethrow;
    }
  }

  Future<void> fetchCartForUser(String userId) async {
    try {
      _cart.clear();

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // --- [MODIFIKASI] Ambil data 'useIceBath' saat fetch ---
        _cart.add(
          CartModel(
            userId: data['userId'],
            docId: doc.id,
            id: data['lapangId'],
            name: data['lapangan'],
            price: data['price'],
            imagePath: data['imagePath'],
            quantity: data['duration'],
            bookingDate: data['tanggal'],
            time: data['jamMulai'],
            duration: int.tryParse(data['duration'].toString()) ?? 0,
            namaPengguna: data['namaPengguna'],
            noWhatsapp: data['noWhatsapp'],
            usePhotographer: data['usePhotographer'] ?? false,
            useReferee: data['useReferee'] ?? false,
            useIceBath: data['useIceBath'] ?? false, // Ambil data ice bath
            teamName: data['teamName'] ?? '',
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
          .where('statusBooking',
              whereIn: ['Pending', 'Booking (Bayar di Tempat)']).get();

      _cart.clear();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['lapangan'] != null &&
            data['tanggal'] != null &&
            data['jamMulai'] != null) {
          // --- [MODIFIKASI] Ambil data 'useIceBath' saat load ---
          _cart.add(
            CartModel(
              userId: data['userId'] ?? '',
              docId: doc.id,
              id: data['lapangId'] ?? '',
              name: data['lapangan'] ?? '',
              price: data['price']?.toString() ?? '0',
              imagePath: data['imagePath'] ?? '',
              quantity: data['duration']?.toString() ?? '0',
              bookingDate: data['tanggal'] ?? '',
              time: data['jamMulai'] ?? '',
              duration: int.tryParse(data['duration']?.toString() ?? '0') ?? 0,
              namaPengguna: data['namaPengguna'] ?? '',
              noWhatsapp: data['noWhatsapp'] ?? '',
              usePhotographer: data['usePhotographer'] ?? false,
              useReferee: data['useReferee'] ?? false,
              useIceBath: data['useIceBath'] ?? false, // Ambil data ice bath
              teamName: data['teamName'] ?? '',
            ),
          );
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cart: $e');
      rethrow;
    }
  }

  // --- [MODIFIKASI] Perbarui kalkulasi total harga ---
  double calculateTotalPrice() {
    return _cart.fold(0, (total, item) {
      final price = double.tryParse(item.price ?? '0') ?? 0;
      final quantity = int.tryParse(item.quantity ?? '0') ?? 0;
      double itemTotal = price * quantity;

      if (item.usePhotographer ?? false) {
        itemTotal += 200000;
      }

      if (item.useReferee ?? false) {
        itemTotal += 70000;
      }

      // Tambahkan biaya ice bath jika digunakan
      if (item.useIceBath ?? false) {
        itemTotal += 50000; // Harga ice bath
      }

      return total + itemTotal;
    });
  }
}
