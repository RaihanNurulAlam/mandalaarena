// ignore_for_file: unused_local_variable, avoid_print, deprecated_member_use, use_build_context_synchronously, use_super_parameters, prefer_final_fields

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/pages/cart_page.dart';
import 'package:mandalaarenaapp/pages/models/lapang.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailPage extends StatefulWidget {
  final Lapang lapang;

  const DetailPage({
    super.key,
    required this.lapang,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int totalPrice = 0;
  String selectedHour = "";
  int bookingDuration = 0;
  DateTime? selectedDate;
  bool isLoved = false;
  List<String> unavailableTimes = [];
  String? userName;
  String? userPhone;
  User? user;
  bool isMember = false;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    SharedPreferences.getInstance().then((prefs) {
      print("SharedPreferences initialized"); // Debug log
      _loadLovedState();
    }).catchError((error) {
      print("Error initializing SharedPreferences: $error");
    });
    _fetchUnavailableTimes();
    user = FirebaseAuth.instance.currentUser; // Get current user in initState

    // Ambil status member dari UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    isMember = userProvider.isMember;
  }

  Future<void> _loadLovedState() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'isLoved_${widget.lapang.id}';
    print("Loading love state for key: $key"); // Debug log
    setState(() {
      isLoved = prefs.getBool(key) ?? false;
    });
  }

  Future<void> clearSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("SharedPreferences cleared"); // Debug log
  }

  Future<void> _saveLovedState() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'isLoved_${widget.lapang.id}';
    print("Saving love state for key: $key, value: $isLoved"); // Debug log
    await prefs.setBool(key, isLoved);
  }

  Future<void> _fetchUnavailableTimes() async {
    if (selectedDate != null) {
      final formattedDate =
          selectedDate!.toIso8601String().split('T')[0]; // "yyyy-MM-dd"
      final bookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('lapangId', isEqualTo: widget.lapang.id)
          .where('tanggal', isEqualTo: formattedDate)
          .get();

      List<String> times = [];
      for (var doc in bookings.docs) {
        // Konversi field 'duration' ke integer (jika disimpan sebagai string)
        final duration = int.tryParse(doc['duration'].toString()) ?? 1;
        // Ambil jam mulai (misal "16:00" -> 16)
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

  Future<void> addToCart() async {
    if (selectedHour.isNotEmpty &&
        bookingDuration > 0 &&
        selectedDate != null &&
        user != null) {
      // Tambahkan pemeriksaan batas tutup lapangan (misal tutup pukul 22:00)
      final int currentStartHour = int.parse(selectedHour.split(":")[0]);
      final int maxAllowedDuration =
          22 - currentStartHour; // jam tersisa hingga 22:00
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

      final cart = context.read<Cart>();
      final userId = user?.uid ?? ""; // Pastikan userId tidak null
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      final selectedTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        currentStartHour,
      );

      // Cek ketersediaan slot di Firestore untuk seluruh durasi
      bool isAvailable = true;
      for (int i = 0; i < bookingDuration; i++) {
        final timeToCheck = selectedTime.add(Duration(hours: i));
        final timeToCheckFormatted = DateFormat('HH:mm').format(timeToCheck);

        final bookingSnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('lapangId', isEqualTo: widget.lapang.id)
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
          const SnackBar(content: Text("Tidak bisa booking di jam tersebut!")),
        );
        return;
      }

      // Cek apakah booking sudah ada di Cart (local)
      bool existsInCart = cart.cart.any((element) =>
          element.id == widget.lapang.id &&
          element.bookingDate == formattedDate &&
          element.time == selectedHour &&
          element.duration == bookingDuration);

      if (existsInCart) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Booking dengan slot tersebut sudah ada di cart!")),
        );
        return;
      }

      try {
        // Ambil data user dari Firestore
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

        final bookingData = {
          'lapangan': widget.lapang.name,
          'tanggal': formattedDate,
          'jamMulai': selectedHour,
          'jamSelesai': DateFormat('HH:mm').format(
            selectedTime.add(Duration(hours: bookingDuration)),
          ),
          'statusBooking': 'Pending',
          'lapangId': widget.lapang.id,
          'userId': user!.uid,
          'namaPengguna': userName,
          'noWhatsapp': userPhone ?? "",
          'duration': bookingDuration.toString(), // disimpan sebagai string
        };

        // Tambahkan booking ke Firestore dan ambil docId-nya
        final docRef = await FirebaseFirestore.instance
            .collection('bookings')
            .add(bookingData);

        // Tambahkan ke cart (local) dengan menyertakan docId
        cart.addToCart(
          userId, // Ambil userId dengan aman
          docRef.id, // ID dari Firestore
          widget.lapang, // Objek Lapang sesuai dengan cart.dart
          bookingDuration, // Durasi booking (int)
          formattedDate, // Tanggal booking (String)
          selectedHour, // Jam mulai booking (String)
          totalPrice, // Total harga (num)
        );

        // Setelah booking berhasil, perbarui daftar unavailableTimes
        await _fetchUnavailableTimes();

        popUpDialog(); // Tampilkan dialog sukses atau aksi selanjutnya
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e")),
        );
      }
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
                '${widget.lapang.name} pada tanggal $formattedDate jam $selectedHour dengan durasi $bookingDuration jam telah ditambahkan ke keranjang.',
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

  DateTime _currentStartOfWeek =
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

  Future<void> _showDatePicker() async {
    // Batasi pemilihan tanggal hanya untuk minggu ini
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(), // Tidak bisa memilih tanggal sebelum hari ini
      lastDate: DateTime(2100), // Dibuka seterusnya
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
      _fetchUnavailableTimes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    isMember = userProvider.isMember;

    // Hitung harga dengan diskon jika member
    int pricePerHour = int.parse(widget.lapang.price.toString());
    if (isMember) {
      pricePerHour = (pricePerHour * 0.4).round(); // Diskon 60%
    }

    // Hitung totalPrice berdasarkan durasi booking
    if (bookingDuration > 0) {
      totalPrice = bookingDuration * pricePerHour;
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
              isLoved ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              color: isLoved ? Colors.red : Colors.white,
            ),
            onPressed: () {
              setState(() {
                isLoved = !isLoved;
                print("isLoved toggled to: $isLoved"); // Debug log
              });
              _saveLovedState();
            },
          ),
          Consumer<Cart>(
            builder: (context, value, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Stack(
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
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Visibility(
                        visible: value.cart.isNotEmpty,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.yellow,
                          child: Center(
                            child: Text(
                              value.cart.length.toString(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100.0),
          child: lapangDetailWidget(context),
        ),
      ),
      bottomNavigationBar: (selectedHour.isNotEmpty &&
              bookingDuration > 0 &&
              selectedDate != null)
          ? GestureDetector(
              onTap: () {
                addToCart();
              },
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
                    const Text(
                      'Bayar Sekarang',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Total: Rp. $totalPrice',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget lapangDetailWidget(BuildContext context) {
    final currentTime = DateTime.now();
    final userProvider = Provider.of<UserProvider>(context);
    isMember = userProvider.isMember; // Perbarui status member

    // Hitung harga dengan diskon jika member
    int pricePerHour = int.parse(widget.lapang.price.toString());
    if (isMember) {
      pricePerHour = (pricePerHour * 0.4).round(); // Diskon 60%
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Hero(
          tag: widget.lapang.imagePath.toString(),
          child: Container(
            height: 300,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(widget.lapang.imagePath.toString()),
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
          padding:
              const EdgeInsets.only(left: 30, right: 30, top: 10, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.lapang.name.toString(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.yellow),
                  Text(
                    widget.lapang.rating.toString(),
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMember
                    ? "Harga (Diskon 60%): Rp $pricePerHour / jam"
                    : "Harga: Rp ${widget.lapang.price} / jam",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Deskripsi:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.lapang.description.toString(),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Fasilitas:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: widget.lapang.facilities?.map((facility) {
                      IconData iconData;
                      switch (facility) {
                        case 'WiFi':
                          iconData = Icons.wifi;
                          break;
                        case 'Parkir':
                          iconData = Icons.local_parking;
                          break;
                        case 'Kantin':
                          iconData = Icons.restaurant;
                          break;
                        case 'Toilet':
                          iconData = Icons.wc;
                          break;
                        default:
                          iconData = Icons.check;
                      }
                      return Chip(
                        avatar: Icon(iconData, color: Colors.white),
                        label: Text(facility),
                        backgroundColor: Colors.black,
                        labelStyle: const TextStyle(color: Colors.white),
                      );
                    }).toList() ??
                    [],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Row(
            children: [
              Text(
                "Pilih Tanggal Booking:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: WeeklyCalendar(
            currentStartOfWeek: _currentStartOfWeek,
            onDateSelected: (date) {
              setState(() {
                selectedDate = date;
              });
              _fetchUnavailableTimes();
            },
            selectedDate: selectedDate,
            onCalendarIconPressed: _showDatePicker,
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.0),
          child: Text(
            "Pilih Jam Booking:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: List.generate(
              14,
              (index) {
                final hour = 8 + index;
                final bookingTime = DateTime(
                  selectedDate?.year ?? DateTime.now().year,
                  selectedDate?.month ?? DateTime.now().month,
                  selectedDate?.day ?? DateTime.now().day,
                  hour,
                );
                bool isPast = bookingTime.isBefore(DateTime.now());
                final isUnavailable = unavailableTimes.contains("$hour:00");

                // Jika sudah memilih jam dan durasi, tampilkan slot dalam rentang booking dengan warna berbeda.
                int? selectedStartHour;
                if (selectedHour.isNotEmpty) {
                  selectedStartHour = int.parse(selectedHour.split(":")[0]);
                }
                // Kondisi untuk jam dalam rentang booking (selain slot start)
                bool isInBookedRange = false;
                if (selectedStartHour != null && bookingDuration > 0) {
                  // Slot start adalah selectedHour, sementara slot setelahnya (misalnya 17:00, 18:00, dst)
                  if (hour > selectedStartHour &&
                      hour < selectedStartHour + bookingDuration) {
                    isInBookedRange = true;
                  }
                }

                return ChoiceChip(
                  label: Text("$hour:00"),
                  selected: selectedHour == "$hour:00",
                  onSelected: isPast || isUnavailable
                      ? null
                      : (bool selected) {
                          setState(() {
                            selectedHour = "$hour:00";
                          });
                        },
                  backgroundColor: isPast || isUnavailable
                      ? Colors.grey.shade300
                      : isInBookedRange
                          ? Colors.grey
                              .shade300 // warna untuk slot yang berada dalam rentang booking
                          : Colors.grey.shade100,
                  labelStyle: TextStyle(
                    color: selectedHour == "$hour:00"
                        ? Colors.black
                        : Colors.black,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: const Text(
            "Pilih Durasi Booking (jam):",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: List.generate(
              5,
              (index) {
                final duration = index + 1;
                // Jika selectedHour sudah dipilih, hitung jam mulai dan batas durasi maksimal (22:00)
                final int currentStartHour = selectedHour.isNotEmpty
                    ? int.parse(selectedHour.split(":")[0])
                    : 0;
                final int maxAllowedDuration = selectedHour.isNotEmpty
                    ? (22 - currentStartHour)
                    : 5; // jika belum pilih jam, biarkan semua pilihan tampil

                // Periksa apakah durasi ini melebihi batas tutup lapangan
                final bool isWithinClosingTime = duration <= maxAllowedDuration;

                // Selain itu, cek juga apakah dalam rentang waktu tersebut ada slot yang sudah unavailable
                bool isDurationAvailable = true;
                if (selectedHour.isNotEmpty) {
                  for (int i = 0; i < duration; i++) {
                    if (unavailableTimes
                        .contains("${currentStartHour + i}:00")) {
                      isDurationAvailable = false;
                      break;
                    }
                  }
                }

                return ChoiceChip(
                  label: Text("$duration Jam"),
                  selected: bookingDuration == duration,
                  onSelected: (isWithinClosingTime && isDurationAvailable)
                      ? (bool selected) {
                          setState(() {
                            bookingDuration = duration;
                            totalPrice = bookingDuration *
                                int.parse(widget.lapang.price.toString());
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
              },
            ),
          ),
        ),
      ],
    );
  }
}

class WeeklyCalendar extends StatelessWidget {
  final DateTime currentStartOfWeek;
  final Function(DateTime) onDateSelected;
  final DateTime? selectedDate;
  final VoidCallback onCalendarIconPressed;

  const WeeklyCalendar({
    Key? key,
    required this.currentStartOfWeek,
    required this.onDateSelected,
    this.selectedDate,
    required this.onCalendarIconPressed,
  }) : super(key: key);

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

                      return GestureDetector(
                        onTap: isPast ? null : () => onDateSelected(date),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.black
                                : isPast
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
