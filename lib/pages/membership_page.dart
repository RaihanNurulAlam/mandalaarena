// pages/membership_page.dart

// ignore_for_file: unnecessary_import, use_super_parameters, avoid_print, use_build_context_synchronously, unnecessary_to_list_in_spreads

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

/// Model untuk menyimpan detail setiap opsi keanggotaan
class MembershipOption {
  final String id;
  final String title;
  final String subtitle;
  final double downPayment;
  final String description;
  final List<String> benefits;
  final String? warning;

  MembershipOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.downPayment,
    required this.description,
    required this.benefits,
    this.warning,
  });
}

class MembershipPage extends StatefulWidget {
  const MembershipPage({Key? key}) : super(key: key);

  @override
  State<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends State<MembershipPage> {
  bool isProcessingPayment = false;

  // Daftar semua opsi keanggotaan
  late final List<MembershipOption> _membershipOptions;
  // State untuk menyimpan opsi yang sedang dipilih
  MembershipOption? _selectedMembership;

  @override
  void initState() {
    super.initState();
    // Inisialisasi data keanggotaan
    _membershipOptions = [
      MembershipOption(
        id: 'minisoccer',
        title: 'Member Mini Soccer',
        subtitle: 'Uang muka dengan 3 kali permainan',
        downPayment: 1500000,
        description: 'Pembayaran Uang Muka Member Mini Soccer',
        benefits: [
          'All access di semua fasilitas mini soccer',
          'Free mineral water',
          'Harga diskon 10% tiap bermain',
          'Priority booking',
          'Ice bath',
          'Ada member card dengan keuntungan pilihan (setelah 10 jam bermain): free 1 jam permainan, ATAU voucher 300k (merchandise/F&B), ATAU pemakaian bola original Nike selama 3 jam.',
        ],
        warning:
            'Apabila dalam satu bulan tidak ada permainan selama 4 kali maka akan diberlakukan pergantian member baru.',
      ),
      MembershipOption(
        id: 'basket_vinyl',
        title: 'Member Basket Ball Vynil',
        subtitle: 'Uang muka dengan 2 kali permainan',
        downPayment: 600000,
        description: 'Pembayaran Uang Muka Member Basket Vynil',
        benefits: [
          'All access di semua fasilitas basket ball',
          'Harga diskon 10% tiap bermain',
          'Priority booking',
          'Ice bath',
          'Bisa menempelkan logo member atau academy',
          'Ada member card dengan keuntungan pilihan (setelah 10 jam bermain): free 1 jam permainan, ATAU voucher 100k (F&B).',
        ],
      ),
      MembershipOption(
        id: 'basket_karet',
        title: 'Member Basket Ball Karet',
        subtitle: 'Uang muka dengan 2 kali permainan',
        downPayment: 300000,
        description: 'Pembayaran Uang Muka Member Basket Karet',
        benefits: [
          'Priority booking',
          'Bisa menempelkan logo member atau academy',
        ],
      ),
    ];
    // Atur pilihan default ke opsi pertama
    _selectedMembership = _membershipOptions[0];
  }

  String getBaseUrl() {
    return 'https://api-ygvy5l5oeq-uc.a.run.app';
  }

  /// Membuat dokumen transaksi membership di Firestore dengan data yang dinamis
  Future<void> _createMembershipTransaction(
      String orderId, MembershipOption selectedOption) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final transactionData = {
      'orderId': orderId,
      'userId': userProvider.userId,
      'userName': userProvider.userName,
      'description': selectedOption.description,
      'status': 'Pending',
      'amount': selectedOption.downPayment,
      'membershipType': selectedOption.id, // Simpan jenis membership
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('membership_transactions')
        .doc(orderId)
        .set(transactionData);
  }

  /// Mengupdate status user menjadi member di Firestore dengan jenis keanggotaan
  Future<void> _updateUserToMember(
      String userId, UserProvider provider, String membershipType) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final newExpiryDate = DateTime.now().add(const Duration(days: 365));

    await userRef.update({
      'isMember': true,
      'memberUntil': Timestamp.fromDate(newExpiryDate),
      'membershipType': membershipType, // Simpan jenis membership di data user
    });

    // Update state lokal melalui provider.
    // Pastikan Anda menambahkan parameter 'membershipType' pada method ini di file provider Anda.
    provider.updateMembershipStatus(true, newExpiryDate,
        membershipType: membershipType);
  }

