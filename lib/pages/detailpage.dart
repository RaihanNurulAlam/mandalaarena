// ignore_for_file: unused_local_variable, avoid_print, deprecated_member_use, use_build_context_synchronously, use_super_parameters, prefer_final_fields

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/Login%20Signup/Screen/login.dart';
import 'package:mandalaarenaapp/pages/booking_summary_page.dart';
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
  int photographerPrice = 200000;
  int refereePrice = 70000;
  int iceBathPrice = 50000;
  String selectedHour = "";
  int bookingDuration = 0;
  DateTime? selectedDate;
  bool isLoved = false;
  List<String> unavailableTimes = [];
  String? userName;
  String? userPhone;
  User? user;
  bool isMember = false;
  bool usePhotographer = false;
  bool useReferee = false;
  bool useIceBath = false;
  String teamName = "";
  final _formKey = GlobalKey<FormState>();
  bool isFormValid = false;
  Map<String, int> bookedSlots = {};

  // --- [PERUBAHAN 1] Fungsi untuk menampilkan dialog jika ada booking ---
  void _showExistingBookingDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Booking Sedang Berlangsung'),
        content: const Text(
            'Anda memiliki booking yang belum diselesaikan. Mohon selesaikan pembayaran atau hapus booking sebelumnya.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BookingSummaryPage()),
              );
            },
            child: const Text('Lihat Booking'),
          ),
        ],
      ),
    );
  }

  // --- [PERUBAHAN 2] Fungsi terpusat untuk menangani aksi booking ---
  void _handleBookingAction() {
    final cart = context.read<Cart>();
    final user = FirebaseAuth.instance.currentUser;

    // Cek jika ada item di keranjang
    if (cart.cart.isNotEmpty) {
      _showExistingBookingDialog();
      return;
    }

    // Jika keranjang kosong, lanjutkan dengan logika booking
    if (user == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Diperlukan'),
          content:
              const Text('Harap login terlebih dahulu untuk booking jadwal'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()));
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
    } else {
      addToCart();
    }
  }

  int _getPriceForHour(int hour) {
    int basePrice = int.tryParse(widget.lapang.price ?? '0') ?? 0;
    String lapangName = widget.lapang.name.toString();

    if (lapangName == "Lapang Minisoccer") {
      if (hour >= 7 && hour < 14) return basePrice;
      if (hour >= 14 && hour < 18) return basePrice + 100000;
      if (hour >= 18 && hour < 23) return basePrice + 200000;
    } else if (lapangName == "Lapang Basket Vynil") {
      if (hour >= 7 && hour < 14) return basePrice;
      if (hour >= 14 && hour < 18) return basePrice + 50000;
      if (hour >= 18 && hour < 23) return basePrice + 100000;
    } else if (lapangName == "Lapang Basket Karet") {
      if (hour >= 7 && hour < 14) return basePrice;
      if (hour >= 14 && hour < 18) return basePrice + 25000;
      if (hour >= 18 && hour < 23) return basePrice + 50000;
    }
    return basePrice;
  }

  String _getPriceRangeString() {
    int pagiPrice = _getPriceForHour(8);
    int malamPrice = _getPriceForHour(19);

    final formatCurrency =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    if (pagiPrice == malamPrice) {
      return "${formatCurrency.format(pagiPrice)} / jam";
    } else {
      return "${formatCurrency.format(pagiPrice)} - ${formatCurrency.format(malamPrice)} / jam";
    }
  }

  void _updateTotalPrice() {
    totalPrice = 0;

    if (selectedHour.isNotEmpty && bookingDuration > 0) {
      final int startHour = int.parse(selectedHour.split(":")[0]);
      int hoursCounted = 0;
      double cumulativePrice = 0;

      for (int i = 0; hoursCounted < bookingDuration; i++) {
        final int currentHour = startHour + i;

        if (currentHour >= 23) {
          break;
        }

        double priceForThisHour = _getPriceForHour(currentHour).toDouble();

        if (isMember) {
          priceForThisHour *= 0.9;
        }

        cumulativePrice += priceForThisHour;
        hoursCounted++;
      }

      totalPrice = cumulativePrice.round();

      if (usePhotographer) {
        totalPrice += photographerPrice;
      }
      if (useReferee) {
        totalPrice += refereePrice;
      }
      if (useIceBath && isMember && widget.lapang.name == "Lapang Minisoccer") {
        totalPrice += iceBathPrice;
      }
    }
    setState(() {});
  }

  bool isDurationAvailable(int startHour, int duration) {
    int hoursCounted = 0;

    for (int i = 0; hoursCounted < duration; i++) {
      final int currentHour = startHour + i;
      if (currentHour >= 23) {
        return false;
      }
      if (unavailableTimes.contains("$currentHour:00")) {
        return false;
      }
      hoursCounted++;
    }
    return true;
  }

  bool isTimeSlotAvailable(int hour) {
    if (hour < 7 || hour >= 23) {
      return false;
    }
    return !unavailableTimes.contains("$hour:00");
  }

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _loadLovedState();
    _fetchUnavailableTimes();
    user = FirebaseAuth.instance.currentUser;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    isMember = userProvider.isMember;
  }

  Future<void> _loadLovedState() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'isLoved_${widget.lapang.id}';
    if (mounted) {
      setState(() {
        isLoved = prefs.getBool(key) ?? false;
      });
    }
  }

  Future<void> _saveLovedState() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'isLoved_${widget.lapang.id}';
    await prefs.setBool(key, isLoved);
  }

  Future<void> _fetchUnavailableTimes() async {
    if (selectedDate != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);

      try {
        final bookings = await FirebaseFirestore.instance
            .collection('bookings')
            .where('items', isNotEqualTo: null)
            .get();

        List<String> times = [];
        for (var doc in bookings.docs) {
          final data = doc.data();
          final items = data['items'] as List<dynamic>?;

          if (items != null) {
            for (var item in items) {
              final bookingDate = item['bookingDate'] as String?;
              final time = item['time'] as String?;
              final lapangName = item['name'] as String?;
              final quantity = int.tryParse(item['quantity'] ?? '1') ?? 1;

              if (bookingDate == formattedDate &&
                  time != null &&
                  lapangName == widget.lapang.name) {
                final startHour = int.parse(time.split(":")[0]);
                for (int i = 0; i < quantity; i++) {
                  times.add("${startHour + i}:00");
                }
              }
            }
          }
        }

        if (mounted) {
          setState(() {
            unavailableTimes = times;
          });
        }
      } catch (e) {
        print("Error fetching unavailable times: $e");
      }
    }
  }

  Future<void> addToCart() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap isi nama tim/nama pemesan terlebih dahulu!"),
        ),
      );
      return;
    }

    if (selectedHour.isNotEmpty &&
        bookingDuration > 0 &&
        selectedDate != null &&
        user != null) {
      final cart = context.read<Cart>();
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);

      final bool isAlreadyInCart = cart.cart.any((item) =>
          item.id == widget.lapang.id &&
          item.bookingDate == formattedDate &&
          item.time == selectedHour);

      if (isAlreadyInCart) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Jadwal ini sudah ada di keranjang Anda."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final int currentStartHour = int.parse(selectedHour.split(":")[0]);
      if (!isDurationAvailable(currentStartHour, bookingDuration)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Slot waktu yang dipilih sudah dibooking atau melebihi jam operasional!",
            ),
          ),
        );
        return;
      }

      try {
        cart.addToCart(
          user!.uid,
          DateTime.now().millisecondsSinceEpoch.toString(),
          widget.lapang,
          bookingDuration,
          DateFormat('yyyy-MM-dd').format(selectedDate!),
          selectedHour,
          totalPrice,
          usePhotographer,
          useReferee,
          teamName,
          useIceBath,
        );

        await _fetchUnavailableTimes();
        popUpDialog();
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
      MaterialPageRoute(builder: (context) => BookingSummaryPage()),
    );
  }

  DateTime _currentStartOfWeek =
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    isMember = userProvider.isMember;

    // --- [PERUBAHAN 3] Tambahkan ini untuk memantau keranjang ---
    final cart = context.watch<Cart>();

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
      // --- [PERUBAHAN 3] Gunakan _handleBookingAction dan perbarui kondisi ---
      bottomNavigationBar: (selectedHour.isNotEmpty &&
              bookingDuration > 0 &&
              selectedDate != null &&
              cart.cart.isEmpty) // Hanya tampil jika keranjang kosong
          ? GestureDetector(
              onTap: _handleBookingAction,
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
                      'Total: Rp. ${NumberFormat.currency(locale: 'id', symbol: '').format(totalPrice)}',
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
    final userProvider = Provider.of<UserProvider>(context);
    final cart = context.watch<Cart>();
    isMember = userProvider.isMember;

    int pricePerHour = int.parse(widget.lapang.price.toString());
    if (isMember) {
      pricePerHour = (pricePerHour * 0.6).round();
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
              const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 5),
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
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getPriceRangeString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (isMember)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "Harga di atas belum termasuk diskon member 10%",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
        Stack(
          children: [
            // Konten asli untuk booking
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Form(
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
                              isFormValid = _formKey.currentState!.validate();
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Pilih Tanggal Booking:",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      AbsorbPointer(
                        absorbing: !isFormValid,
                        child: Opacity(
                          opacity: isFormValid ? 1.0 : 0.5,
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Pilih Jam Booking:",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      AbsorbPointer(
                        absorbing: !isFormValid || selectedDate == null,
                        child: Opacity(
                          opacity:
                              isFormValid && selectedDate != null ? 1.0 : 0.5,
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            // --- PERUBAHAN 1 ---
                            // Jam operasional dari 7:00 hingga 22:00 -> 15 slot
                            children: List.generate(
                              15,
                              (index) {
                                // Memulai dari jam 7 pagi
                                final hour = 7 + index;
                                final bookingTime = DateTime(
                                  selectedDate?.year ?? DateTime.now().year,
                                  selectedDate?.month ?? DateTime.now().month,
                                  selectedDate?.day ?? DateTime.now().day,
                                  hour,
                                );
                                bool isPast =
                                    bookingTime.isBefore(DateTime.now());
                                final isBooked =
                                    unavailableTimes.contains("$hour:00");

                                final int startHour = selectedHour.isNotEmpty
                                    ? int.parse(selectedHour.split(":")[0])
                                    : -1;

                                // --- PERUBAHAN 2 ---
                                // Menyederhanakan logika karena jam 18:00 sekarang aktif
                                final bool isWithinSelectedDuration =
                                    selectedHour.isNotEmpty &&
                                        hour >= startHour &&
                                        hour < startHour + bookingDuration;

                                // --- PERUBAHAN 3 ---
                                // Jam tidak tersedia adalah jam 22:00 (10 malam) ke atas
                                final bool isUnavailable = hour >= 22;

                                return ChoiceChip(
                                  label: Text("$hour:00"),
                                  selected: isWithinSelectedDuration,
                                  onSelected:
                                      (isPast || isBooked || isUnavailable)
                                          ? null
                                          : (bool selected) {
                                              setState(() {
                                                selectedHour = "$hour:00";
                                                bookingDuration = 1;
                                                _updateTotalPrice();
                                              });
                                            },
                                  backgroundColor: isPast || isUnavailable
                                      ? Colors.grey.shade300
                                      : isBooked
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade100,
                                  selectedColor: Colors.black,
                                  labelStyle: TextStyle(
                                    color: isWithinSelectedDuration
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  checkmarkColor: Colors.white,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Pilih Durasi Booking (jam):",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      AbsorbPointer(
                        absorbing: !isFormValid ||
                            selectedDate == null ||
                            selectedHour.isEmpty,
                        child: Opacity(
                          opacity: isFormValid &&
                                  selectedDate != null &&
                                  selectedHour.isNotEmpty
                              ? 1.0
                              : 0.5,
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: List.generate(
                              5,
                              (index) {
                                final duration = index + 1;
                                final int currentStartHour =
                                    selectedHour.isNotEmpty
                                        ? int.parse(selectedHour.split(":")[0])
                                        : 0;

                                bool isAvailable = isDurationAvailable(
                                    currentStartHour, duration);

                                // --- PERUBAHAN 4 ---
                                bool isSelectionEnabled = isAvailable;
                                // Jika jam mulai adalah 21:00, hanya durasi 1 jam yang diizinkan
                                if (currentStartHour == 21) {
                                  isSelectionEnabled = (duration == 1);
                                }
                                // Batasi agar total durasi tidak melewati jam 23:00 (tutup)
                                if (currentStartHour + duration > 22) {
                                  isSelectionEnabled = false;
                                }

                                return ChoiceChip(
                                  label: Text("$duration Jam"),
                                  selected: bookingDuration == duration,
                                  onSelected: isSelectionEnabled
                                      ? (bool selected) {
                                          setState(() {
                                            bookingDuration = duration;
                                            _updateTotalPrice();
                                          });
                                        }
                                      : null,
                                  backgroundColor: isSelectionEnabled
                                      ? Colors.grey.shade100
                                      : Colors.grey.shade300,
                                  selectedColor: Colors.black,
                                  labelStyle: TextStyle(
                                    color: bookingDuration == duration
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  checkmarkColor: Colors.white,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (widget.lapang.name != "Gokart")
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tambahan Layanan:",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        _buildServiceOption(
                          icon: Icons.camera_alt,
                          title: "Photographer",
                          price: "Rp 200,000",
                          value: usePhotographer,
                          onChanged: (bool value) {
                            setState(() {
                              usePhotographer = value;
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
                          onChanged: (bool value) {
                            setState(() {
                              useReferee = value;
                              _updateTotalPrice();
                            });
                          },
                        ),
                        if (isMember &&
                            widget.lapang.name == "Lapang Minisoccer")
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: _buildServiceOption(
                              icon: Icons.ac_unit,
                              title: "Ice Bath",
                              price: "Rp 50,000",
                              value: useIceBath,
                              onChanged: (bool value) {
                                setState(() {
                                  useIceBath = value;
                                  _updateTotalPrice();
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            Visibility(
              visible: cart.cart.isNotEmpty,
              child: Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.9),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.orange, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Selesaikan Booking Anda Sebelumnya',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Anda tidak dapat membuat booking baru jika masih ada yang belum selesai.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => BookingSummaryPage()),
                              );
                            },
                            child: const Text('Lihat Booking'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        )
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
                  icon: const Icon(Icons.calendar_today, size: 24),
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
                      final isPast = date.isBefore(
                          DateTime.now().subtract(const Duration(days: 1)));
                      final isSelected = selectedDate != null &&
                          date.year == selectedDate!.year &&
                          date.month == selectedDate!.month &&
                          date.day == selectedDate!.day;

                      return GestureDetector(
                        onTap: isPast ? null : () => onDateSelected(date),
                        child: Container(
                          padding: const EdgeInsets.all(12),
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
                                DateFormat('E', 'id_ID').format(date),
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
                    icon: const Icon(Icons.calendar_today, size: 24),
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
