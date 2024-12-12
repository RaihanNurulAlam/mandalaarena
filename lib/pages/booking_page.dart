// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';

class BookingPage extends StatefulWidget {
  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  int? selectedField;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  int selectedDuration = 1;

  final List<Map<String, dynamic>> fields = [
    {'id': 1, 'name': 'Lapangan A', 'photo': 'assets/images/mandalaarena1.jpg'},
    {'id': 2, 'name': 'Lapangan B', 'photo': 'assets/lapangan_b.jpg'},
    {'id': 3, 'name': 'Lapangan C', 'photo': 'assets/lapangan_c.jpg'},
  ];

  void _selectDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  void _selectTime() async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  void _confirmBooking() {
    if (selectedField == null || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Harap lengkapi semua pilihan!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Booking'),
        content: Text(
            'Lapangan: ${fields.firstWhere((f) => f['id'] == selectedField)['name']}\n'
            'Tanggal: ${selectedDate!.toLocal().toString().split(' ')[0]}\n'
            'Jam: ${selectedTime!.format(context)}\n'
            'Durasi: $selectedDuration jam'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Booking berhasil!')),
              );
            },
            child: Text('Bayar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Booking Lapangan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Lapangan:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: fields.length,
                itemBuilder: (context, index) {
                  final field = fields[index];
                  return ListTile(
                    leading: Image.asset(field['photo'], width: 50, height: 50),
                    title: Text(field['name']),
                    trailing: Radio<int>(
                      value: field['id'],
                      groupValue: selectedField,
                      onChanged: (value) {
                        setState(() {
                          selectedField = value;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Text('Pilih Tanggal:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: _selectDate,
              child: Text(selectedDate == null
                  ? 'Pilih Tanggal'
                  : '${selectedDate!.toLocal()}'.split(' ')[0]),
            ),
            SizedBox(height: 16),
            Text('Pilih Jam Mulai:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: _selectTime,
              child: Text(selectedTime == null
                  ? 'Pilih Jam'
                  : selectedTime!.format(context)),
            ),
            SizedBox(height: 16),
            Text('Durasi (jam):',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            DropdownButton<int>(
              value: selectedDuration,
              items: [1, 2, 3, 4].map((e) {
                return DropdownMenuItem<int>(
                  value: e,
                  child: Text('$e jam'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDuration = value!;
                });
              },
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmBooking,
                child: Text('Bayar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
