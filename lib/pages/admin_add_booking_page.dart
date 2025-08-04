// ignore_for_file: deprecated_member_use, use_super_parameters, curly_braces_in_flow_control_structures, use_build_context_synchronously, prefer_const_constructors

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class AdminAddBookingPage extends StatefulWidget {
  const AdminAddBookingPage({super.key});

  @override
  State<AdminAddBookingPage> createState() => _AdminAddBookingPageState();
}

class _AdminAddBookingPageState extends State<AdminAddBookingPage> {
  final _formKey = GlobalKey<FormState>();

  // Data Lapangan
  List<Map<String, dynamic>> _lapanganData = [];

  // State untuk alur booking
  String? selectedLapangan;
  DateTime? selectedDate = DateTime.now();
  DateTime _currentStartOfWeek =
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  String? selectedHour;
  int bookingDuration = 1;
  bool isMember = false;

  // State untuk jadwal & harga
  List<String> _unavailableTimes = [];
  bool _isLoadingTimes = false;
  int _totalPrice = 0;

  // Controllers untuk Form
  final _namaPemesanController = TextEditingController();
  final _noWaController = TextEditingController();
  final _teamNameController = TextEditingController();
  final _dpController = TextEditingController();

  // State untuk layanan & pembayaran
  String _paymentStatus = 'Booking (Bayar di Tempat)';
  bool _usePhotographer = false;
  bool _useReferee = false;
  bool _useIceBath = false;

  // Variabel baru untuk upload gambar
  bool _isUploading = false;
  Uint8List? _webImage;
  File? _imageFile;

  final int photographerPrice = 200000;
  final int refereePrice = 70000;
  final int iceBathPrice = 50000;

  @override
  void initState() {
    super.initState();
    _fetchLapanganData();
  }

  // --- FUNGSI LOGIKA ---

  Future<void> _fetchLapanganData() async {
    setState(() {
      _lapanganData = [
        {
          "id": "1",
          "name": "Lapang Basket A",
          "price": "150000",
          "image_path": "assets/vynil.JPG"
        },
        {
          "id": "2",
          "name": "Lapang Basket B",
          "price": "75000",
          "image_path": "assets/rubber.JPG"
        },
        {
          "id": "3",
          "name": "Lapang Minisoccer",
          "price": "450000",
          "image_path": "assets/mini.JPG"
        },
      ];
    });
  }

