// ignore_for_file: avoid_print, deprecated_member_use

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
  bool showPaymentOptions = false;
  bool isPayingOnSite = false;

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

      final bookingData = {
        'orderId': orderId,
        'userId': userProvider.userId,
        'userName': userProvider.userName,
        'userEmail': userProvider.userEmail,
        'userPhone': userProvider.userPhone,
        'statusBooking': 'Pending', // Default status for online payment
        'createdAt': FieldValue.serverTimestamp(),
        'items': cart.cart
            .map((item) => {
                  'name': item.name,
                  'price': item.price,
                  'originalPrice': item.price,
                  'quantity': item.quantity,
                  'bookingDate': item.bookingDate,
                  'time': item.time,
                  'usePhotographer': item.usePhotographer,
                  'useReferee': item.useReferee,
                  'imagePath': item.imagePath,
                  'teamName': item.teamName,
                  'isMember': userProvider.isMember,
                  'discountedPrice': userProvider.isMember
                      ? (double.tryParse(item.price ?? '0') ?? 0) * 0.6
                      : (double.tryParse(item.price ?? '0') ?? 0),
                })
            .toList(),
        'totalAmount': _calculateTotalPrice(),
        'originalTotalAmount':
            cart.cart.fold(0.0, (double previousValue, cartModel) {
          double price = double.tryParse(cartModel.price ?? '0') ?? 0;
          final int quantity = int.tryParse(cartModel.quantity ?? '1') ?? 1;
          double itemTotal = price * quantity;

          if (cartModel.usePhotographer ?? false) {
            itemTotal += 200000;
          }

          if (cartModel.useReferee ?? false) {
            itemTotal += 70000;
          }

          return previousValue + itemTotal.toInt();
        }),
      };

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(orderId)
          .set(bookingData);

      if (kDebugMode) {
        print('Booking document created successfully with all original fields');
      }
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
      print('Booking status updated to: $status');
    } catch (e) {
      print('Error updating booking status: $e');
      if (e.toString().contains('not-found')) {
        await _createBookingDocument(orderId);
        await updateBookingStatus(orderId, status);
      }
    }
  }

  double _calculateTotalPrice() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final cart = Provider.of<Cart>(context, listen: false);

    return cart.cart.fold(0, (previousValue, cartModel) {
      double price = double.tryParse(cartModel.price ?? '0') ?? 0;
      if (userProvider.isMember) {
        price = price * 0.6;
      }
      final int quantity = int.tryParse(cartModel.quantity ?? '1') ?? 1;
      double itemTotal = price * quantity;

      if (cartModel.usePhotographer ?? false) {
        itemTotal += 200000;
      }

      if (cartModel.useReferee ?? false) {
        itemTotal += 70000;
      }

      return previousValue + itemTotal.toInt();
    });
  }

  Future<void> _completePayment(String orderId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final cart = Provider.of<Cart>(context, listen: false);

    try {
      // Update status to "Sudah Bayar" and save to Firestore
      await updateBookingStatus(orderId, 'Sudah Bayar');
      int earnedPoints = int.parse(cart.cart.first.quantity!) * 10;
      await _updateUserPoints(userProvider.userId, earnedPoints);
      await _saveUserPointsTransaction(
          userProvider.userId, earnedPoints, orderId);

      await cart.clearCart();
      await cart.loadCart(userProvider.userId);

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

  Future<void> _updateUserPoints(String userId, int earnedPoints) async {
    if (userId.isEmpty) return;

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      // Gunakan transaction untuk memastikan konsistensi
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          throw Exception("User tidak ditemukan");
        }

        int currentPoints = userDoc.data()?['points'] ?? 0;
        transaction.update(userRef, {'points': currentPoints + earnedPoints});
      });

      print('User points updated successfully');
    } catch (e) {
      print('Error updating user points: $e');
      rethrow;
    }
  }

  Future<void> _saveUserPointsTransaction(
      String userId, int earnedPoints, String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('points').doc().set({
        'userId': userId,
        'points': earnedPoints,
        'orderId': orderId,
        'type': 'earned',
        'timestamp': FieldValue.serverTimestamp(),
        'description': 'Poin dari pembayaran booking',
        'status': 'Berhasil',
        'imageUrl': 'assets/earned_points.png', // Gambar default
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

          setState(() {
            showPaymentPopup = false;
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const TransactionHistoryPage(),
            ),
          );
        } else if (transactionStatus == 'pending') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Pembayaran Anda masih pending. Silakan selesaikan pembayaran.'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pembayaran gagal. Status: $transactionStatus'),
              backgroundColor: Colors.red,
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
        const SnackBar(
          content: Text('Tidak ada item untuk dibayar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isProcessingPayment = true;
    });

    try {
      final orderId =
          'ORDER-${DateTime.now().millisecondsSinceEpoch}-${userProvider.userId.substring(0, 5)}';

      // Create booking with 'Pending' status
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
              'callbackUrl':
                  'https://mandalaarenaapp-95d0d.web.app/payment-callback',
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
          await launchUrl(
            Uri.parse(paymentUrl!),
            mode: LaunchMode.externalApplication,
          );
        }
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${errorData['status_message'] ?? 'Terjadi kesalahan pada sistem pembayaran.'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
        throw Exception('Failed to create transaction: ${response.body}');
      }
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

  Future<void> initiateOnSitePayment() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final cart = Provider.of<Cart>(context, listen: false);

    if (cart.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada item untuk dibooking'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isProcessingPayment = true;
      isPayingOnSite = true;
    });

    try {
      final orderId =
          'ORDER-${DateTime.now().millisecondsSinceEpoch}-${userProvider.userId.substring(0, 5)}';

      // Update status to "Booking (Bayar di Tempat)" and save to Firestore
      await updateBookingStatus(orderId, 'Booking (Bayar di Tempat)');

      final bookingDetails = cart.cart.map((item) {
        double price = double.tryParse(item.price ?? '0') ?? 0;
        if (userProvider.isMember) {
          price = price * 0.6;
        }

        return '''
Lapangan: ${item.name}
Tanggal: ${item.bookingDate}
Jam: ${item.time}
Durasi: ${item.quantity} jam
Harga per jam: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(price)}
${item.usePhotographer ?? false ? 'Dengan Photographer (+Rp 200,000)' : ''}
${item.useReferee ?? false ? 'Dengan Wasit (+Rp 70,000)' : ''}
''';
      }).join('\n');

      final whatsappMessage = '''
Halo Admin Mandala Arena,

Saya ingin melakukan booking dengan detail berikut:

$bookingDetails

Nama: ${userProvider.userName}
Email: ${userProvider.userEmail}
No. HP: ${userProvider.userPhone}
Status Member: ${userProvider.isMember ? 'Ya' : 'Tidak'}

Saya memilih untuk bayar di tempat.

Terima kasih.
''';

      final encodedMessage = Uri.encodeComponent(whatsappMessage);
      final whatsappUrl = 'https://wa.me/6281111122525?text=$encodedMessage';

      cart.clearCart();

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
        isPayingOnSite = false;
      });
    }
  }

  void _closePaymentPopup() async {
    setState(() {
      showPaymentPopup = false;
    });

    if (currentOrderId != null) {
      // Periksa status transaksi
      await checkTransactionStatus(currentOrderId!);

      // Jika status masih "Pending", hapus data booking
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

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pilih Metode Pembayaran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      initiateMidtransPayment();
                    },
                    child: const Text(
                      'Bayar Online',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      initiateOnSitePayment();
                    },
                    child: const Text(
                      'Bayar di Tempat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final cart = Provider.of<Cart>(context);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title:
                const Text('Transaksi', style: TextStyle(color: Colors.black)),
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
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (transactionStatus != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: transactionStatus == 'settlement'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            transactionStatus == 'settlement'
                                ? Icons.check_circle
                                : Icons.error,
                            color: transactionStatus == 'settlement'
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Status Transaksi: $transactionStatus',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: transactionStatus == 'settlement'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isProcessingPayment)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_cart, color: Colors.black54),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            cart.cart.isNotEmpty
                                ? 'Jumlah Item: ${cart.cart.length}'
                                : 'Tidak ada item',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (cart.cart.isEmpty)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomePage(),
                                ),
                              );
                            },
                            child: const Text('Lakukan Booking',
                                style: TextStyle(color: Colors.black)),
                          ),
                      ],
                    ),
                  ),
                  if (cart.cart.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Item di keranjang:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cart.cart.length,
                      itemBuilder: (context, index) {
                        final item = cart.cart[index];
                        double price = double.tryParse(item.price ?? '0') ?? 0;
                        final originalPrice = price;
                        if (userProvider.isMember) {
                          price = price * 0.6;
                        }
                        final totalPrice =
                            price * (int.tryParse(item.quantity ?? '1') ?? 1);

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  item.imagePath ??
                                      'assets/images/placeholder.png',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name ?? 'Item tidak diketahui',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (userProvider.isMember)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Harga Asli: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(originalPrice)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                          ),
                                          Text(
                                            'Harga Member: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(price)} x ${item.quantity} Jam',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Text(
                                        'Harga: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(price)} x ${item.quantity} Jam',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    Text(
                                      'Total: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(totalPrice)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tanggal: ${item.bookingDate} - Jam: ${item.time}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    if (item.usePhotographer ?? false)
                                      const Text(
                                        'Photographer: Rp 200,000',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    if (item.useReferee ?? false)
                                      const Text(
                                        'Wasit: Rp 70,000',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Harga:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (userProvider.isMember)
                                Text(
                                  'Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(cart.cart.fold(0, (previousValue, cartModel) {
                                    double price = double.tryParse(
                                            cartModel.price ?? '0') ??
                                        0;
                                    final int quantity = int.tryParse(
                                            cartModel.quantity ?? '1') ??
                                        1;
                                    double itemTotal = price * quantity;

                                    if (cartModel.usePhotographer ?? false) {
                                      itemTotal += 200000;
                                    }

                                    if (cartModel.useReferee ?? false) {
                                      itemTotal += 70000;
                                    }

                                    return previousValue + itemTotal.toInt();
                                  }))}',
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              Text(
                                'Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(_calculateTotalPrice())}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              if (userProvider.isMember)
                                Text(
                                  'Anda hemat Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(cart.cart.fold(0, (previousValue, cartModel) {
                                    double price = double.tryParse(
                                            cartModel.price ?? '0') ??
                                        0;
                                    final int quantity = int.tryParse(
                                            cartModel.quantity ?? '1') ??
                                        1;
                                    double itemTotal = price * quantity;
                                    double discountedItemTotal =
                                        (price * 0.6) * quantity;

                                    if (cartModel.usePhotographer ?? false) {
                                      itemTotal += 200000;
                                      discountedItemTotal += 200000;
                                    }

                                    if (cartModel.useReferee ?? false) {
                                      itemTotal += 70000;
                                      discountedItemTotal += 70000;
                                    }

                                    return previousValue +
                                        (itemTotal - discountedItemTotal)
                                            .toInt();
                                  }))}',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (transactionStatus == null && !isProcessingPayment)
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          onPressed: _showPaymentMethodDialog,
                          child: const Text(
                            'Pilih Metode Pembayaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
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
                    const Icon(
                      Icons.payment,
                      size: 50,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pembayaran Online',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Silakan selesaikan pembayaran Anda',
                      style: TextStyle(fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (paymentUrl != null)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () async {
                          if (await canLaunchUrl(Uri.parse(paymentUrl!))) {
                            await launchUrl(
                              Uri.parse(paymentUrl!),
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: const Text(
                          'Buka Halaman Pembayaran',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text(
                      'Menunggu konfirmasi pembayaran...',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _closePaymentPopup,
                      child: const Text(
                        'Tutup',
                        style: TextStyle(fontSize: 16),
                      ),
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
