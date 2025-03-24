import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:mandalaarenaapp/pages/add_recurring_booking_page.dart';
import 'package:mandalaarenaapp/pages/bookingpage.dart';

class BookingSchedulePage extends StatefulWidget {
  @override
  _BookingSchedulePageState createState() => _BookingSchedulePageState();
}

class _BookingSchedulePageState extends State<BookingSchedulePage> {
  String? selectedLapangan = 'Lapang Minisoccer'; // Default lapangan
  DateTime? selectedDate = DateTime.now(); // Default hari ini
  List<String> lapanganList = [];
  List<Map<String, dynamic>> lapangData = [];

  @override
  void initState() {
    super.initState();
    _loadLapangData();
  }

  // Load data lapang dari file JSON
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

  // Tampilkan popup pemilihan lapangan
  void _showLapanganSelectionPopup(BuildContext context, String selectedTime) {
    final lapanganOptions = [
      'Lapang Basket Vynil',
      'Lapang Basket Karet',
      'Lapang Basket 3x3',
      'Lapang Minisoccer',
      'Gokart',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pilih Lapangan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: lapanganOptions.map((lapangan) {
            return ListTile(
              title: Text(lapangan),
              onTap: () {
                Navigator.of(context).pop(); // Tutup popup
                _navigateToBookingPage(context, lapangan, selectedTime);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // Navigasi ke halaman BookingPage
  void _navigateToBookingPage(
      BuildContext context, String lapangan, String selectedTime) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingPage(
          lapangan: lapangan,
          selectedTime: selectedTime,
          selectedDate: selectedDate!,
        ),
      ),
    );
  }

  // Cek apakah jam sudah terlewat
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jadwal Booking'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                // Navigasi ke halaman tambah booking langganan
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddRecurringBookingPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Lapangan
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
          // Tombol Pilih Tanggal dan Teks Tanggal yang Dipilih
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
                      // firstDate: DateTime.now(),
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
                  .where('lapangan', isEqualTo: selectedLapangan)
                  .where('tanggal',
                      isEqualTo: selectedDate != null
                          ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                          : null)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                // Buat daftar jam yang sudah dibooking
                final bookedTimes = <String>[];
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final bookings = snapshot.data!.docs;
                  for (var booking in bookings) {
                    final data = booking.data() as Map<String, dynamic>;
                    final jamMulai = data['jamMulai'] as String? ?? '';
                    final jamSelesai = data['jamSelesai'] as String? ?? '';
                    if (jamMulai.isNotEmpty && jamSelesai.isNotEmpty) {
                      final startHour = int.parse(jamMulai.split(':')[0]);
                      final endHour = int.parse(jamSelesai.split(':')[0]);
                      for (int i = startHour; i < endHour; i++) {
                        bookedTimes.add('$i:00');
                      }
                    }
                  }
                }

                // Tampilkan jam dari 08:00 hingga 21:00
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
                    itemCount: 14, // Jam dari 08:00 hingga 21:00
                    itemBuilder: (context, index) {
                      final hour = 8 + index;
                      final time = '$hour:00';
                      final isBooked = bookedTimes.contains(time);
                      final isPast = _isTimePast(time);

                      return GestureDetector(
                        onTap: isBooked
                            ? () {
                                // Tampilkan popup detail booking
                                final booking =
                                    snapshot.data!.docs.firstWhere((booking) {
                                  final data =
                                      booking.data() as Map<String, dynamic>;
                                  final jamMulai =
                                      data['jamMulai'] as String? ?? '';
                                  final jamSelesai =
                                      data['jamSelesai'] as String? ?? '';
                                  final startHour =
                                      int.parse(jamMulai.split(':')[0]);
                                  final endHour =
                                      int.parse(jamSelesai.split(':')[0]);
                                  return hour >= startHour && hour < endHour;
                                });
                                final data =
                                    booking.data() as Map<String, dynamic>;
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Detail Booking'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Lapangan: ${data['lapangan']}'),
                                          Text('Tanggal: ${data['tanggal']}'),
                                          Text(
                                              'Jam: ${data['jamMulai']} - ${data['jamSelesai']}'),
                                          Text('Nama: ${data['namaPengguna']}'),
                                          Text(
                                              'No WhatsApp: ${data['noWhatsapp']}'),
                                          Text(
                                              'Nama Tim/Atas Nama: ${data['teamName']}'),
                                          if (data['usePhotographer'] == true)
                                            Text(
                                                'Layanan: Photographer (+Rp 200,000)'),
                                          if (data['useReferee'] == true)
                                            Text('Layanan: Wasit (+Rp 70,000)'),
                                          Text(
                                              'Total Harga: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(data['totalPrice'])}'),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: Text('Tutup'),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () async {
                                          final shouldDelete =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('Konfirmasi Hapus'),
                                              content: Text(
                                                  'Yakin ingin menghapus booking ini?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(false),
                                                  child: Text('Batal'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(true),
                                                  child: Text('Hapus',
                                                      style: TextStyle(
                                                          color: Colors.red)),
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

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        'Booking berhasil dihapus.')),
                                              );

                                              Navigator.of(context)
                                                  .pop(); // Tutup popup detail
                                              setState(
                                                  () {}); // Perbarui tampilan
                                            } catch (e) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        'Gagal menghapus booking: $e')),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                );
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
                                    _showLapanganSelectionPopup(context, time);
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