  Future<void> _fetchUnavailableTimes() async {
    if (selectedLapangan == null || selectedDate == null) return;

    setState(() {
      _isLoadingTimes = true;
      _unavailableTimes = [];
      selectedHour = null;
      _calculateTotalPrice();
    });

    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('bookings').get();

      List<String> times = [];
      for (var doc in querySnapshot.docs) {
        final items = doc.data()['items'] as List<dynamic>?;
        if (items != null) {
          for (var item in items) {
            if (item is Map &&
                item['name'] == selectedLapangan &&
                item['bookingDate'] == formattedDate) {
              final time = item['time'] as String?;
              final quantity =
                  int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;

              if (time != null) {
                final startHour = int.parse(time.split(":")[0]);
                for (int i = 0; i < quantity; i++) {
                  times.add("${startHour + i}:00");
                }
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _unavailableTimes = times;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal memuat jadwal: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTimes = false;
        });
      }
    }
  }

  void _calculateTotalPrice() {
    if (selectedLapangan == null ||
        selectedHour == null ||
        bookingDuration <= 0) {
      setState(() => _totalPrice = 0);
      return;
    }

    double cumulativePrice = 0.0;
    final int startHour = int.parse(selectedHour!.split(":")[0]);

    for (int i = 0; i < bookingDuration; i++) {
      final int currentHour = startHour + i;
      double priceForThisHour = _getPriceForHour(currentHour).toDouble();
      if (isMember) {
        priceForThisHour *= 0.9;
      }
      cumulativePrice += priceForThisHour;
    }

    int newTotal = cumulativePrice.round();
    if (_usePhotographer) newTotal += photographerPrice;
    if (_useReferee) newTotal += refereePrice;
    if (_useIceBath) newTotal += iceBathPrice;

    setState(() {
      _totalPrice = newTotal;
    });
  }

  int _getPriceForHour(int hour) {
    var lapang = _lapanganData.firstWhere((l) => l['name'] == selectedLapangan,
        orElse: () => {'price': '0', 'name': ''});
    int basePrice = int.tryParse(lapang['price'] ?? '0') ?? 0;
    String lapangName = lapang['name'];

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

  bool isDurationAvailable(int startHour, int duration) {
    for (int i = 0; i < duration; i++) {
      final int currentHour = startHour + i;
      if (currentHour >= 23 || _unavailableTimes.contains("$currentHour:00")) {
        return false;
      }
    }
    return true;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile != null) {
        if (kIsWeb) {
          _webImage = await pickedFile.readAsBytes();
        } else {
          _imageFile = File(pickedFile.path);
        }
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal memilih gambar: $e")));
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null && _webImage == null) return null;
    try {
      String fileName =
          'buktipembayaran/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask;

      if (kIsWeb && _webImage != null) {
        uploadTask = storageRef.putData(_webImage!);
      } else if (_imageFile != null) {
        uploadTask = storageRef.putFile(_imageFile!);
      } else {
        return null;
      }

      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate() || selectedHour == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Harap lengkapi semua data yang diperlukan!')));
      return;
    }

    final dpAmount = int.tryParse(_dpController.text) ?? 0;
    if (_paymentStatus.contains('DP') &&
        (dpAmount <= 0 || dpAmount >= _totalPrice)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jumlah DP tidak valid!')));
      return;
    }

    if ((_paymentStatus.contains('DP') || _paymentStatus.contains('Lunas')) &&
        (_webImage == null && _imageFile == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Bukti pembayaran wajib diunggah untuk status DP atau Lunas!'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final String? paymentProofUrl = await _uploadImage();

      final orderId = 'ADMIN-${DateTime.now().millisecondsSinceEpoch}';
      final lapangInfo =
          _lapanganData.firstWhere((l) => l['name'] == selectedLapangan);
      final int startHour = int.parse(selectedHour!.split(":")[0]);

      String finalStatus;
      int finalDpAmount = 0;
      int finalRemainingAmount = 0;

      if (_paymentStatus.contains('Lunas')) {
        finalStatus = 'Sudah Bayar (Offline)';
        finalDpAmount = _totalPrice;
        finalRemainingAmount = 0;
      } else if (_paymentStatus.contains('DP')) {
        finalStatus = 'DP (Bayar di Tempat)';
        finalDpAmount = dpAmount;
        finalRemainingAmount = _totalPrice - dpAmount;
      } else {
        finalStatus = 'Booking (Bayar di Tempat)';
        finalRemainingAmount = _totalPrice;
      }

      await FirebaseFirestore.instance.collection('bookings').doc(orderId).set({
        'orderId': orderId,
        'userId': 'admin_manual',
        'userName': _namaPemesanController.text,
        'userPhone': _noWaController.text,
        'totalAmount': _totalPrice,
        'statusBooking': finalStatus,
        'downPaymentAmount': finalDpAmount,
        'remainingAmount': finalRemainingAmount,
        'paymentProofUrl': paymentProofUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'isMember': isMember,
        'items': [
          {
            'name': lapangInfo['name'],
            'bookingDate': DateFormat('yyyy-MM-dd').format(selectedDate!),
            'time': selectedHour,
            'endTime': '${startHour + bookingDuration}:00',
            'quantity': bookingDuration.toString(),
            'teamName': _teamNameController.text,
            'usePhotographer': _usePhotographer,
            'useReferee': _useReferee,
            'useIceBath': _useIceBath,
            'price': lapangInfo['price'],
            'imagePath': lapangInfo['image_path'],
            'lapangId': lapangInfo['id'],
          }
        ],
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Booking berhasil ditambahkan!'),
        backgroundColor: Colors.green,
      ));
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menyimpan booking: $e'),
          backgroundColor: Colors.red));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Booking Manual'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[200],
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: AbsorbPointer(
                  absorbing: _isUploading,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('1. Pilih Lapangan & Tanggal'),
                      _buildLapanganSelector(),
                      const SizedBox(height: 16),
                      WeeklyCalendar(
                        currentStartOfWeek: _currentStartOfWeek,
                        selectedDate: selectedDate,
                        onDateSelected: (date) {
                          setState(() {
                            selectedDate = date;
                          });
                          if (selectedLapangan != null)
                            _fetchUnavailableTimes();
                        },
                        onCalendarIconPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 90)),
                          );
                          if (date != null) {
                            setState(() {
                              selectedDate = date;
                              _currentStartOfWeek = date
                                  .subtract(Duration(days: date.weekday - 1));
                            });
                            if (selectedLapangan != null)
                              _fetchUnavailableTimes();
                          }
                        },
                      ),
                      const Divider(height: 40),
                      _buildSectionTitle('2. Pilih Jadwal',
                          enabled:
                              selectedLapangan != null && selectedDate != null),
                      _buildTimePicker(),
                      const SizedBox(height: 16),
                      _buildDurationPicker(),
                      const Divider(height: 40),
                      _buildSectionTitle('3. Data Pemesan',
                          enabled: selectedHour != null),
                      _buildCustomerDataForm(),
                      const Divider(height: 40),
                      _buildSectionTitle('4. Layanan & Pembayaran',
                          enabled: selectedHour != null),
                      _buildAddonsAndPayment(),
                      const Divider(height: 40),
                      _buildSubmitSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: enabled ? Colors.black87 : Colors.grey.shade400,
            ),
      ),
    );
  }

  Widget _buildLapanganSelector() {
    return DropdownButtonFormField<String>(
      value: selectedLapangan,
      hint: const Text('Pilih lapangan...'),
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: _lapanganData.map((lapang) {
        return DropdownMenuItem<String>(
            value: lapang['name'], child: Text(lapang['name']));
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedLapangan = value;
          selectedHour = null;
        });
        if (selectedDate != null) _fetchUnavailableTimes();
      },
      validator: (v) => v == null ? 'Lapangan harus dipilih' : null,
    );
  }

  Widget _buildTimePicker() {
    bool enabled = selectedLapangan != null && selectedDate != null;
    if (!enabled)
      return const Center(
          child: Text("Pilih lapangan dan tanggal terlebih dahulu."));
    if (_isLoadingTimes)
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.black)));

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: List.generate(16, (index) {
        final hour = 7 + index;
        final timeStr = "$hour:00";
        final now = DateTime.now();
        final bookingTime = DateTime(
            selectedDate!.year, selectedDate!.month, selectedDate!.day, hour);
        final bool isPast = bookingTime.isBefore(now);
        final bool isBooked = _unavailableTimes.contains(timeStr);
        final int startHour =
            selectedHour != null ? int.parse(selectedHour!.split(":")[0]) : -1;
        final bool isWithinSelectedDuration = selectedHour != null &&
            hour >= startHour &&
            hour < startHour + bookingDuration;

        return GestureDetector(
          onTap: (isPast || isBooked)
              ? null
              : () {
                  setState(() {
                    selectedHour = timeStr;
                    bookingDuration = 1;
                    _calculateTotalPrice();
                  });
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isWithinSelectedDuration
                  ? Colors.black
                  : (isPast || isBooked ? Colors.grey.shade200 : Colors.white),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isWithinSelectedDuration
                      ? Colors.black
                      : Colors.grey.shade300),
            ),
            child: Text(
              timeStr,
              style: TextStyle(
                color: isWithinSelectedDuration
                    ? Colors.white
                    : (isPast || isBooked
                        ? Colors.grey.shade500
                        : Colors.black),
                fontWeight: isWithinSelectedDuration
                    ? FontWeight.bold
                    : FontWeight.normal,
                decoration:
                    isBooked ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDurationPicker() {
    bool enabled = selectedHour != null;
    if (!enabled) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Durasi (jam)', style: Theme.of(context).textTheme.bodyLarge),
        Row(
          children: [
            IconButton(
              onPressed: bookingDuration > 1
                  ? () {
                      setState(() => bookingDuration--);
                      _calculateTotalPrice();
                    }
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$bookingDuration',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: isDurationAvailable(
                      int.parse(selectedHour!.split(":")[0]),
                      bookingDuration + 1)
                  ? () {
                      setState(() => bookingDuration++);
                      _calculateTotalPrice();
                    }
                  : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildCustomerDataForm() {
    bool enabled = selectedHour != null;
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Column(
          children: [
            TextFormField(
              controller: _namaPemesanController,
              decoration: const InputDecoration(
                  labelText: 'Nama Pemesan', border: OutlineInputBorder()),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Nama pemesan wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noWaController,
              decoration: const InputDecoration(
                  labelText: 'No. WhatsApp',
                  border: OutlineInputBorder(),
                  prefixText: '+62 '),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
                  v == null || v.isEmpty ? 'No. WhatsApp wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _teamNameController,
              decoration: const InputDecoration(
                  labelText: 'Nama Tim / Atas Nama (Opsional)',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddonsAndPayment() {
    bool enabled = selectedHour != null;
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Mode Member'),
              subtitle: const Text('Aktifkan untuk diskon 10%'),
              value: isMember,
              onChanged: (val) {
                setState(() => isMember = val);
                _calculateTotalPrice();
              },
              secondary: Icon(isMember ? Icons.star : Icons.star_border),
            ),
            if (selectedLapangan != "Gokart") ...[
              SwitchListTile(
                title: const Text('Photographer'),
                value: _usePhotographer,
                onChanged: (val) {
                  setState(() => _usePhotographer = val);
                  _calculateTotalPrice();
                },
                secondary: const Icon(Icons.camera_alt_outlined),
              ),
              SwitchListTile(
                title: const Text('Wasit'),
                value: _useReferee,
                onChanged: (val) {
                  setState(() => _useReferee = val);
                  _calculateTotalPrice();
                },
                secondary: const Icon(Icons.sports_outlined),
              ),
              SwitchListTile(
                title: const Text('Ice Bath'),
                value: _useIceBath,
                onChanged: (val) {
                  setState(() => _useIceBath = val);
                  _calculateTotalPrice();
                },
                secondary: const Icon(Icons.ac_unit),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentStatus,
              decoration: const InputDecoration(
                  labelText: 'Status Pembayaran', border: OutlineInputBorder()),
              items: [
                'Booking (Bayar di Tempat)',
                'DP (Bayar di Tempat)',
                'Lunas (Bayar di Tempat)'
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _paymentStatus = val!),
            ),
            if (_paymentStatus.contains('DP')) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _dpController,
                decoration: const InputDecoration(
                    labelText: 'Jumlah DP',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp '),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (!_paymentStatus.contains('DP')) return null;
                  return (v == null || v.isEmpty || int.parse(v) <= 0)
                      ? 'DP harus diisi'
                      : null;
                },
              ),
            ],
            if (_paymentStatus.contains('DP') ||
                _paymentStatus.contains('Lunas')) ...[
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
        Text('Bukti Pembayaran (Wajib)',
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 150,
            width: double.infinity,
            clipBehavior:
                Clip.antiAlias, // Ensures the image respects the border radius
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: (_webImage != null)
                ? Image.memory(_webImage!, fit: BoxFit.cover)
                : (_imageFile != null)
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.add_a_photo_outlined,
                            color: Colors.grey.shade600),
                        const SizedBox(height: 4),
                        Text('Unggah Bukti',
                            style: TextStyle(color: Colors.grey.shade700)),
                      ])),
          ),
        )
      ],
    );
  }

  Widget _buildSubmitSection() {
    bool enabled = selectedHour != null && !_isUploading;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Harga",
                  style: TextStyle(fontSize: 16, color: Colors.grey[700])),
              Text(
                NumberFormat.currency(
                        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                    .format(_totalPrice),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: enabled ? _submitBooking : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              child: _isUploading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ))
                  : const Text('Simpan Booking',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET KALENDER YANG TELAH DIPERBAIKI ---
class WeeklyCalendar extends StatelessWidget {
  final DateTime currentStartOfWeek;
  final Function(DateTime) onDateSelected;
  final DateTime? selectedDate;
  final VoidCallback onCalendarIconPressed;
  final bool enabled;

  const WeeklyCalendar({
    Key? key,
    required this.currentStartOfWeek,
    required this.onDateSelected,
    this.selectedDate,
    required this.onCalendarIconPressed,
    this.enabled = true,
  }) : super(key: key);

  // Fungsi helper untuk mendapatkan nama hari manual
  String _getIndonesianDayAbbreviation(int weekday) {
    // weekday: 1=Senin, 7=Minggu
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.start,
                children: List.generate(7, (index) {
                  final date = currentStartOfWeek.add(Duration(days: index));
                  final now = DateTime.now();

                  // Normalisasi tanggal untuk perbandingan yang akurat
                  final today = DateTime(now.year, now.month, now.day);
                  final currentDate = DateTime(date.year, date.month, date.day);
                  final isPast = currentDate.isBefore(today);

                  final isSelected = selectedDate != null &&
                      date.year == selectedDate!.year &&
                      date.month == selectedDate!.month &&
                      date.day == selectedDate!.day;

                  return GestureDetector(
                    onTap: isPast ? null : () => onDateSelected(date),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      width: 48,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isSelected
                                ? Colors.black
                                : Colors.grey.shade300),
                      ),
                      child: Opacity(
                        opacity: isPast ? 0.5 : 1.0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              // Menggunakan fungsi helper manual
                              _getIndonesianDayAbbreviation(date.weekday),
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              // 'DateFormat' untuk angka tanggal aman digunakan
                              DateFormat('d').format(date),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined),
              onPressed: onCalendarIconPressed,
            ),
          ],
        ),
      ),
    );
  }
}
