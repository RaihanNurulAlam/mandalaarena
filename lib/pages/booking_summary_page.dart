// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously, avoid_print, deprecated_member_use, avoid_types_as_parameter_names

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/pages/admin_home_page.dart';
import 'package:mandalaarenaapp/pages/home_page.dart';
import 'package:mandalaarenaapp/pages/models/cart_model.dart';
import 'package:mandalaarenaapp/pages/riwayat_pembayaran.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class BookingSummaryPage extends StatefulWidget {
  @override
  State<BookingSummaryPage> createState() => _BookingSummaryPageState();
}

class _BookingSummaryPageState extends State<BookingSummaryPage> {
  // State dari PaymentPage
  String? transactionStatus;
  bool isProcessingPayment = false;
  bool showPaymentPopup = false;
  String? paymentUrl;
  String? currentOrderId;
  Timer? _cartCleanUpTimer;

  @override
  void initState() {
    super.initState();
    // Memuat data keranjang dan melakukan pembersihan awal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndCleanCart();
    });

    // BARU: Setel Timer untuk memeriksa keranjang secara berkala (misal: setiap 30 detik)
    _cartCleanUpTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // Pastikan widget masih ada di tree sebelum menjalankan pengecekan
      if (mounted) {
        print("Timer berjalan: Memeriksa booking yang kedaluwarsa...");
        _removeExpiredBookings();
      }
    });
  }

  @override
  void dispose() {
    _cartCleanUpTimer?.cancel();
    super.dispose();
  }

  /// Memuat data keranjang dari Firebase dan membersihkan item yang sudah kedaluwarsa.
  Future<void> _loadAndCleanCart() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cart = Provider.of<Cart>(context, listen: false);
      await cart.loadCart(user.uid);
      // Panggil fungsi untuk menghapus item kedaluwarsa setelah data dimuat
      await _removeExpiredBookings();
    }
  }

  /// **FITUR BARU: Hapus item booking yang waktunya sudah terlewat.**
  Future<void> _removeExpiredBookings() async {
    final cart = Provider.of<Cart>(context, listen: false);
    if (cart.cart.isEmpty) return;

    final now = DateTime.now();
    // BARU: Sesuaikan format parser dengan data Anda
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    List<CartModel> expiredItems = [];

    for (final item in cart.cart) {
      try {
        // String gabungan akan menjadi "2025-07-25 09:00"
        final String dateTimeString = '${item.bookingDate} ${item.time}';
        final DateTime bookingDateTime = formatter.parse(dateTimeString);

        if (bookingDateTime.isBefore(now)) {
          expiredItems.add(item);
        }
      } catch (e) {
        print("Error parsing date untuk item ${item.name}: $e");
        print(
            "Data string yang gagal di-parse: '${item.bookingDate} ${item.time}'");
      }
    }

    if (expiredItems.isNotEmpty) {
      int expiredCount = expiredItems.length;
      for (final item in expiredItems) {
        await cart.deleteItemCart(item);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '$expiredCount item booking yang kedaluwarsa telah dihapus.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // --- SEMUA LOGIKA DARI CARTPAGE & PAYMENTPAGE DIGABUNG DI SINI ---

  int _getPriceForHour(int hour, String lapangName, int basePrice) {
    if (lapangName == "Lapang Minisoccer") {
      if (hour >= 7 && hour < 14) return basePrice;
      if (hour >= 14 && hour < 18) return basePrice + 100000;
      if (hour >= 18 && hour < 23) return basePrice + 200000;
    } else if (lapangName == "Lapang Basket Vynil") {
      if (hour >= 7 && hour < 14) return basePrice;
      if (hour >= 14 && hour < 18) return basePrice + 50000;
      if (hour >= 18 && hour < 23) return basePrice + 100000;
    } else if (lapangName == "Lapang Basket Karet") {
      if (hour >= 7 && hour < 14) return basePrice;
      if (hour >= 14 && hour < 18) return basePrice + 25000;
      if (hour >= 18 && hour < 23) return basePrice + 50000;
    }
    return basePrice;
  }

  String getBaseUrl() {
    const baseUrl = 'https://api-ygvy5l5oeq-uc.a.run.app';
    if (kDebugMode) {
      print('Using base URL: $baseUrl');
    }
    return baseUrl;
  }

  // Fungsi-fungsi dari PaymentPage (di-copy-paste ke sini)
  Future<void> _createBookingDocument(String orderId, double grandTotal) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final cart = Provider.of<Cart>(context, listen: false);

    // Hitung ulang rincian harga untuk disimpan
    double totalBaseBookingPrice = 0;
    double totalDiscountAmount = 0;
    double totalAddonsPrice = 0;

    for (final item in cart.cart) {
      int baseBookingPriceForItem = 0;
      final int startHour = int.tryParse(item.time?.split(":")[0] ?? '0') ?? 0;
      final int duration = int.tryParse(item.quantity ?? '1') ?? 1;
      final int basePricePerHour = int.tryParse(item.price ?? '0') ?? 0;

      for (int i = 0; i < duration; i++) {
        baseBookingPriceForItem +=
            _getPriceForHour(startHour + i, item.name ?? '', basePricePerHour);
      }
      totalBaseBookingPrice += baseBookingPriceForItem;

      if (userProvider.isMember) {
        totalDiscountAmount += baseBookingPriceForItem * 0.10;
      }

      if (item.usePhotographer ?? false) totalAddonsPrice += 200000;
      if (item.useReferee ?? false) totalAddonsPrice += 70000;
      if (item.useIceBath ?? false) totalAddonsPrice += 50000;
    }

    final bookingData = {
      'orderId': orderId,
      'userId': userProvider.userId,
      'userName': userProvider.userName,
      'userEmail': userProvider.userEmail,
      'userPhone': userProvider.userPhone,
      'statusBooking': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
      'items': cart.cart.map((item) => item.toMap()).toList(),
      'totalAmount': grandTotal,
      'baseBookingPrice': totalBaseBookingPrice,
      'discountAmount': totalDiscountAmount,
      'addonsPrice': totalAddonsPrice,
      'isMember': userProvider.isMember,
      'pointsAwarded': false,
    };

    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(orderId)
        .set(bookingData);
  }

  Future<void> updateBookingStatus(String orderId, String status) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(orderId)
        .update({'statusBooking': status});
  }

  Future<void> _completePayment(String orderId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final cart = Provider.of<Cart>(context, listen: false);

    try {
      final bookingDocRef =
          FirebaseFirestore.instance.collection('bookings').doc(orderId);
      final bookingDoc = await bookingDocRef.get();
      if (!bookingDoc.exists) return;

      await updateBookingStatus(orderId, 'Sudah Bayar');

      final bool pointsAlreadyAwarded =
          bookingDoc.data()?['pointsAwarded'] == true;

      if (!pointsAlreadyAwarded && userProvider.isMember) {
        int earnedPoints = cart.cart.fold(
            0, (sum, item) => sum + (int.tryParse(item.quantity ?? '1') ?? 1));
        if (earnedPoints > 0) {
          String imageUrl =
              cart.cart.isNotEmpty ? cart.cart.first.imagePath ?? '' : '';
          await _updateUserPoints(
              userProvider.userId, earnedPoints, userProvider);
          await _saveUserPointsTransaction(
              userProvider.userId, earnedPoints, orderId, imageUrl);
          await bookingDocRef.update({'pointsAwarded': true});
        }
      } else {
        await bookingDocRef.update({'pointsAwarded': true});
      }

      await cart.clearCart();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const TransactionHistoryPage()),
        );
      }
    } catch (e) {
      print('Error completing payment: $e');
    }
  }

  Future<void> _updateUserPoints(
      String userId, int earnedPoints, UserProvider provider) async {
    if (userId.isEmpty || earnedPoints <= 0) return;
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    int newTotalPoints = 0;
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) throw Exception("User tidak ditemukan");
      int currentPoints = userDoc.data()?['points'] ?? 0;
      newTotalPoints = currentPoints + earnedPoints;
      transaction.update(userRef, {'points': newTotalPoints});
    });
    provider.updateUserPoints(newTotalPoints);
  }

  Future<void> _saveUserPointsTransaction(
      String userId, int earnedPoints, String orderId, String imageUrl) async {
    if (earnedPoints <= 0) return;
    await FirebaseFirestore.instance.collection('points').doc().set({
      'userId': userId,
      'points': earnedPoints,
      'orderId': orderId,
      'type': 'earned',
      'timestamp': FieldValue.serverTimestamp(),
      'description': 'Poin dari pembayaran booking',
      'status': 'Berhasil',
      'imageUrl': imageUrl,
    });
  }

  Future<void> checkTransactionStatus(String orderId) async {
    try {
      final baseUrl = getBaseUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/transaction-status?orderId=$orderId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => transactionStatus = data['transaction_status']);
        if (transactionStatus == 'settlement' ||
            transactionStatus == 'capture') {
          await _completePayment(orderId);
        }
      }
    } catch (e) {
      print('Error checking transaction status: $e');
    }
  }

  Future<void> initiateMidtransPayment(double grandTotal) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() => isProcessingPayment = true);

    try {
      final orderId =
          'ORDER-${DateTime.now().millisecondsSinceEpoch}-${userProvider.userId.substring(0, 5)}';
      await _createBookingDocument(orderId, grandTotal);

      final baseUrl = getBaseUrl();
      final response = await http
          .post(
            Uri.parse('$baseUrl/pay'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'orderId': orderId,
              'grossAmount': grandTotal.toString(),
              'firstName': userProvider.userName.split(' ').first,
              'lastName': userProvider.userName.split(' ').length > 1
                  ? userProvider.userName.split(' ').sublist(1).join(' ')
                  : '',
              'email': userProvider.userEmail,
              'phone': userProvider.userPhone,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          showPaymentPopup = true;
          paymentUrl = data['redirect_url'];
          currentOrderId = orderId;
        });
        if (kIsWeb && paymentUrl != null) {
          await launchUrl(Uri.parse(paymentUrl!),
              mode: LaunchMode.externalApplication);
        }
      } else {
        throw Exception('Failed to create transaction: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => isProcessingPayment = false);
    }
  }

  Future<void> initiateOnSitePayment(double grandTotal) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final cart = Provider.of<Cart>(context, listen: false);
    setState(() => isProcessingPayment = true);

    try {
      final orderId =
          'ORDER-${DateTime.now().millisecondsSinceEpoch}-${userProvider.userId.substring(0, 5)}';
      await _createBookingDocument(orderId, grandTotal);
      await updateBookingStatus(orderId, 'Booking (Bayar di Tempat)');

      double totalBaseBookingPrice = 0;
      for (final item in cart.cart) {
        int baseBookingPriceForItem = 0;
        final int startHour =
            int.tryParse(item.time?.split(":")[0] ?? '0') ?? 0;
        final int duration = int.tryParse(item.quantity ?? '1') ?? 1;
        final int basePricePerHour = int.tryParse(item.price ?? '0') ?? 0;
        for (int i = 0; i < duration; i++) {
          baseBookingPriceForItem += _getPriceForHour(
              startHour + i, item.name ?? '', basePricePerHour);
        }
        totalBaseBookingPrice += baseBookingPriceForItem;
      }
      final dpAmount = totalBaseBookingPrice * 0.10;
      final currencyFormatter =
          NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
      final formattedDp = currencyFormatter.format(dpAmount);
      final formattedTotal = currencyFormatter.format(grandTotal);

      final bookingDetails = cart.cart
          .map((item) =>
              'Lapangan: ${item.name}\nTanggal: ${item.bookingDate}\nJam: ${item.time} (${item.quantity} jam)')
          .join('\n\n');
      final whatsappMessage = '''
Halo Admin Mandala Arena,
Saya ingin melakukan booking dengan detail berikut:

$bookingDetails

Nama: ${userProvider.userName}
No. HP: ${userProvider.userPhone}
Total Tagihan: *$formattedTotal*

Saya memilih untuk *Bayar di Tempat* dan akan melakukan transfer DP sebesar *$formattedDp* (10% dari harga sewa lapang). Mohon info rekening tujuan.

Terima kasih.
''';
      final encodedMessage = Uri.encodeComponent(whatsappMessage);
      final whatsappUrl = 'https://wa.me/6281111122525?text=$encodedMessage';

      await cart.clearCart();
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
      }

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const TransactionHistoryPage()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => isProcessingPayment = false);
    }
  }

  void _closePaymentPopup() async {
    setState(() => showPaymentPopup = false);
    if (currentOrderId != null) {
      await checkTransactionStatus(currentOrderId!);
      if (transactionStatus == null || transactionStatus == 'pending') {
        try {
          await FirebaseFirestore.instance
              .collection('bookings')
              .doc(currentOrderId)
              .delete();
          print('Booking data deleted due to incomplete payment.');
        } catch (e) {
          print('Error deleting booking data: $e');
        }
      }
    }
  }

  void _showElegantPaymentMethodSheet(double grandTotal) {
    final cart = Provider.of<Cart>(context, listen: false);
    final currencyFormatter =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    double totalBaseBookingPrice = 0;
    for (final item in cart.cart) {
      int baseBookingPriceForItem = 0;
      final int startHour = int.tryParse(item.time?.split(":")[0] ?? '0') ?? 0;
      final int duration = int.tryParse(item.quantity ?? '1') ?? 1;
      final int basePricePerHour = int.tryParse(item.price ?? '0') ?? 0;
      for (int i = 0; i < duration; i++) {
        baseBookingPriceForItem +=
            _getPriceForHour(startHour + i, item.name ?? '', basePricePerHour);
      }
      totalBaseBookingPrice += baseBookingPriceForItem;
    }
    final dpAmount = totalBaseBookingPrice * 0.10;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pilih Metode Pembayaran',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context))
              ],
            ),
            const SizedBox(height: 16),
            _buildTimerNote(),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.green),
                title: const Text('Bayar Online (Lunas)',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Aman & terverifikasi otomatis'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  initiateMidtransPayment(grandTotal);
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.storefront, color: Colors.blue),
                title: const Text('Bayar di Tempat (DP 10%)',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(
                    'DP ${currencyFormatter.format(dpAmount)}, konfirmasi via Admin'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  initiateOnSitePayment(grandTotal);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final cart = context.watch<Cart>();
    final currencyFormatter =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    // Kalkulasi harga dari CartPage
    List<Map<String, dynamic>> detailedItems = [];
    double grandTotal = 0;

    for (final item in cart.cart) {
      int baseBookingPrice = 0;
      final int startHour = int.tryParse(item.time?.split(":")[0] ?? '0') ?? 0;
      final int duration = int.tryParse(item.quantity ?? '1') ?? 1;
      final int basePricePerHour = int.tryParse(item.price ?? '0') ?? 0;

      for (int i = 0; i < duration; i++) {
        baseBookingPrice +=
            _getPriceForHour(startHour + i, item.name ?? '', basePricePerHour);
      }

      double discountAmount =
          userProvider.isMember ? baseBookingPrice * 0.10 : 0;
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

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Ringkasan & Pembayaran'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TransactionHistoryPage()),
                    );
                  },
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
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      CupertinoButton(
                        color: Colors.black,
                        child: const Text('Lakukan Booking',
                            style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          // Ambil UserProvider tanpa me-listen
                          final userProvider =
                              Provider.of<UserProvider>(context, listen: false);

                          // Cek apakah user adalah admin
                          if (userProvider.isAdmin) {
                            // Jika admin, arahkan ke AdminHomePage
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AdminHomePage()),
                              (route) => false,
                            );
                          } else {
                            // Jika bukan admin, arahkan ke HomePage
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomePage()),
                              (route) => false,
                            );
                          }
                        },
                      )
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
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
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Text(
                                                'Jadwal: ${item.bookingDate}, ${item.time} (${item.quantity} jam)'),
                                          ],
                                        ),
                                      ),
                                      // **FITUR: Tombol hapus per item**
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
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  _buildPriceRow('Harga Booking',
                                      details['baseBookingPrice']),
                                  if (details['discountAmount'] > 0)
                                    _buildPriceRow('Diskon Member (10%)',
                                        -details['discountAmount'],
                                        isDiscount: true),
                                  if (details['addonsPrice'] > 0)
                                    _buildPriceRow('Layanan Tambahan',
                                        details['addonsPrice']),
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
                                              fontSize: 16)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildTimerNote(),
                      const SizedBox(
                          height: 80), // Jarak tambahan untuk bottom bar
                    ],
                  ),
                ),
          bottomNavigationBar: grandTotal == 0
              ? null
              : Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                          const Text('Total Bayar',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16)),
                          Text(currencyFormatter.format(grandTotal),
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)),
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                          ),
                          onPressed: isProcessingPayment
                              ? null
                              : () =>
                                  _showElegantPaymentMethodSheet(grandTotal),
                          child: isProcessingPayment
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 3))
                              : const Text('Pilih Pembayaran',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        if (showPaymentPopup) // Popup dari PaymentPage
          Dialog(
            insetPadding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.payment, size: 50, color: Colors.blue),
                    const SizedBox(height: 16),
                    const Text('Pembayaran Online',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text('Silakan selesaikan pembayaran Anda',
                        style: TextStyle(fontSize: 15),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    if (paymentUrl != null)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12)),
                        onPressed: () async {
                          if (await canLaunchUrl(Uri.parse(paymentUrl!))) {
                            await launchUrl(Uri.parse(paymentUrl!),
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        child: const Text('Buka Halaman Pembayaran',
                            style:
                                TextStyle(fontSize: 15, color: Colors.white)),
                      ),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Menunggu konfirmasi pembayaran...',
                        style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _closePaymentPopup,
                      child:
                          const Text('Tutup', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Widget helper dari CartPage & PaymentPage
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

  Widget _buildTimerNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Selesaikan pembayaran dalam 1x24 jam untuk menghindari pembatalan otomatis oleh sistem.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
