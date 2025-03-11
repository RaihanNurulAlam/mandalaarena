// ignore_for_file: avoid_print, deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/pages/cart_page.dart';
import 'package:mandalaarenaapp/pages/models/sparring_team_model.dart';
import 'package:mandalaarenaapp/pages/models/lapang.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SparringBookingPage extends StatefulWidget {
  final SparringTeam team;
  final String lapangCategory;

  const SparringBookingPage({
    super.key,
    required this.team,
    required this.lapangCategory,
  });

  @override
  _SparringBookingPageState createState() => _SparringBookingPageState();
}

class _SparringBookingPageState extends State<SparringBookingPage> {
  Lapang? selectedLapang;
  int totalPrice = 0;
  String selectedHour = "";
  int bookingDuration = 1; // Default durasi 1 jam
  DateTime? selectedDate;
  List<String> unavailableTimes = [];
  bool isLoved = false;
  final DateTime _currentStartOfWeek =
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _fetchLapangData();
    _fetchUnavailableTimes();
    _setInitialBookingTime();
    _loadLovedState();
  }

  Future<void> _fetchLapangData() async {
    try {
      // Ambil data lapang dari lapang.json
      final List<Lapang> lapangList = await Lapang.getLapangFromJson(context);

      // Cari lapang berdasarkan kategori yang dipilih
      final lapang = lapangList.firstWhere(
        (lapang) => lapang.name == widget.lapangCategory,
        orElse: () => Lapang(), // Return Lapang kosong jika tidak ditemukan
      );

      if (lapang.name != null) {
        setState(() {
          selectedLapang = lapang;
          totalPrice = int.parse(selectedLapang!.price!) * bookingDuration;
        });
      } else {
        // Jika lapang tidak ditemukan, tampilkan pesan error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lapang tidak ditemukan!')),
        );
        Navigator.pop(context); // Kembali ke halaman sebelumnya
      }
    } catch (e) {
      // Tangani error jika terjadi kesalahan
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data lapang: $e')),
      );
      Navigator.pop(context); // Kembali ke halaman sebelumnya
    }
  }

  Future<void> _fetchUnavailableTimes() async {
    if (selectedDate != null) {
      final formattedDate = selectedDate!.toIso8601String().split('T')[0];
      final bookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('lapangId', isEqualTo: selectedLapang?.id)
          .where('tanggal', isEqualTo: formattedDate)
          .get();

      List<String> times = [];
      for (var doc in bookings.docs) {
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
  }

  void _setInitialBookingTime() {
    final now = DateTime.now();
    final availableDays = widget.team.availableDays;
    final availableHours = widget.team.availableHours;

    // Cari hari terdekat yang tersedia
    DateTime? nearestDate;
    for (var day in availableDays) {
      final dayIndex = _getDayIndex(day);
      final date = _currentStartOfWeek.add(Duration(days: dayIndex));
      if (date.isAfter(now)) {
        nearestDate = date;
        break;
      }
    }

    // Jika tidak ada hari tersedia, pilih hari pertama di minggu depan
    nearestDate ??= _currentStartOfWeek
        .add(Duration(days: 7 + _getDayIndex(availableDays.first)));

    // Set tanggal dan jam booking
    setState(() {
      selectedDate = nearestDate;
      selectedHour = availableHours.isNotEmpty ? availableHours.first : "";
    });
  }

  int _getDayIndex(String day) {
    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    return days.indexOf(day);
  }

  Future<void> _showDatePicker() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
      _fetchUnavailableTimes();
    }
  }

  Future<void> _loadLovedState() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'isLoved_${selectedLapang?.id}';
    print("Loading love state for key: $key");
    setState(() {
      isLoved = prefs.getBool(key) ?? false;
    });
  }

  Future<void> _saveLovedState() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'isLoved_${selectedLapang?.id}';
    print("Saving love state for key: $key, value: $isLoved");
    await prefs.setBool(key, isLoved);
  }

  Future<void> addToCart() async {
    if (selectedHour.isNotEmpty &&
        bookingDuration > 0 &&
        selectedDate != null) {
      final cart = context.read<Cart>();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anda harus login terlebih dahulu!')),
        );
        return;
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      final startHour = int.parse(selectedHour.split(":")[0]);
      final selectedTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        startHour,
      );

      // Cek ketersediaan slot di Firestore untuk seluruh durasi
      bool isAvailable = true;
      for (int i = 0; i < bookingDuration; i++) {
        final timeToCheck = selectedTime.add(Duration(hours: i));
        final timeToCheckFormatted = DateFormat('HH:mm').format(timeToCheck);

        final bookingSnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('lapangId', isEqualTo: selectedLapang?.id)
            .where('tanggal', isEqualTo: formattedDate)
            .where('jamMulai', isEqualTo: timeToCheckFormatted)
            .get();

        if (bookingSnapshot.docs.isNotEmpty) {
          isAvailable = false;
          break;
        }
      }

      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak bisa booking di jam tersebut!')),
        );
        return;
      }

      // Simpan booking ke Firestore
      final bookingData = {
        'lapangan': selectedLapang!.name,
        'tanggal': formattedDate,
        'jamMulai': selectedHour,
        'jamSelesai': DateFormat('HH:mm').format(
          selectedTime.add(Duration(hours: bookingDuration)),
        ),
        'statusBooking': 'Pending',
        'lapangId': selectedLapang!.id,
        'userId': user.uid,
        'namaPengguna': user.displayName ?? "",
        'noWhatsapp': user.phoneNumber ?? "",
        'duration': bookingDuration.toString(),
      };

      final docRef = await FirebaseFirestore.instance
          .collection('bookings')
          .add(bookingData);

      // Tambahkan ke cart (local)
      cart.addToCart(
        user.uid,
        docRef.id,
        selectedLapang!,
        bookingDuration,
        formattedDate,
        selectedHour,
        totalPrice,
      );

      // Tampilkan popup sukses
      popUpDialog();
    }
  }

  void popUpDialog() {
    final formattedDate = DateFormat('dd MMMM yyyy').format(selectedDate!);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      showDragHandle: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking lapang telah dimasukkan ke keranjang',
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${selectedLapang!.name} pada tanggal $formattedDate jam $selectedHour dengan durasi $bookingDuration jam telah ditambahkan ke keranjang.',
                style: const TextStyle(
                  fontSize: 18.0,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: FloatingActionButton(
                      heroTag: 'goToCart',
                      backgroundColor: const Color.fromARGB(109, 140, 94, 91),
                      elevation: 0,
                      onPressed: () {
                        Navigator.pop(context);
                        goToCart();
                      },
                      child: const Text(
                        'Lihat Keranjang',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FloatingActionButton(
                      heroTag: 'pop',
                      backgroundColor: Colors.black,
                      elevation: 0,
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Selesai',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CartPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (selectedLapang == null || selectedLapang!.name == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Booking Lapang'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isLoved ? Icons.favorite : Icons.favorite_border,
              color: isLoved ? Colors.red : Colors.white,
            ),
            onPressed: () {
              setState(() {
                isLoved = !isLoved;
              });
              _saveLovedState();
            },
          ),
          Consumer<Cart>(
            builder: (context, cart, child) {
              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      goToCart();
                    },
                    icon: const Icon(
                      CupertinoIcons.bag,
                      size: 30,
                    ),
                  ),
                  if (cart.cart.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.yellow,
                        child: Center(
                          child: Text(
                            cart.cart.length.toString(),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: selectedLapang!.imagePath.toString(),
                child: Container(
                  height: 300,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(selectedLapang!.imagePath.toString()),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.2),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedLapang!.name.toString(),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.yellow),
                            SizedBox(width: 4),
                            Text(
                              selectedLapang!.rating.toString(),
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Harga: Rp ${selectedLapang!.price}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Deskripsi:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      selectedLapang!.description.toString(),
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Fasilitas:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: selectedLapang!.facilities?.map((facility) {
                            return Chip(
                              label: Text(facility),
                              backgroundColor: Colors.black,
                              labelStyle: TextStyle(color: Colors.white),
                            );
                          }).toList() ??
                          [],
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Pilih Tanggal Booking:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    WeeklyCalendar(
                      currentStartOfWeek: _currentStartOfWeek,
                      onDateSelected: (date) {
                        setState(() {
                          selectedDate = date;
                        });
                        _fetchUnavailableTimes();
                      },
                      selectedDate: selectedDate,
                      onCalendarIconPressed: _showDatePicker,
                      availableDays: widget.team.availableDays,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Pilih Jam Booking:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: List.generate(14, (index) {
                        final hour = 8 + index;
                        final bookingTime = DateTime(
                          selectedDate?.year ?? DateTime.now().year,
                          selectedDate?.month ?? DateTime.now().month,
                          selectedDate?.day ?? DateTime.now().day,
                          hour,
                        );
                        bool isPast = bookingTime.isBefore(DateTime.now());
                        final isUnavailable =
                            unavailableTimes.contains("$hour:00");
                        final isOverOperationalTime = hour >= 22;

                        return ChoiceChip(
                          label: Text("$hour:00"),
                          selected: selectedHour == "$hour:00",
                          onSelected: isPast ||
                                  isUnavailable ||
                                  isOverOperationalTime
                              ? null
                              : (bool selected) {
                                  setState(() {
                                    selectedHour = "$hour:00";
                                    if (hour == 22) {
                                      bookingDuration = 1;
                                      totalPrice =
                                          int.parse(selectedLapang!.price!) *
                                              bookingDuration;
                                    }
                                  });
                                },
                          backgroundColor:
                              isPast || isUnavailable || isOverOperationalTime
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade100,
                          labelStyle: TextStyle(
                            color: selectedHour == "$hour:00"
                                ? Colors.black
                                : Colors.black,
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Pilih Durasi Booking (jam):",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: List.generate(5, (index) {
                        final duration = index + 1;
                        final int currentStartHour = selectedHour.isNotEmpty
                            ? int.parse(selectedHour.split(":")[0])
                            : 0;
                        final int maxAllowedDuration = selectedHour.isNotEmpty
                            ? (22 - currentStartHour)
                            : 5;

                        final bool isWithinClosingTime =
                            duration <= maxAllowedDuration;

                        return ChoiceChip(
                          label: Text("$duration Jam"),
                          selected: bookingDuration == duration,
                          onSelected: isWithinClosingTime
                              ? (bool selected) {
                                  setState(() {
                                    bookingDuration = duration;
                                    totalPrice =
                                        int.parse(selectedLapang!.price!) *
                                            bookingDuration;
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
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: (selectedHour.isNotEmpty &&
              bookingDuration > 0 &&
              selectedDate != null)
          ? GestureDetector(
              onTap: addToCart,
              child: Container(
                margin: const EdgeInsets.all(8.0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.black,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Bayar Sekarang',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Total: Rp. $totalPrice',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SizedBox.shrink(),
    );
  }
}

class WeeklyCalendar extends StatelessWidget {
  final DateTime currentStartOfWeek;
  final Function(DateTime) onDateSelected;
  final DateTime? selectedDate;
  final VoidCallback onCalendarIconPressed;
  final List<String> availableDays;

  const WeeklyCalendar({
    super.key,
    required this.currentStartOfWeek,
    required this.onDateSelected,
    this.selectedDate,
    required this.onCalendarIconPressed,
    required this.availableDays,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isIconOnTop = constraints.maxWidth < 300;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isIconOnTop)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.calendar_today, size: 24),
                  onPressed: onCalendarIconPressed,
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: List.generate(7, (index) {
                      final date =
                          currentStartOfWeek.add(Duration(days: index));
                      final isPast = date
                          .isBefore(DateTime.now().subtract(Duration(days: 1)));
                      final isSelected = selectedDate != null &&
                          date.year == selectedDate!.year &&
                          date.month == selectedDate!.month &&
                          date.day == selectedDate!.day;
                      final isAvailable = availableDays.contains(
                          DateFormat('EEEE').format(date).substring(0, 3));

                      return GestureDetector(
                        onTap: isPast || !isAvailable
                            ? null
                            : () => onDateSelected(date),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.black
                                : isPast || !isAvailable
                                    ? Colors.grey.shade300
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? null
                                : Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              Text(
                                DateFormat('E').format(date),
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                DateFormat('d').format(date),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                if (!isIconOnTop)
                  IconButton(
                    icon: Icon(Icons.calendar_today, size: 24),
                    onPressed: onCalendarIconPressed,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