  /// Memulai pembayaran via Midtrans sesuai opsi yang dipilih
  Future<void> initiateMembershipPayment() async {
    if (_selectedMembership == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Silakan pilih jenis member terlebih dahulu.')));
      return;
    }

    final selectedOption = _selectedMembership!;
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
      await _createMembershipTransaction(orderId, selectedOption);

      final baseUrl = getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/pay'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'orderId': orderId,
          'grossAmount': selectedOption.downPayment.toString(),
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
            _showWaitingDialog(orderId);
          }
        }
      } else {
        throw Exception('Gagal membuat transaksi: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() => isProcessingPayment = false);
    }
  }

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
              await checkTransactionStatus(orderId, showSuccessDialog: false);
            },
            child: const Text('Tutup'),
          )
        ],
      ),
    );
    _startPolling(orderId);
  }

  void _startPolling(String orderId) {
    Future.delayed(const Duration(seconds: 10), () async {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
        final success = await checkTransactionStatus(orderId);
        if (!success) {
          _startPolling(orderId);
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
          // Ambil data transaksi dari firestore untuk mendapatkan tipe member
          final transactionDoc = await FirebaseFirestore.instance
              .collection('membership_transactions')
              .doc(orderId)
              .get();

          if (transactionDoc.exists) {
            final membershipType =
                transactionDoc.data()?['membershipType'] as String? ??
                    'unknown';
            final userProvider =
                Provider.of<UserProvider>(context, listen: false);

            await FirebaseFirestore.instance
                .collection('membership_transactions')
                .doc(orderId)
                .update({'status': 'Success'});
            await _updateUserToMember(
                userProvider.userId, userProvider, membershipType);

            if (mounted && showSuccessDialog) {
              Navigator.pop(context);
              _showSuccessDialog();
            }
            setState(() => isProcessingPayment = false);
            return true;
          }
        }
      }
    } catch (e) {
      print('Error checking transaction status: $e');
    }
    return false;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pendaftaran Berhasil!'),
        content:
            const Text('Selamat! Anda sekarang adalah member Mandala Arena.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
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
            const Center(
              child: Text(
                'Pilih Jenis Keanggotaan',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            // Widget untuk pilihan keanggotaan
            Column(
              children: _membershipOptions.map((option) {
                return _buildMembershipOptionCard(option);
              }).toList(),
            ),

            const SizedBox(height: 24),
            if (_selectedMembership != null) ...[
              Text(
                'Benefit Member: ${_selectedMembership!.title}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Menampilkan benefit dari opsi yang dipilih
              ..._selectedMembership!.benefits.map((benefit) {
                return _buildBenefitItem(
                    Icons.check_circle_outline, benefit, Colors.green);
              }).toList(),

              // Menampilkan warning jika ada
              if (_selectedMembership!.warning != null) ...[
                const SizedBox(height: 16),
                _buildBenefitItem(Icons.warning_amber_rounded,
                    _selectedMembership!.warning!, Colors.orange.shade800),
              ]
            ]
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
                const Text('Uang Muka',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                Text(
                    // Harga dinamis sesuai pilihan
                    _selectedMembership != null
                        ? currencyFormatter
                            .format(_selectedMembership!.downPayment)
                        : 'Pilih Opsi',
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                icon: isProcessingPayment
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.star, color: Colors.white),
                label: Text(
                    isProcessingPayment ? 'Memproses...' : 'Bayar Sekarang',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                onPressed: isProcessingPayment || _selectedMembership == null
                    ? null
                    : initiateMembershipPayment,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget baru untuk membuat kartu pilihan member
  Widget _buildMembershipOptionCard(MembershipOption option) {
    bool isSelected = _selectedMembership?.id == option.id;
    final currencyFormatter =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.black : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMembership = option;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Radio<String>(
                value: option.id,
                groupValue: _selectedMembership?.id,
                onChanged: (value) {
                  setState(() {
                    _selectedMembership = option;
                  });
                },
                activeColor: Colors.black,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(option.subtitle,
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(currencyFormatter.format(option.downPayment),
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 15, height: 1.4))),
        ],
      ),
    );
  }
}
