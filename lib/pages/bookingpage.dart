// ignore_for_file: sort_child_properties_last, use_super_parameters

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingPage extends StatefulWidget {
  final String lapangan;
  final String selectedTime;
  final DateTime selectedDate;

  const BookingPage({
    Key? key,
    required this.lapangan,
    required this.selectedTime,
    required this.selectedDate,
  }) : super(key: key);

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  int bookingDuration = 1;
  bool usePhotographer = false;
  bool useReferee = false;
  String teamName = "";
  final _formKey = GlobalKey<FormState>();

  Future<void> _addBooking() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Harap isi nama tim/nama pemesan!')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anda harus login terlebih dahulu!')),
      );
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data pengguna tidak ditemukan!')),
      );
      return;
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final userName = userData['name'];
    final userPhone = userData['phone'];

    final bookingData = {
      'lapangan': widget.lapangan,
      'tanggal': DateFormat('yyyy-MM-dd').format(widget.selectedDate),
      'jamMulai': widget.selectedTime,
      'jamSelesai': DateFormat('HH:mm').format(
        DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          widget.selectedDate.day,
          int.parse(widget.selectedTime.split(':')[0]) + bookingDuration,
        ),
      ),
      'statusBooking': 'Pending',
      'userId': user.uid,
      'namaPengguna': userName,
      'noWhatsapp': userPhone,
      'duration': bookingDuration.toString(),
      'teamName': teamName,
      'usePhotographer': usePhotographer,
      'useReferee': useReferee,
      'totalPrice': _calculateTotalPrice(),
    };

    try {
      await FirebaseFirestore.instance.collection('bookings').add(bookingData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking berhasil!')),
      );
      Navigator.of(context).pop(); // Kembali ke BookingSchedulePage
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan booking: $e')),
      );
    }
  }

  int _calculateTotalPrice() {
    // Hitung total harga berdasarkan lapangan dan durasi
    int pricePerHour = 100000; // Contoh harga per jam
    int totalPrice = pricePerHour * bookingDuration;

    if (usePhotographer) totalPrice += 200000;
    if (useReferee) totalPrice += 70000;

    return totalPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking ${widget.lapangan}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informasi Lapangan
              Text(
                widget.lapangan,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Tanggal: ${DateFormat('dd MMMM yyyy').format(widget.selectedDate)}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Jam: ${widget.selectedTime}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),

              // Form Nama Tim/Atas Nama
              Form(
                key: _formKey,
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Nama Tim/Atas Nama',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harap isi nama tim/nama pemesan!';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() => teamName = value),
                ),
              ),
              SizedBox(height: 20),

              // Pilih Durasi Booking
              Text(
                'Pilih Durasi Booking (jam):',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              DropdownButton<int>(
                value: bookingDuration,
                items: List.generate(5, (index) => index + 1)
                    .map((duration) => DropdownMenuItem<int>(
                          value: duration,
                          child: Text('$duration Jam'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => bookingDuration = value!),
              ),
              SizedBox(height: 20),

              // Tambahan Layanan
              Text(
                'Tambahan Layanan:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              CheckboxListTile(
                title: Text('Photographer (+Rp 200,000)'),
                value: usePhotographer,
                onChanged: (value) => setState(() => usePhotographer = value!),
              ),
              CheckboxListTile(
                title: Text('Wasit (+Rp 70,000)'),
                value: useReferee,
                onChanged: (value) => setState(() => useReferee = value!),
              ),
              SizedBox(height: 20),

              // Tombol Booking Sekarang
              Center(
                child: ElevatedButton(
                  onPressed: _addBooking,
                  child: Text(
                    'Booking Sekarang',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
