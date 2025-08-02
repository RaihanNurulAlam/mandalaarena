// [edit_booking_page.dart] - DENGAN LOGIKA MEMBER YANG DISEMPURNAKAN

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:intl/intl.dart';

class EditBookingPage extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> initialData;

  const EditBookingPage({
    super.key,
    required this.bookingId,
    required this.initialData,
  });

  @override
  State<EditBookingPage> createState() => _EditBookingPageState();
}

enum PaymentStatus { lunas, dp, booking }

class _EditBookingPageState extends State<EditBookingPage> {
  final _formKey = GlobalKey<FormState>();

  // State variables
  int totalAmount = 0;
  late int bookingDuration;
  late bool usePhotographer;
  late bool useReferee;
  late bool useIceBath;
  late String teamName;
  late PaymentStatus _paymentStatus;
  late int _downPaymentAmount;
  final TextEditingController _downPaymentController = TextEditingController();

  // Image handling
  Uint8List? _webImage;
  File? _imageFile;
  String? _paymentProofUrl;

  // Data dari booking awal
  late String lapangan;
  late String bookingDate;
  late String time;
  late bool isMember; // <-- Status member disimpan di sini

  final int photographerPrice = 200000;
  final int refereePrice = 70000;
  final int iceBathPrice = 50000;

  @override
  void initState() {
    super.initState();
    _initializeStateAndRecalculate();
  }

  void _initializeStateAndRecalculate() {
    final items = widget.initialData['items'] as List<dynamic>? ?? [];
    final firstItem = items.isNotEmpty ? items[0] as Map<String, dynamic> : {};

    lapangan = firstItem['name'] ?? "";
    bookingDuration =
        int.tryParse(firstItem['quantity']?.toString() ?? '1') ?? 1;
    usePhotographer = firstItem['usePhotographer'] ?? false;
    useReferee = firstItem['useReferee'] ?? false;
    useIceBath = firstItem['useIceBath'] ?? false;
    teamName = firstItem['teamName'] ?? "";
    bookingDate = firstItem['bookingDate'] ?? "";
    time = firstItem['time'] ?? "";

    // [PENTING] Mengambil status member dari data awal booking
    isMember = widget.initialData['isMember'] ?? false;

    final statusString =
        widget.initialData['statusBooking']?.toString() ?? 'Booking';
    if (statusString.contains('Sudah Bayar')) {
      _paymentStatus = PaymentStatus.lunas;
    } else if (statusString.toUpperCase().contains('DP')) {
      _paymentStatus = PaymentStatus.dp;
    } else {
      _paymentStatus = PaymentStatus.booking;
    }

    _downPaymentAmount = widget.initialData['downPaymentAmount'] ?? 0;
    _downPaymentController.text =
        _downPaymentAmount > 0 ? _downPaymentAmount.toString() : '';
    _paymentProofUrl = widget.initialData['paymentProofUrl'];

    _updateTotalPrice();
  }

  // [LOGIKA KALKULASI HARGA DENGAN DISKON MEMBER]
  int _calculateBaseRentalPrice() {
    if (time.isEmpty || bookingDuration <= 0) return 0;

    double cumulativePrice = 0.0;
    final int startHour = int.parse(time.split(":")[0]);

    for (int i = 0; i < bookingDuration; i++) {
      final int currentHour = startHour + i;
      double priceForThisHour = _getPriceForHour(currentHour).toDouble();

      // [LOGIKA DISKON] Jika user adalah member, harga per jam dikalikan 0.9 (diskon 10%)
      if (isMember) {
        priceForThisHour *= 0.9;
      }

      cumulativePrice += priceForThisHour;
    }
    return cumulativePrice.round();
  }

  void _updateTotalPrice() {
    int newTotal = _calculateBaseRentalPrice();

    if (usePhotographer) {
      newTotal += photographerPrice;
    }
    if (useReferee) {
      newTotal += refereePrice;
    }
    if (useIceBath) newTotal += iceBathPrice;

    setState(() {
      totalAmount = newTotal;
    });
  }

  int _getPriceForHour(int hour) {
    int basePrice = 0;
    if (lapangan == "Lapang Basket A") basePrice = 150000;
    if (lapangan == "Lapang Basket B") basePrice = 75000;
    if (lapangan == "Lapang Basket 3x3") basePrice = 150000;
    if (lapangan == "Lapang Minisoccer") basePrice = 450000;
    if (lapangan == "Gokart") basePrice = 100000;

    String lapangName = lapangan;

    if (lapangName == "Lapang Minisoccer") {
      if (hour >= 7 && hour < 14) return basePrice;
      if (hour >= 14 && hour < 18) return basePrice + 100000;
      if (hour >= 18 && hour < 23) return basePrice + 200000;
    } else if (lapangName == "Lapang Basket A") {
      if (hour >= 7 && hour < 14) return basePrice;
      if (hour >= 14 && hour < 18) return basePrice + 50000;
      if (hour >= 18 && hour < 23) return basePrice + 100000;
    } else if (lapangName == "Lapang Basket B") {
      if (hour >= 7 && hour < 14) return basePrice;
      if (hour >= 14 && hour < 18) return basePrice + 25000;
      if (hour >= 18 && hour < 23) return basePrice + 50000;
    }
    return basePrice;
  }

