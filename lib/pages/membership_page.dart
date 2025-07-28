// pages/membership_page.dart

// ignore_for_file: unnecessary_import, use_super_parameters, avoid_print

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class MembershipPage extends StatefulWidget {
  const MembershipPage({Key? key}) : super(key: key);

  @override
  State<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends State<MembershipPage> {
  bool isProcessingPayment = false;
  final double membershipFee = 150000; // Definisikan harga member di sini

  String getBaseUrl() {
    // Pastikan fungsi ini sama dengan yang di BookingSummaryPage
    return 'https://api-ygvy5l5oeq-uc.a.run.app';
  }

  /// Membuat dokumen transaksi membership di Firestore
  Future<void> _createMembershipTransaction(String orderId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final transactionData = {
      'orderId': orderId,
      'userId': userProvider.userId,
      'userName': userProvider.userName,
      'description': 'Pembayaran Pendaftaran Member (1 Tahun)',
      'status': 'Pending',
      'amount': membershipFee,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('membership_transactions')
        .doc(orderId)
        .set(transactionData);
  }

  /// Mengupdate status user menjadi member di Firestore
  Future<void> _updateUserToMember(String userId, UserProvider provider) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final newExpiryDate = DateTime.now().add(const Duration(days: 365));

    await userRef.update({
      'isMember': true,
      'memberUntil': Timestamp.fromDate(newExpiryDate),
    });

    // Update state lokal melalui provider
    provider.updateMembershipStatus(true, newExpiryDate);
  }

  /// Memulai pembayaran via Midtrans
  Future<void> initiateMembershipPayment() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anda harus login untuk mendaftar.')));
      return;
    }

    setState(() => isProcessingPayment = true);

    try {
      final orderId =
          'MEMBER-${DateTime.now().millisecondsSinceEpoch}-${userProvider.userId.substring(0, 5)}';
      await _createMembershipTransaction(orderId);

      final baseUrl = getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/pay'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'orderId': orderId,
          'grossAmount': membershipFee.toString(),
          'firstName': userProvider.userName.split(' ').first,
          'lastName': userProvider.userName.split(' ').length > 1
              ? userProvider.userName.split(' ').sublist(1).join(' ')
              : '',
          'email': userProvider.userEmail,
          'phone': userProvider.userPhone,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final paymentUrl = data['redirect_url'];

        if (paymentUrl != null) {
          if (await canLaunchUrl(Uri.parse(paymentUrl))) {
            await launchUrl(Uri.parse(paymentUrl),
                mode: LaunchMode.externalApplication);
            // Setelah di-launch, kita tunggu dan cek status
            _showWaitingDialog(orderId);
          }
        }
      } else {
        throw Exception('Gagal membuat transaksi: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      // Set isProcessingPayment ke false saat dialog ditutup
    }
  }

  /// Dialog untuk menunggu pembayaran dan cek status
  void _showWaitingDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Menunggu Pembayaran'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Silakan selesaikan pembayaran. Jangan tutup halaman ini.'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog
              setState(() => isProcessingPayment = false);
              await checkTransactionStatus(orderId,
                  showSuccessDialog: false); // Cek status terakhir kali
            },
            child: const Text('Tutup'),
          )
        ],
      ),
    );

    // Mulai polling status transaksi
    _startPolling(orderId);
  }

  void _startPolling(String orderId) {
    Future.delayed(const Duration(seconds: 10), () async {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        final success = await checkTransactionStatus(orderId);
        if (!success) {
          _startPolling(orderId); // Lanjutkan polling jika belum berhasil
        }
      }
    });
  }

  Future<bool> checkTransactionStatus(String orderId,
      {bool showSuccessDialog = true}) async {
    try {
      final baseUrl = getBaseUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/transaction-status?orderId=$orderId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final transactionStatus = data['transaction_status'];

        if (transactionStatus == 'settlement' ||
            transactionStatus == 'capture') {
          // Pembayaran Berhasil
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          await FirebaseFirestore.instance
              .collection('membership_transactions')
              .doc(orderId)
              .update({'status': 'Success'});
          await _updateUserToMember(userProvider.userId, userProvider);

          if (mounted && showSuccessDialog) {
            Navigator.pop(context); // Tutup dialog loading
            _showSuccessDialog();
          }
          setState(() => isProcessingPayment = false);
          return true; // Berhasil
        }
      }
    } catch (e) {
      print('Error checking transaction status: $e');
    }
    return false; // Belum berhasil / error
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pendaftaran Berhasil!'),
        content:
            const Text('Selamat! Anda sekarang adalah member Mandala Arena.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Tutup dialog sukses
              Navigator.of(context)
                  .pop(); // Kembali ke halaman sebelumnya (homepage)
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Member'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Icon(Icons.star_border_purple500_sharp,
                      size: 60, color: Colors.amber[700]),
                  const SizedBox(height: 8),
                  const Text(
                    'Jadi Member Mandala Arena',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Nikmati berbagai keuntungan eksklusif!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Keuntungan Member',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBenefitItem(Icons.local_offer_outlined,
                'Diskon 10% untuk setiap booking lapang.'),
            _buildBenefitItem(Icons.star_outline,
                'Dapatkan Poin untuk setiap jam booking yang bisa ditukar.'),
            _buildBenefitItem(Icons.calendar_today_outlined,
                'Informasi & prioritas untuk event-event spesial.'),
            _buildBenefitItem(
                Icons.card_giftcard, 'Promo eksklusif khusus untuk member.'),
            const SizedBox(height: 24),
            const Text(
              'Syarat & Ketentuan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBenefitItem(Icons.check_circle_outline,
                'Keanggotaan berlaku selama 1 (satu) tahun sejak tanggal pembayaran.'),
            _buildBenefitItem(Icons.check_circle_outline,
                'Diskon member tidak dapat digabungkan dengan promo lainnya.'),
            _buildBenefitItem(Icons.check_circle_outline,
                'Keanggotaan tidak dapat dipindahtangankan.'),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Harga / Tahun',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                Text(currencyFormatter.format(membershipFee),
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.star, color: Colors.white),
                label: const Text('Daftar Sekarang',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                onPressed:
                    isProcessingPayment ? null : initiateMembershipPayment,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
