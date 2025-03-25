// ignore_for_file: unused_local_variable, avoid_print, deprecated_member_use, use_build_context_synchronously, use_super_parameters, prefer_final_fields

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart';

class BookingPage extends StatefulWidget {
  final String lapangan;
  final String selectedTime;
  final DateTime selectedDate;

  const BookingPage({
    super.key,
    required this.lapangan,
    required this.selectedTime,
    required this.selectedDate,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  int totalPrice = 0;
  int photographerPrice = 200000;
  int refereePrice = 70000;
  int bookingDuration = 1; // Default duration is 1 hour
  bool isMember = false;
  bool usePhotographer = false;
  bool useReferee = false;
  String teamName = "";
  final _formKey = GlobalKey<FormState>();
  List<String> unavailableTimes = [];
  String? userName;
  String? userPhone;
  User? user;

  // Lapang data from the JSON structure
  final List<Map<String, dynamic>> lapangData = [
    {
      "id": "1",
      "name": "Lapang Basket Vynil",
      "description": "Deskripsi Lapang Basket Vynil.",
      "price": "250000",
      "image_path": "assets/vynil.JPG",
      "rating": "4.8",
      "bookings": ["2024-12-24T08:00:00.000Z", "2024-12-24T09:00:00.000Z"],
      "facilities": ["Shower", "Parking Area", "Locker Room"]
    },
    {
      "id": "2",
      "name": "Lapang Basket Karet",
      "description": "Deskripsi Lapang Basket Karet.",
      "price": "250000",
      "image_path": "assets/rubber.JPG",
      "rating": "4.9",
      "bookings": [],
      "facilities": ["Shower", "Parking Area", "Locker Room"]
    },
    {
      "id": "3",
      "name": "Lapang Basket 3x3",
      "description": "Deskripsi Lapang Basket 3x3.",
      "price": "150000",
      "image_path": "assets/3x3.JPG",
      "rating": "4.8",
      "bookings": [],
      "facilities": ["Shower", "Parking Area", "Locker Room"]
    },
    {
      "id": "4",
      "name": "Lapang Minisoccer",
      "description": "Deskripsi Lapang Minisoccer.",
      "price": "500000",
      "image_path": "assets/mini.JPG",
      "rating": "4.8",
      "bookings": [],
      "facilities": ["Shower", "Parking Area", "Locker Room"]
    },
    {
      "id": "5",
      "name": "Gokart",
      "description": "Deskripsi Gokart.",
      "price": "100000",
      "image_path": "assets/gokart.JPG",
      "rating": "4.8",
      "bookings": [],
      "facilities": ["Shower", "Parking Area", "Locker Room"]
    }
  ];

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    isMember = userProvider.isMember;
    _fetchUnavailableTimes();
  }

  void _updateTotalPrice() {
    // Find the selected lapang data
    final selectedLapang = lapangData.firstWhere(
      (lapang) => lapang['name'] == widget.lapangan,
      orElse: () => {},
    );

    if (selectedLapang.isEmpty) {
      return;
    }

    int pricePerHour = int.parse(selectedLapang['price']);

    if (isMember) {
      pricePerHour = (pricePerHour * 0.4).round(); // Diskon 60% untuk member
    }

    totalPrice = bookingDuration * pricePerHour;

    // Tambahkan biaya photographer jika dipilih dan bukan lapang Gokart
    if (usePhotographer && widget.lapangan != "Gokart") {
      totalPrice += photographerPrice;
    }

    // Tambahkan biaya wasit jika dipilih dan bukan lapang Gokart
    if (useReferee && widget.lapangan != "Gokart") {
      totalPrice += refereePrice;
    }

    setState(() {});
  }

  Future<void> _fetchUnavailableTimes() async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    final dayOfWeek = DateFormat('EEEE').format(widget.selectedDate);

    // Ambil booking reguler untuk tanggal yang dipilih
    final bookings = await FirebaseFirestore.instance
        .collection('bookings')
        .where('lapangan', isEqualTo: widget.lapangan)
        .where('tanggal', isEqualTo: formattedDate)
        .get();

    // Ambil booking langganan untuk hari yang sama dengan hari yang dipilih
    final recurringBookings = await FirebaseFirestore.instance
        .collection('bookings')
        .where('lapangan', isEqualTo: widget.lapangan)
        .where('hari', isEqualTo: dayOfWeek)
        .where('isRecurring', isEqualTo: true)
        .get();

    List<String> times = [];
    for (var doc in [...bookings.docs, ...recurringBookings.docs]) {
      final duration = int.tryParse(doc['duration'].toString()) ?? 1;
      final startHour = int.parse(doc['jamMulai'].split(":")[0]);
      for (int i = 0; i < duration; i++) {
        times.add("${startHour + i}:00");
      }
    }
    setState(() {
      unavailableTimes = times;
    });
  }