  // Fungsi untuk menyimpan perubahan ke Firestore
  Future<void> _updateBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dpAmount = int.tryParse(_downPaymentController.text) ?? 0;
    if (_paymentStatus == PaymentStatus.dp &&
        (dpAmount <= 0 || dpAmount >= totalAmount)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jumlah DP tidak valid!")),
      );
      return;
    }

    try {
      String? newPaymentProofUrl = await _uploadImage();
      String finalStatus;
      int finalDpAmount = 0;
      int finalRemainingAmount = 0;

      switch (_paymentStatus) {
        case PaymentStatus.lunas:
          finalStatus = 'Sudah Bayar (Offline)';
          finalDpAmount = totalAmount;
          finalRemainingAmount = 0;
          break;
        case PaymentStatus.dp:
          finalStatus = 'DP (Bayar di Tempat)';
          finalDpAmount = dpAmount;
          finalRemainingAmount = totalAmount - dpAmount;
          break;
        case PaymentStatus.booking:
          finalStatus = 'Booking (Bayar di Tempat)';
          finalDpAmount = 0;
          finalRemainingAmount = totalAmount;
          newPaymentProofUrl = null;
          break;
      }

      final items = widget.initialData['items'] as List<dynamic>? ?? [];
      final firstItem =
          items.isNotEmpty ? items[0] as Map<String, dynamic> : {};

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'totalAmount': totalAmount,
        'statusBooking': finalStatus,
        'downPaymentAmount': finalDpAmount,
        'remainingAmount': finalRemainingAmount,
        'paymentProofUrl': newPaymentProofUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        'isMember': isMember, // <-- [PENTING] Simpan kembali status member
        'items': [
          {
            ...firstItem,
            'quantity': bookingDuration.toString(),
            'teamName': teamName,
            'usePhotographer': usePhotographer,
            'useReferee': useReferee,
            'useIceBath': useIceBath,
          }
        ],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Booking berhasil diperbarui!'),
            backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error memperbarui booking: $e"),
            backgroundColor: Colors.red),
      );
    }
  }

  // --- Sisa fungsi helper tidak ada perubahan ---
  Future<String?> _uploadImage() async {
    try {
      if (_imageFile == null && _webImage == null) return _paymentProofUrl;
      String fileName =
          'buktipembayaran/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask;
      if (kIsWeb && _webImage != null) {
        uploadTask = storageRef.putData(_webImage!);
      } else if (_imageFile != null) {
        uploadTask = storageRef.putFile(_imageFile!);
      } else {
        return _paymentProofUrl;
      }
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return _paymentProofUrl;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (kIsWeb) {
          _webImage = await pickedFile.readAsBytes();
        } else {
          _imageFile = File(pickedFile.path);
        }
        setState(() {});
      }
    } catch (e) {/* handle error */}
  }

  Future<void> _deletePaymentProof() async {
    setState(() {
      _imageFile = null;
      _webImage = null;
      _paymentProofUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Booking'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 20),
              _buildSectionTitle('Ubah Data Booking'),
              _buildEditableFields(),
              const SizedBox(height: 20),
              _buildSectionTitle('Status Pembayaran'),
              _buildPaymentSection(),
              const SizedBox(height: 20),
              if (lapangan != "Gokart") ...[
                _buildSectionTitle('Layanan Tambahan'),
                _buildAddonServices(),
                const SizedBox(height: 20),
              ],
              _buildPriceDetailsCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // --- Widget build methods ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lapangan,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            _buildInfoRow(
                Icons.person_outline, widget.initialData['userName'] ?? 'N/A'),
            _buildInfoRow(
                Icons.calendar_today,
                DateFormat('EEEE, dd MMMM yyyy')
                    .format(DateTime.parse(bookingDate))),
            _buildInfoRow(Icons.access_time, 'Jam $time'),
            // [INDIKATOR VISUAL MEMBER]
            if (isMember)
              _buildInfoRow(Icons.star_border_purple500_outlined,
                  'Status: Member (Diskon 10%)',
                  color: Colors.purple.shade700),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.grey.shade700),
          const SizedBox(width: 10),
          Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildEditableFields() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              initialValue: teamName,
              decoration: const InputDecoration(
                labelText: "Nama Tim / Atas Nama",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => teamName = value),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Nama tim wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Durasi (jam)',
                    style: Theme.of(context).textTheme.bodyLarge),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (bookingDuration > 1) {
                          setState(() => bookingDuration--);
                          _updateTotalPrice();
                        }
                      },
                      icon: Icon(Icons.remove_circle_outline),
                    ),
                    Text('$bookingDuration',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: () {
                        setState(() => bookingDuration++);
                        _updateTotalPrice();
                      },
                      icon: Icon(Icons.add_circle_outline),
                    ),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SegmentedButton<PaymentStatus>(
              segments: const [
                ButtonSegment(
                    value: PaymentStatus.booking,
                    label: Text('Booking'),
                    icon: Icon(Icons.bookmark_border)),
                ButtonSegment(
                    value: PaymentStatus.dp,
                    label: Text('DP'),
                    icon: Icon(Icons.monetization_on_outlined)),
                ButtonSegment(
                    value: PaymentStatus.lunas,
                    label: Text('Lunas'),
                    icon: Icon(Icons.check_circle_outline)),
              ],
              selected: {_paymentStatus},
              onSelectionChanged: (newSelection) {
                setState(() => _paymentStatus = newSelection.first);
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: Colors.black.withOpacity(0.1),
                selectedForegroundColor: Colors.black,
              ),
            ),
            if (_paymentStatus == PaymentStatus.dp) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _downPaymentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah DP',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (_paymentStatus != PaymentStatus.dp) return null;
                  final amount = int.tryParse(v ?? '');
                  if (amount == null || amount <= 0) return 'DP harus diisi';
                  if (amount >= totalAmount) return 'DP harus < total harga';
                  return null;
                },
              ),
            ],
            if (_paymentStatus != PaymentStatus.booking) ...[
              const SizedBox(height: 16),
              _buildPaymentProofUploader(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentProofUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Bukti Pembayaran',
                style: Theme.of(context).textTheme.bodyLarge),
            if (_paymentProofUrl != null ||
                _imageFile != null ||
                _webImage != null)
              IconButton(
                  onPressed: _deletePaymentProof,
                  icon: Icon(Icons.delete),
                  color: Colors.red,
                  tooltip: 'Hapus Bukti Bayar'),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: (_webImage != null)
                ? Image.memory(_webImage!, fit: BoxFit.cover)
                : (_imageFile != null)
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : (_paymentProofUrl != null)
                        ? Image.network(_paymentProofUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                const Center(child: Text('Gagal Muat')))
                        : const Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                Icon(Icons.add_a_photo_outlined),
                                Text('Unggah Bukti')
                              ])),
          ),
        )
      ],
    );
  }

  Widget _buildAddonServices() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: Text('Photographer'),
              subtitle: Text(
                  'Rp ${NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0).format(photographerPrice)}'),
              value: usePhotographer,
              onChanged: (val) {
                setState(() => usePhotographer = val);
                _updateTotalPrice();
              },
              secondary: Icon(Icons.camera_alt_outlined),
            ),
            const Divider(),
            SwitchListTile(
              title: Text('Wasit'),
              subtitle: Text(
                  'Rp ${NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0).format(refereePrice)}'),
              value: useReferee,
              onChanged: (val) {
                setState(() => useReferee = val);
                _updateTotalPrice();
              },
              secondary: Icon(Icons.sports_outlined),
            ),
            if (lapangan == "Lapang Minisoccer" && isMember) ...[
              const Divider(),
              SwitchListTile(
                title: const Text('Ice Bath (Khusus Member)'),
                subtitle: Text(
                    'Rp ${NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0).format(iceBathPrice)}'),
                value: useIceBath,
                onChanged: (val) {
                  setState(() => useIceBath = val);
                  _updateTotalPrice();
                },
                secondary: const Icon(Icons.ac_unit),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetailsCard() {
    final dpAmount = (_paymentStatus == PaymentStatus.dp)
        ? (int.tryParse(_downPaymentController.text) ?? 0)
        : 0;
    final remainingAmount = totalAmount - dpAmount;

    return Card(
      color: Colors.grey.shade100,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPriceRow('Subtotal Lapangan', _calculateBaseRentalPrice()),
            if (usePhotographer)
              _buildPriceRow('Photographer', photographerPrice),
            if (useReferee) _buildPriceRow('Wasit', refereePrice),
            const Divider(height: 20, thickness: 1),
            if (useIceBath) _buildPriceRow('Ice Bath', iceBathPrice),
            const Divider(height: 20, thickness: 1),
            _buildPriceRow('Total Harga', totalAmount, isTotal: true),
            if (_paymentStatus == PaymentStatus.dp && dpAmount > 0) ...[
              const SizedBox(height: 8),
              _buildPriceRow('DP Dibayar', dpAmount,
                  color: Colors.green.shade700),
              _buildPriceRow('Sisa Pembayaran', remainingAmount,
                  color: Colors.red.shade700),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, int amount,
      {Color? color, bool isTotal = false}) {
    final textStyle = TextStyle(
      fontSize: isTotal ? 18 : 16,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      color: color ?? (isTotal ? Colors.black : Colors.grey.shade800),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textStyle),
          Text(
            NumberFormat.currency(
                    locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                .format(amount),
            style: textStyle.copyWith(color: color ?? Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16.0).copyWith(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, -2)),
        ],
      ),
      child: FilledButton(
        onPressed: _updateBooking,
        style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50))),
        child: const Text('Simpan Perubahan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
