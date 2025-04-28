// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/pages/bookingpage.dart';
import 'package:mandalaarenaapp/pages/edit_bookingpage.dart';

class BookingSchedulePage extends StatefulWidget {
  @override
  _BookingSchedulePageState createState() => _BookingSchedulePageState();
}

class _BookingSchedulePageState extends State<BookingSchedulePage> {
  String? selectedLapangan = 'Lapang Minisoccer';
  DateTime? selectedDate = DateTime.now();
  List<String> lapanganList = [];
  List<Map<String, dynamic>> lapangData = [];

  @override
  void initState() {
    super.initState();
    _loadLapangData();
  }

  Future<void> _loadLapangData() async {
    final String jsonString =
        await DefaultAssetBundle.of(context).loadString('assets/lapang.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    setState(() {
      lapangData = jsonData.cast<Map<String, dynamic>>();
      lapanganList =
          lapangData.map((lapang) => lapang['name'] as String).toList();
    });
  }

  void _navigateToBookingPage(BuildContext context, String selectedTime) {
    if (selectedLapangan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silakan pilih lapangan terlebih dahulu')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingPage(
          lapangan: selectedLapangan!,
          selectedTime: selectedTime,
          selectedDate: selectedDate!,
        ),
      ),
    );
  }

  bool _isTimePast(String time) {
    if (selectedDate == null) return false;

    final now = DateTime.now();
    final selectedDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      int.parse(time.split(':')[0]),
    );

    return selectedDateTime.isBefore(now);
  }

  void _showBookingDetailPopup(BuildContext context, DocumentSnapshot booking) {
    final data = booking.data() as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    final firstItem = items.isNotEmpty ? items[0] : {};

    final status = data['statusBooking'] ?? 'Pending';
    final isPaid = status.contains('Sudah Bayar');
    final isBookingOnSite = status.contains('Booking');
    final totalAmount = data['totalAmount'] ?? 0;
    final quantity = int.tryParse(firstItem['quantity'] ?? '1') ??
        1; // Gunakan quantity sebagai durasi
    final downPayment = data['downPaymentAmount'] ?? 0;
    final remainingAmount = data['remainingAmount'] ?? 0;
    final paymentProofUrl = data['paymentProofUrl'] as String?;
    final bool _isPaidFull = remainingAmount == 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Booking'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.sports),
                title: Text('Lapangan'),
                subtitle: Text(firstItem['name'] ?? '-'),
              ),
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text('Tanggal'),
                subtitle: Text(firstItem['bookingDate'] ?? '-'),
              ),
              ListTile(
                leading: Icon(Icons.access_time),
                title: Text('Jam'),
                subtitle: Text(
                    '${firstItem['time']} (Durasi: ${firstItem['quantity']} jam)'),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Nama Pemesan'),
                subtitle: Text(data['userName'] ?? '-'),
              ),
              ListTile(
                leading: Icon(Icons.phone),
                title: Text('No WhatsApp'),
                subtitle: Text(data['userPhone'] ?? '-'),
              ),
              ListTile(
                leading: Icon(Icons.group),
                title: Text('Nama Tim/Atas Nama'),
                subtitle: Text(firstItem['teamName'] ?? '-'),
              ),
              if (firstItem['usePhotographer'] == true)
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Photographer'),
                  subtitle: Text('Rp 200,000'),
                ),
              if (firstItem['useReferee'] == true)
                ListTile(
                  leading: Icon(Icons.sports_score),
                  title: Text('Wasit'),
                  subtitle: Text('Rp 70,000'),
                ),
              ListTile(
                leading: Icon(Icons.payment),
                title: Text('Status Pembayaran'),
                subtitle: Text(
                  status,
                  style: TextStyle(
                    color: isPaid
                        ? Colors.green
                        : isBookingOnSite
                            ? Colors.blue
                            : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!isBookingOnSite) ...[
                ListTile(
                  leading: Icon(Icons.money),
                  title: Text('Total Pembayaran'),
                  subtitle: Text(
                    'Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(totalAmount)}',
                  ),
                ),
                if (!_isPaidFull) ...[
                  ListTile(
                    leading: Icon(Icons.payment),
                    title: Text('DP Dibayar'),
                    subtitle: Text(
                      'Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(downPayment)}',
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.payment),
                    title: Text('Sisa Pembayaran'),
                    subtitle: Text(
                      'Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(remainingAmount)}',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ],
              if (paymentProofUrl != null && !isBookingOnSite) ...[
                ListTile(
                  leading: Icon(Icons.image),
                  title: Text('Bukti Pembayaran'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Image.network(
                    paymentProofUrl,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Text('Gagal memuat gambar'),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.black, // Warna latar belakang hitam
              foregroundColor: Colors.white, // Warna teks putih
            ),
            child: Text('Tutup'),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue),
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToEditPage(context, booking);
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final shouldDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Konfirmasi Hapus'),
                  content: Text('Yakin ingin menghapus booking ini?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            Colors.black, // Warna latar belakang hitam
                        foregroundColor: Colors.white, // Warna teks putih
                      ),
                      child: Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            Colors.black, // Warna latar belakang hitam
                        foregroundColor: Colors.white, // Warna teks putih
                      ),
                      child: Text('Hapus'),
                    ),
                  ],
                ),
              );

              if (shouldDelete == true) {
                try {
                  await FirebaseFirestore.instance
                      .collection('bookings')
                      .doc(booking.id)
                      .delete();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Booking berhasil dihapus.')),
                  );

                  Navigator.of(context).pop();
                  setState(() {});
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus booking: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _navigateToEditPage(BuildContext context, DocumentSnapshot booking) {
    final data = booking.data() as Map<String, dynamic>;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBookingPage(
          bookingId: booking.id,
          initialData: data,
          lapangan: selectedLapangan!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jadwal Booking'),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: DropdownButtonFormField<String>(
              value: selectedLapangan,
              hint: Text('Pilih Lapangan'),
              items: lapanganList.map((String lapangan) {
                return DropdownMenuItem<String>(
                  value: lapangan,
                  child: Text(lapangan),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  selectedLapangan = value;
                });
              },
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? 'Tanggal Dipilih: ${DateFormat('EEEE, dd MMMM yyyy').format(selectedDate!)}'
                        : 'Pilih Tanggal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('items', isNotEqualTo: null)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final bookedTimes = <String, DocumentSnapshot>{};
                final filteredBookings = <DocumentSnapshot>[];

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final bookings = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final items = data['items'] as List<dynamic>? ?? [];
                    if (items.isEmpty) return false;

                    final firstItem = items[0];
                    final lapangan = firstItem['name'] as String?;
                    final bookingDate = firstItem['bookingDate'] as String?;

                    // Filter by selected lapangan and date
                    if (selectedLapangan != null &&
                        lapangan != selectedLapangan) {
                      return false;
                    }

                    if (selectedDate != null && bookingDate != null) {
                      final date = DateFormat('yyyy-MM-dd').parse(bookingDate);
                      return date.year == selectedDate!.year &&
                          date.month == selectedDate!.month &&
                          date.day == selectedDate!.day;
                    }

                    return true;
                  }).toList();

                  filteredBookings.addAll(bookings);

                  for (var booking in bookings) {
                    final data = booking.data() as Map<String, dynamic>;
                    final items = data['items'] as List<dynamic>? ?? [];
                    if (items.isEmpty) continue;

                    final firstItem = items[0];
                    final time = firstItem['time'] as String? ?? '';
                    final quantity =
                        int.tryParse(firstItem['quantity'] ?? '1') ??
                            1; // Gunakan quantity sebagai durasi
                    if (time.isNotEmpty) {
                      final startHour = int.parse(time.split(':')[0]);

                      // Tandai semua jam dalam quantity sebagai sudah dibooking
                      for (int i = 0; i < quantity; i++) {
                        final bookedTime = '${startHour + i}:00';
                        bookedTimes[bookedTime] = booking;
                      }
                    }
                  }
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: GridView.builder(
                    padding: EdgeInsets.all(10),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: 14,
                    itemBuilder: (context, index) {
                      final hour = 8 + index;
                      final time = '$hour:00';
                      final isBooked = bookedTimes.containsKey(time);
                      final isPast = _isTimePast(time);

                      return GestureDetector(
                        onTap: isBooked
                            ? () {
                                final booking = bookedTimes[time]!;
                                _showBookingDetailPopup(context, booking);
                              }
                            : isPast
                                ? () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Maaf'),
                                        content: Text(
                                            'Jam sudah terlewat dan tidak bisa dibooking.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: Text('OK'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                : () {
                                    _navigateToBookingPage(context, time);
                                  },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isBooked
                                ? Colors.grey[300]
                                : isPast
                                    ? Colors.grey[100]
                                    : Colors.white,
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              time,
                              style: TextStyle(
                                color: isBooked ? Colors.black : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
