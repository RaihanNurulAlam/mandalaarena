import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MidtransPaymentPopup extends StatefulWidget {
  final String transactionToken;
  final String orderId;

  const MidtransPaymentPopup({
    super.key,
    required this.transactionToken,
    required this.orderId,
  });

  @override
  State<MidtransPaymentPopup> createState() => _MidtransPaymentPopupState();
}

class _MidtransPaymentPopupState extends State<MidtransPaymentPopup> {
  @override
  void initState() {
    super.initState();
    _openPaymentUrl();
  }

  Future<void> _openPaymentUrl() async {
    final url =
        'https://app.sandbox.midtrans.com/snap/v2/vtweb/${widget.transactionToken}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      // Simulasikan pembayaran selesai setelah membuka URL
      _checkPaymentStatus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka URL pembayaran'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context, false);
    }
  }

  void _checkPaymentStatus() {
    // Simulasikan logika untuk memeriksa status pembayaran
    // Misalnya, Anda dapat memanggil API untuk memeriksa status transaksi
    Navigator.pop(context, true); // Kembali ke halaman sebelumnya
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran Midtrans'),
      ),
      body: const Center(
        child: Text('Membuka halaman pembayaran...'),
      ),
    );
  }
}