  // Di bagian _confirmBooking(), ubah menjadi:
  Future<void> _confirmBooking() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap isi nama tim/nama pemesan terlebih dahulu!"),
        ),
      );
      return;
    }

    final currentStartHour = int.parse(widget.selectedTime.split(":")[0]);
    final maxAllowedDuration = 22 - currentStartHour;
    if (bookingDuration > maxAllowedDuration) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Tidak bisa booking pada jam tersebut karena melebihi jam tutup!",
          ),
        ),
      );
      return;
    }

    // Cek ketersediaan slot
    bool isAvailable = true;
    for (int i = 0; i < bookingDuration; i++) {
      final timeToCheck = currentStartHour + i;
      if (unavailableTimes.contains("$timeToCheck:00")) {
        isAvailable = false;
        break;
      }
    }

    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak bisa booking di jam tersebut!")),
      );
      return;
    }

    try {
      // Ambil data pengguna dari Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception("User data not found in Firestore.");
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      userName = userData['name'];
      userPhone = userData['phone'] as String?;

      // Data yang akan disimpan ke Firestore
      final bookingData = {
        'lapangan': widget.lapangan,
        'tanggal': DateFormat('yyyy-MM-dd').format(widget.selectedDate),
        'jamMulai': widget.selectedTime,
        'jamSelesai': DateFormat('HH:mm').format(
          DateTime(
            widget.selectedDate.year,
            widget.selectedDate.month,
            widget.selectedDate.day,
            currentStartHour + bookingDuration,
          ),
        ),
        'statusBooking': 'Pending',
        'userId': user!.uid,
        'namaPengguna': userName,
        'noWhatsapp': userPhone ?? "",
        'duration': bookingDuration.toString(),
        'isMember': isMember,
        'teamName': teamName,
        'usePhotographer': usePhotographer,
        'useReferee': useReferee,
        'totalPrice': totalPrice,
        'createdAt': FieldValue.serverTimestamp(),
        // Tambahkan field lain yang diperlukan untuk payment
        'price': int.parse(lapangData.firstWhere(
          (lapang) => lapang['name'] == widget.lapangan,
          orElse: () => {'price': '0'},
        )['price']),
        'imagePath': lapangData.firstWhere(
          (lapang) => lapang['name'] == widget.lapangan,
          orElse: () => {'image_path': ''},
        )['image_path'],
        'lapangId': lapangData.firstWhere(
          (lapang) => lapang['name'] == widget.lapangan,
          orElse: () => {'id': ''},
        )['id'],
      };

      // Simpan langsung ke collection bookings tanpa melalui cart
      await FirebaseFirestore.instance.collection('bookings').add(bookingData);

      // Tampilkan dialog sukses
      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
    }
  }

  void _showSuccessDialog() {
    final formattedDate =
        DateFormat('dd MMMM yyyy').format(widget.selectedDate);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Booking Berhasil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.lapangan} pada tanggal $formattedDate jam ${widget.selectedTime} dengan durasi $bookingDuration jam telah berhasil dibooking.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Text(
              'Total: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(totalPrice)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    isMember = userProvider.isMember;

    // Find the selected lapang data
    final selectedLapang = lapangData.firstWhere(
      (lapang) => lapang['name'] == widget.lapangan,
      orElse: () => {},
    );

    if (selectedLapang.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Booking')),
        body: Center(child: Text('Lapangan tidak ditemukan')),
      );
    }

    int pricePerHour = int.parse(selectedLapang['price']);

    if (isMember) {
      pricePerHour = (pricePerHour * 0.4).round(); // Diskon 60%
    }

    // Update total price when building
    _updateTotalPrice();

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
              // Informasi Booking
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.lapangan,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tanggal: ${DateFormat('EEEE, dd MMMM yyyy').format(widget.selectedDate)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Jam: ${widget.selectedTime}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        isMember
                            ? "Harga (Diskon 60%): Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(pricePerHour)} / jam"
                            : "Harga: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(pricePerHour)} / jam",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Form Nama Tim/Atas Nama
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Nama Tim / Atas Nama:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: "Masukkan nama tim atau nama pemesan",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Nama tim/nama pemesan wajib diisi!";
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          teamName = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Durasi Booking
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pilih Durasi Booking (jam):",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: List.generate(5, (index) {
                      final duration = index + 1;
                      final int currentStartHour =
                          int.parse(widget.selectedTime.split(":")[0]);
                      final int maxAllowedDuration = 22 - currentStartHour;
                      final bool isWithinClosingTime =
                          duration <= maxAllowedDuration;

                      bool isDurationAvailable = true;
                      for (int i = 0; i < duration; i++) {
                        if (unavailableTimes
                            .contains("${currentStartHour + i}:00")) {
                          isDurationAvailable = false;
                          break;
                        }
                      }

                      return ChoiceChip(
                        label: Text("$duration Jam"),
                        selected: bookingDuration == duration,
                        onSelected: isWithinClosingTime && isDurationAvailable
                            ? (bool selected) {
                                setState(() {
                                  bookingDuration = duration;
                                  _updateTotalPrice();
                                });
                              }
                            : null,
                        selectedColor: Colors.grey.shade300,
                        backgroundColor: Colors.grey.shade100,
                        labelStyle: TextStyle(
                          color: bookingDuration == duration
                              ? Colors.black
                              : Colors.black,
                        ),
                      );
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Tampilkan layanan tambahan hanya jika bukan lapang Gokart
              if (widget.lapangan != "Gokart")
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tambahan Layanan:",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _buildServiceOption(
                      icon: Icons.camera_alt,
                      title: "Photographer",
                      price: "Rp 200,000",
                      value: usePhotographer,
                      onChanged: (bool? value) {
                        setState(() {
                          usePhotographer = value ?? false;
                          _updateTotalPrice();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildServiceOption(
                      icon: Icons.sports,
                      title: "Wasit",
                      price: "Rp 70,000",
                      value: useReferee,
                      onChanged: (bool? value) {
                        setState(() {
                          useReferee = value ?? false;
                          _updateTotalPrice();
                        });
                      },
                    ),
                  ],
                ),

              const SizedBox(height: 30),

              // Total Harga
              Card(
                color: Colors.grey[200],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Harga:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(totalPrice)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Tombol Booking
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.black,
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _confirmBooking();
                    }
                  },
                  child: const Text(
                    "Konfirmasi Booking",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceOption({
    required IconData icon,
    required String title,
    required String price,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return GestureDetector(
      onTap: () {
        onChanged(!value);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: value ? Colors.black : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value ? Colors.black : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: value ? Colors.white : Colors.black),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: value ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 14,
                    color: value ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              value ? Icons.check_circle : Icons.radio_button_unchecked,
              color: value ? Colors.white : Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}
