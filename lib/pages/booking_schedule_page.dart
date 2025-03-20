import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:mandalaarenaapp/pages/add_recurring_booking_page.dart'; // Untuk membaca file JSON

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
    final String jsonString = await DefaultAssetBundle.of(context)
        .loadString('assets/lapang.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    setState(() {
      lapangData = jsonData.cast<Map<String, dynamic>>();
      lapanganList = lapangData.map((lapang) => lapang['name'] as String).toList();
    });
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20.0), // Padding horizontal
                  child: GridView.builder(
                    padding: EdgeInsets.all(10), // Padding grid
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6, // 4 kolom untuk tampilan jam
                      crossAxisSpacing: 15, // Jarak horizontal antar jam
                      mainAxisSpacing: 15, // Jarak vertikal antar jam
                      childAspectRatio: 1.2, // Ukuran tombol menyesuaikan dengan text
                    ),
                    itemCount: 14, // Jam dari 08:00 hingga 21:00
                    itemBuilder: (context, index) {
                      final hour = 8 + index;
                      final time = '$hour:00';
                      final isBooked = bookedTimes.contains(time);

                      return GestureDetector(
                        onTap: isBooked
                            ? () {
                                // Tampilkan popup detail booking
                                final booking = snapshot.data!.docs.firstWhere((booking) {
                                  final data = booking.data() as Map<String, dynamic>;
                                  final jamMulai = data['jamMulai'] as String? ?? '';
                                  final jamSelesai = data['jamSelesai'] as String? ?? '';
                                  final startHour = int.parse(jamMulai.split(':')[0]);
                                  final endHour = int.parse(jamSelesai.split(':')[0]);
                                  return hour >= startHour && hour < endHour;
                                });
                                final data = booking.data() as Map<String, dynamic>;
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Detail Booking'),
                                    content: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Lapangan: ${data['lapangan']}'),
                                        Text('Tanggal: ${data['tanggal']}'),
                                        Text('Jam: ${data['jamMulai']} - ${data['jamSelesai']}'),
                                        Text('Nama: ${data['namaPengguna']}'),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: Text('Tutup'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            : null, // Tombol jam yang tersedia tidak bisa diklik
                        child: Container(
                          decoration: BoxDecoration(
                            color: isBooked ? Colors.grey[300] : Colors.white,
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              time,
                              style: TextStyle(
                                color: isBooked ? Colors.black : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14, // Ukuran font disesuaikan
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