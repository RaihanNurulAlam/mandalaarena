import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AddRecurringBookingPage extends StatefulWidget {
  @override
  _AddRecurringBookingPageState createState() => _AddRecurringBookingPageState();
}

class _AddRecurringBookingPageState extends State<AddRecurringBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaTimController = TextEditingController();
  final _keteranganController = TextEditingController();
  String? _selectedLapangan;
  String? _selectedHari;
  String? _selectedJam;
  int? _selectedDurasi;

  final List<String> _lapanganList = [
    'Lapang Minisoccer',
    'Lapang Basket Vynil',
    'Lapang Basket Karet',
    'Lapang Basket 3x3',
    'Gokart',
  ];

  final List<String> _hariList = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  final List<String> _jamList = List.generate(14, (index) => '${8 + index}:00');
  final List<int> _durasiList = [1, 2, 3, 4, 5];

  // Data lapangan dari lapang.json
  final Map<String, Map<String, String>> _lapangData = {
    'Lapang Minisoccer': {
      'imagePath': 'assets/mini.JPG',
      'price': '500000',
    },
    'Lapang Basket Vynil': {
      'imagePath': 'assets/vynil.JPG',
      'price': '250000',
    },
    'Lapang Basket Karet': {
      'imagePath': 'assets/rubber.JPG',
      'price': '250000',
    },
    'Lapang Basket 3x3': {
      'imagePath': 'assets/3x3.JPG',
      'price': '150000',
    },
    'Gokart': {
      'imagePath': 'assets/gokart.JPG',
      'price': '100000',
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Booking Langganan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedLapangan,
                hint: Text('Pilih Lapangan'),
                items: _lapanganList.map((lapangan) {
                  return DropdownMenuItem<String>(
                    value: lapangan,
                    child: Text(lapangan),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLapangan = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Pilih lapangan';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedHari,
                hint: Text('Pilih Hari'),
                items: _hariList.map((hari) {
                  return DropdownMenuItem<String>(
                    value: hari,
                    child: Text(hari),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedHari = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Pilih hari';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedJam,
                hint: Text('Pilih Jam'),
                items: _jamList.map((jam) {
                  return DropdownMenuItem<String>(
                    value: jam,
                    child: Text(jam),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedJam = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Pilih jam';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedDurasi,
                hint: Text('Pilih Durasi (jam)'),
                items: _durasiList.map((durasi) {
                  return DropdownMenuItem<int>(
                    value: durasi,
                    child: Text('$durasi Jam'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDurasi = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Pilih durasi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _namaTimController,
                decoration: InputDecoration(
                  labelText: 'Nama Tim / Pengguna',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan nama tim/pengguna';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _keteranganController,
                decoration: InputDecoration(
                  labelText: 'Keterangan Langganan',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan keterangan';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitBooking,
                child: Text('Simpan Booking Langganan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fungsi untuk menghitung tanggal terdekat berdasarkan hari yang dipilih
  DateTime _getNearestDate(String selectedDay) {
    final now = DateTime.now();
    final currentDay = DateFormat('EEEE').format(now); // Hari sekarang (misal: Senin)

    // Cari selisih hari antara hari sekarang dan hari yang dipilih
    final daysToAdd = _getDaysToAdd(currentDay, selectedDay);

    // Tambahkan selisih hari ke tanggal sekarang
    return now.add(Duration(days: daysToAdd));
  }

  // Fungsi untuk menghitung selisih hari
  int _getDaysToAdd(String currentDay, String selectedDay) {
    final daysOfWeek = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final currentIndex = daysOfWeek.indexOf(currentDay);
    final selectedIndex = daysOfWeek.indexOf(selectedDay);

    if (selectedIndex > currentIndex) {
      return selectedIndex - currentIndex;
    } else if (selectedIndex == currentIndex) {
      return 7; // Jika hari yang dipilih sama dengan hari sekarang, gunakan minggu depan
    } else {
      return 7 - (currentIndex - selectedIndex); // Jika hari yang dipilih sudah lewat, gunakan minggu depan
    }
  }

  Future<void> _submitBooking() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser; // Ambil user yang sedang login
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>;

      // Ambil imagePath dan price berdasarkan lapangan yang dipilih
      final lapangInfo = _lapangData[_selectedLapangan]!;
      final imagePath = lapangInfo['imagePath']!;
      final price = lapangInfo['price']!;

      // Hitung tanggal terdekat berdasarkan hari yang dipilih
      final nearestDate = _getNearestDate(_selectedHari!);

      final bookingData = {
        'duration': _selectedDurasi.toString(), // Durasi sebagai string
        'imagePath': imagePath, // Sesuaikan dengan lapangan
        'jamMulai': _selectedJam,
        'jamSelesai': _calculateEndTime(_selectedJam!, _selectedDurasi!),
        'lapangId': _getLapangId(_selectedLapangan!), // Ambil ID lapangan
        'lapangan': _selectedLapangan,
        'namaPengguna': userData['username'], // Ambil username dari user
        'noWhatsapp': userData['phone'] ?? '', // Ambil nomor WhatsApp dari user
        'price': price, // Sesuaikan dengan lapangan
        'statusBooking': 'Pending', // Status default
        'tanggal': DateFormat('yyyy-MM-dd').format(nearestDate), // Gunakan tanggal terdekat
        'userId': user?.uid, // User ID yang sedang login
        'hari': _selectedHari, // Hari booking langganan
        'isRecurring': true, // Menandakan booking langganan
      };

      // Simpan ke Firestore
      await FirebaseFirestore.instance.collection('bookings').add(bookingData);

      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking langganan berhasil disimpan!')),
      );

      // Kembali ke halaman sebelumnya
      Navigator.pop(context);
    }
  }

  // Fungsi untuk menghitung jam selesai
  String _calculateEndTime(String startTime, int duration) {
    final startHour = int.parse(startTime.split(':')[0]);
    final endHour = startHour + duration;
    return '$endHour:00';
  }

  // Fungsi untuk mendapatkan ID lapangan berdasarkan nama
  String _getLapangId(String lapangan) {
    switch (lapangan) {
      case 'Lapang Minisoccer':
        return '4';
      case 'Lapang Basket Vynil':
        return '1';
      case 'Lapang Basket Karet':
        return '2';
      case 'Lapang Basket 3x3':
        return '3';
      case 'Gokart':
        return '5';
      default:
        return '0';
    }
  }
}