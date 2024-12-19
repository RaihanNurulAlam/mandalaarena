// ignore_for_file: library_private_types_in_public_api, use_key_in_widget_constructors, sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/pages/payment_page.dart';

class BookingPage extends StatefulWidget {
  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? selectedDate;
  int? selectedStartHour;
  int duration = 1;
  final int pricePerHour = 200000; // Harga per jam

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Lapangan'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Lapangan
            Image.asset(
              'assets/lapangan1.jpg',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 16),

            // Deskripsi Lapangan
            Text(
              'Lapangan Mini Soccer 1',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Lapangan dengan rumput sintetis berkualitas tinggi, cocok untuk pertandingan dan latihan.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),

            // Rating
            Row(
              children: List.generate(5, (index) => Icon(Icons.star, color: Colors.amber)),
            ),
            SizedBox(height: 16),

            // Pilih Tanggal
            Text('Pilih Tanggal:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(DateTime.now().year + 1),
                );
                if (pickedDate != null) {
                  setState(() {
                    selectedDate = pickedDate;
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  selectedDate == null
                      ? 'Pilih Tanggal'
                      : DateFormat('dd MMM yyyy').format(selectedDate!),
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Pilih Jam Mulai
            Text('Pilih Jam Mulai:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: List.generate(14, (index) {
                int hour = index + 8; // Jam mulai dari 8 pagi hingga 9 malam
                return ChoiceChip(
                  label: Text('$hour:00'),
                  selected: selectedStartHour == hour,
                  onSelected: (selected) {
                    setState(() {
                      selectedStartHour = selected ? hour : null;
                    });
                  },
                );
              }),
            ),
            SizedBox(height: 16),

            // Lama Booking
            Text('Lama Booking (jam):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: List.generate(5, (index) {
                int hours = index + 1;
                return ChoiceChip(
                  label: Text('$hours Jam'),
                  selected: duration == hours,
                  onSelected: (selected) {
                    setState(() {
                      duration = selected ? hours : duration;
                    });
                  },
                );
              }),
            ),
            SizedBox(height: 16),

            // Tombol Bayar
            ElevatedButton(
              onPressed: () {
                if (selectedDate != null && selectedStartHour != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentPage(
                        date: selectedDate!,
                        startHour: selectedStartHour!,
                        duration: duration,
                        total: duration * pricePerHour,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Harap pilih tanggal dan jam!')),
                  );
                }
              },
              child: Text('Bayar'),
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
            ),
          ],
        ),
      ),
    );
  }
}