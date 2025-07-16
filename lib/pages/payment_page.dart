// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously, avoid_print, deprecated_member_use

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/pages/home_page.dart';
import 'package:mandalaarenaapp/pages/riwayat_pembayaran.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? transactionStatus;
  bool isProcessingPayment = false;
  bool showPaymentPopup = false;
  String? paymentUrl;
  String? currentOrderId;

  // Helper function untuk menghitung harga per jam
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

  Map<String, double> _calculatePriceDetails() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final cart = Provider.of<Cart>(context, listen: false);

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

    final grandTotal =
        (totalBaseBookingPrice - totalDiscountAmount) + totalAddonsPrice;

    return {
      'totalBaseBookingPrice': totalBaseBookingPrice,
      'totalDiscountAmount': totalDiscountAmount,
      'totalAddonsPrice': totalAddonsPrice,
      'grandTotal': grandTotal,
    };
  }

  double _calculateTotalPrice() {
    return _calculatePriceDetails()['grandTotal'] ?? 0.0;
  }

  String getBaseUrl() {
    const baseUrl = 'https://api-ygvy5l5oeq-uc.a.run.app';
    if (kDebugMode) {
      print('Using base URL: $baseUrl');
    }
    return baseUrl;
  }

  Future<void> _createBookingDocument(String orderId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final cart = Provider.of<Cart>(context, listen: false);
      final priceDetails = _calculatePriceDetails();

      final bookingData = {
        'orderId': orderId,
        'userId': userProvider.userId,
        'userName': userProvider.userName,
        'userEmail': userProvider.userEmail,
        'userPhone': userProvider.userPhone,
        'statusBooking': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'items': cart.cart
            .map((item) => {
                  'name': item.name,
                  'price': item.price,
                  'quantity': item.quantity,
                  'bookingDate': item.bookingDate,
                  'time': item.time,
                  'usePhotographer': item.usePhotographer,
                  'useReferee': item.useReferee,
                  'useIceBath': item.useIceBath,
                  'imagePath': item.imagePath,
                  'teamName': item.teamName,
                })
            .toList(),
        'totalAmount': priceDetails['grandTotal'],
        'baseBookingPrice': priceDetails['totalBaseBookingPrice'],
        'discountAmount': priceDetails['totalDiscountAmount'],
        'addonsPrice': priceDetails['totalAddonsPrice'],
        'isMember': userProvider.isMember,
        'pointsAwarded': false,
      };

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(orderId)
          .set(bookingData);
    } catch (e) {
      print('Error creating booking document: $e');
      rethrow;
    }
  }

  Future<void> updateBookingStatus(String orderId, String status) async {
    try {
      final bookingRef =
          FirebaseFirestore.instance.collection('bookings').doc(orderId);
      await bookingRef.update({'statusBooking': status});
    } catch (e) {
      print('Error updating booking status: $e');
    }
  }

  Future<void> _completePayment(String orderId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final cart = Provider.of<Cart>(context, listen: false);

    try {
      final bookingDocRef =
          FirebaseFirestore.instance.collection('bookings').doc(orderId);
      final bookingDoc = await bookingDocRef.get();

      if (!bookingDoc.exists) {
        print("Error: Dokumen booking tidak ditemukan.");
        return;
      }

      await updateBookingStatus(orderId, 'Sudah Bayar');

      final bool pointsAlreadyAwarded =
          bookingDoc.data()?['pointsAwarded'] == true;

      if (pointsAlreadyAwarded) {
        print(
            "Poin untuk order $orderId sudah diproses sebelumnya. Proses dilewati.");
      } else {
        if (userProvider.isMember) {
          print("Member terdeteksi. Memberikan poin untuk order $orderId...");
          int earnedPoints = cart.cart.fold(0, (previousValue, item) {
            final int duration = int.tryParse(item.quantity ?? '1') ?? 1;
            return previousValue + duration;
          });

          if (earnedPoints > 0) {
            String imageUrl = cart.cart.isNotEmpty
                ? cart.cart.first.imagePath ?? 'assets/default_image.png'
                : 'assets/default_image.png';

            await _updateUserPoints(
                userProvider.userId, earnedPoints, userProvider);
            await _saveUserPointsTransaction(
                userProvider.userId, earnedPoints, orderId, imageUrl);

            await bookingDocRef.update({'pointsAwarded': true});
            print("Poin berhasil diberikan dan ditandai.");
          }
        } else {
          print("User bukan member. Poin tidak diberikan.");
          await bookingDocRef.update({'pointsAwarded': true});
        }
      }

      await cart.clearCart();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const TransactionHistoryPage(),
          ),
        );
      }
    } catch (e) {
      print('Error completing payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateUserPoints(
      String userId, int earnedPoints, UserProvider provider) async {
    if (userId.isEmpty || earnedPoints <= 0) return;

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      int newTotalPoints = 0;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw Exception("User tidak ditemukan");

        int currentPoints = userDoc.data()?['points'] ?? 0;
        newTotalPoints = currentPoints + earnedPoints;
        transaction.update(userRef, {'points': newTotalPoints});
      });

      provider.updateUserPoints(newTotalPoints);
      print('User points updated successfully to $newTotalPoints');
    } catch (e) {
      print('Error updating user points: $e');
      rethrow;
    }
  }

  Future<void> _saveUserPointsTransaction(
      String userId, int earnedPoints, String orderId, String imageUrl) async {
    if (earnedPoints <= 0) return;
    try {
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
      print('Points transaction saved successfully');
    } catch (e) {
      print('Error saving points transaction: $e');
      rethrow;
    }
  }

  Future<void> checkTransactionStatus(String orderId) async {
    try {
      final baseUrl = getBaseUrl();
      final statusResponse = await http.get(
        Uri.parse('$baseUrl/transaction-status?orderId=$orderId'),
      );

      if (statusResponse.statusCode == 200) {
        final statusData = json.decode(statusResponse.body);
        setState(() {
          transactionStatus = statusData['transaction_status'];
        });

        if (transactionStatus == 'settlement' ||
            transactionStatus == 'capture') {
          await _completePayment(orderId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status Pembayaran: $transactionStatus'),
              backgroundColor:
                  transactionStatus == 'pending' ? Colors.orange : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error checking transaction status: $e');
    }
  }

  Future<void> initiateMidtransPayment() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final cart = Provider.of<Cart>(context, listen: false);

    if (cart.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada item untuk dibayar')),
      );
      return;
    }

    setState(() {
      isProcessingPayment = true;
    });

    try {
      final orderId =
          'ORDER-${DateTime.now().millisecondsSinceEpoch}-${userProvider.userId.substring(0, 5)}';
      await _createBookingDocument(orderId);

      final baseUrl = getBaseUrl();
      final response = await http
          .post(
            Uri.parse('$baseUrl/pay'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'orderId': orderId,
              'grossAmount': _calculateTotalPrice().toString(),
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

        if (kIsWeb && await canLaunchUrl(Uri.parse(paymentUrl!))) {
          await launchUrl(Uri.parse(paymentUrl!),
              mode: LaunchMode.externalApplication);
        }
      } else {
        throw Exception('Failed to create transaction: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        isProcessingPayment = false;
      });
    }
  }

  Future<void> initiateOnSitePayment() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final cart = Provider.of<Cart>(context, listen: false);

    if (cart.cart.isEmpty) return;

    setState(() {
      isProcessingPayment = true;
    });

    try {
      final orderId =
          'ORDER-${DateTime.now().millisecondsSinceEpoch}-${userProvider.userId.substring(0, 5)}';

      await _createBookingDocument(orderId);
      await updateBookingStatus(orderId, 'Booking (Bayar di Tempat)');

      final priceDetails = _calculatePriceDetails();
      final dpAmount = (priceDetails['totalBaseBookingPrice'] ?? 0) * 0.10;
      final totalHarga = _calculateTotalPrice();

      final currencyFormatter =
          NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
      final formattedDp = currencyFormatter.format(dpAmount);
      final formattedTotal = currencyFormatter.format(totalHarga);

      final bookingDetails = cart.cart.map((item) {
        return 'Lapangan: ${item.name}\nTanggal: ${item.bookingDate}\nJam: ${item.time} (${item.quantity} jam)';
      }).join('\n\n');

      final whatsappMessage = '''
Halo Admin Mandala Arena,
Saya ingin melakukan booking dengan detail berikut:

$bookingDetails

Nama: ${userProvider.userName}
No. HP: ${userProvider.userPhone}
Total Tagihan: *$formattedTotal*

Saya memilih untuk *Bayar di Tempat* dan akan melakukan transfer DP sebesar *${formattedDp}* (10% dari harga sewa lapang). Mohon info rekening tujuan.

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
          builder: (context) => const TransactionHistoryPage(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isProcessingPayment = false;
      });
    }
  }

  void _closePaymentPopup() async {
    setState(() {
      showPaymentPopup = false;
    });

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

  void _showElegantPaymentMethodSheet() {
    final priceDetails = _calculatePriceDetails();
    final currencyFormatter =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    // --- PERUBAHAN: Hitung DP ---
    final dpAmount = (priceDetails['totalBaseBookingPrice'] ?? 0) * 0.10;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
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
              _buildTimerNote(), // --- PERUBAHAN: Tampilkan catatan timer ---
              const SizedBox(height: 16),

              // Pilihan Metode
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
                    initiateMidtransPayment();
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
                  // --- PERUBAHAN: Tampilkan jumlah DP di subtitle ---
                  subtitle: Text(
                      'DP ${currencyFormatter.format(dpAmount)}, konfirmasi via Admin'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    initiateOnSitePayment();
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceRow(String title, double amount,
      {bool isDiscount = false}) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final Color color = isDiscount ? Colors.green : Colors.black87;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 14)),
          Text(
            currencyFormatter.format(amount),
            style: TextStyle(
                color: color, fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // --- PERUBAHAN: Widget baru untuk menampilkan catatan timer ---
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

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);
    final priceDetails = _calculatePriceDetails();
    final currencyFormatter =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Ringkasan Booking',
                style: TextStyle(color: Colors.black)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: IconButton(
                  icon: const Icon(Icons.history, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransactionHistoryPage(),
                      ),
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
                      const Text('Tidak ada item di keranjang',
                          style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => HomePage()),
                            (route) => false,
                          );
                        },
                        child: const Text('Lakukan Booking'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- PERUBAHAN: Detail dan Rincian disatukan dalam satu Card ---
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Detail Booking',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: cart.cart.length,
                                  itemBuilder: (context, index) {
                                    final item = cart.cart[index];
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.asset(
                                              item.imagePath ??
                                                  'assets/images/placeholder.png',
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(item.name ?? 'Item',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text(
                                                    '${item.bookingDate} - ${item.time} (${item.quantity} jam)'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const Divider(height: 24, thickness: 1),
                                const Text('Rincian Pembayaran',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                _buildPriceRow('Harga Booking',
                                    priceDetails['totalBaseBookingPrice']!),
                                if (priceDetails['totalDiscountAmount']! > 0)
                                  _buildPriceRow('Diskon Member (10%)',
                                      -priceDetails['totalDiscountAmount']!,
                                      isDiscount: true),
                                if (priceDetails['totalAddonsPrice']! > 0)
                                  _buildPriceRow('Layanan Tambahan',
                                      priceDetails['totalAddonsPrice']!),
                                const Divider(height: 24, thickness: 1),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                      currencyFormatter
                                          .format(priceDetails['grandTotal']),
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildTimerNote(), // Tampilkan catatan timer di halaman utama juga
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          bottomNavigationBar: cart.cart.isEmpty
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
                          Text(currencyFormatter.format(_calculateTotalPrice()),
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
                              : _showElegantPaymentMethodSheet,
                          child: isProcessingPayment
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 3),
                                )
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
        if (showPaymentPopup)
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
                              horizontal: 20, vertical: 12),
                        ),
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
}
