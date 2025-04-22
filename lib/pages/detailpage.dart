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
  int photographerPrice = 200000;
  int refereePrice = 70000;
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
  String teamName = "";
  final _formKey = GlobalKey<FormState>();
  bool isFormValid = false;
  Map<String, int> bookedSlots =
      {}; // Map to store booked hours and their durations

  void _updateTotalPrice() {
    int pricePerHour = int.parse(widget.lapang.price.toString());
    if (isMember) {
      pricePerHour = (pricePerHour * 0.6).round();
    }

    totalPrice = bookingDuration * pricePerHour;

    // Tambahkan biaya photographer jika dipilih dan bukan lapang Gokart
    if (usePhotographer && widget.lapang.name != "Gokart") {
      totalPrice += 200000; // Tambahkan harga photographer
    }

    // Tambahkan biaya wasit jika dipilih dan bukan lapang Gokart
    if (useReferee && widget.lapang.name != "Gokart") {
      totalPrice += 70000; // Tambahkan harga wasit
    }

    setState(() {});
  }

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
    // _fetchBookedSlots();
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
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);

      try {
        // Ambil data booking dari Firestore berdasarkan lapangId, tanggal, dan nama lapangan
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

              // Periksa apakah tanggal, jam, dan nama lapangan cocok
              if (bookingDate == formattedDate &&
                  time != null &&
                  lapangName == widget.lapang.name) {
                final startHour = int.parse(time.split(":")[0]);

                // Tambahkan semua jam yang sudah dibooking ke dalam daftar unavailableTimes
                for (int i = 0; i < quantity; i++) {
                  times.add("${startHour + i}:00");
                }
              }
            }
          }
        }

        setState(() {
          unavailableTimes = times;
        });
      } catch (e) {
        print("Error fetching unavailable times: $e");
      }
    }
  }

  // Future<void> _fetchBookedSlots() async {
  //   if (selectedDate != null) {
  //     final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);

  //     try {
  //       // Ambil data booking dari Firestore berdasarkan lapangId dan tanggal
  //       final bookings = await FirebaseFirestore.instance
  //           .collection('bookings')
  //           .where('lapangId', isEqualTo: widget.lapang.id)
  //           .where('tanggal', isEqualTo: formattedDate)
  //           .get();

  //       bookedSlots.clear();

  //       for (var doc in bookings.docs) {
  //         final startHourStr = doc['jamMulai'].toString().split(':')[0];
  //         final startHour = int.tryParse(startHourStr) ?? 0;
  //         final duration = int.tryParse(doc['duration'].toString()) ?? 1;

  //         for (int i = 0; i < duration; i++) {
  //           final hour = startHour + i;
  //           bookedSlots[hour.toString()] = duration - i;
  //         }
  //       }

  //       setState(() {});
  //     } catch (e) {
  //       print("Error fetching booked slots: $e");
  //     }
  //   }
  // }

  bool isTimeSlotAvailable(int hour) {
    return !unavailableTimes.contains("$hour:00");
  }

  bool isDurationAvailable(int startHour, int duration) {
    for (int i = 0; i < duration; i++) {
      final hour = startHour + i;
      if (unavailableTimes.contains("$hour:00")) {
        return false; // Jika salah satu jam dalam durasi tidak tersedia, return false
      }
    }
    return true; // Semua jam dalam durasi tersedia
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
      int pricePerHour = int.parse(widget.lapang.price.toString());
      if (isMember) {
        pricePerHour = (pricePerHour * 0.6).round();
      }

      int totalPrice = bookingDuration * pricePerHour;

      if (usePhotographer && widget.lapang.name != "Gokart") {
        totalPrice += 200000;
      }

      if (useReferee && widget.lapang.name != "Gokart") {
        totalPrice += 70000;
      }

      final int currentStartHour = int.parse(selectedHour.split(":")[0]);
      final int maxAllowedDuration = 22 - currentStartHour;
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

      // Check availability only against confirmed bookings
      if (!isDurationAvailable(currentStartHour, bookingDuration)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Slot waktu yang dipilih sudah dibooking oleh orang lain!",
            ),
          ),
        );
        return;
      }

      try {
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
          'tanggal': DateFormat('yyyy-MM-dd').format(selectedDate!),
          'jamMulai': selectedHour,
          'jamSelesai': DateFormat('HH:mm').format(
            DateTime(
              selectedDate!.year,
              selectedDate!.month,
              selectedDate!.day,
              int.parse(selectedHour.split(":")[0]) + bookingDuration,
            ),
          ),
          'statusBooking': 'Pending',
          'lapangId': widget.lapang.id,
          'userId': user!.uid,
          'namaPengguna': userName,
          'noWhatsapp': userPhone ?? "",
          'duration': bookingDuration.toString(),
          'isMember': isMember,
          'teamName': teamName,
          'usePhotographer': usePhotographer,
          'useReferee': useReferee,
          'totalPrice': totalPrice,
          'createdAt': FieldValue.serverTimestamp(), // Add created timestamp
        };

        final docRef = await FirebaseFirestore.instance
            .collection('bookings')
            .add(bookingData);

        final cart = context.read<Cart>();
        cart.addToCart(
          user!.uid,
          docRef.id,
          widget.lapang,
          bookingDuration,
          DateFormat('yyyy-MM-dd').format(selectedDate!),
          selectedHour,
          totalPrice,
          usePhotographer,
          useReferee,
          teamName,
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
      // _fetchBookedSlots();
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
      pricePerHour = (pricePerHour * 0.6).round();
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
    final currentTime = DateTime.now();
    final userProvider = Provider.of<UserProvider>(context);
    isMember = userProvider.isMember; // Perbarui status member

    // Hitung harga dengan diskon jika member
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMember
                    ? "Harga (Diskon 40%): Rp $pricePerHour / jam"
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
                      teamName =
                          value; // Nilai input disimpan ke state `teamName`
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
              Row(
                children: [
                  Text(
                    "Pilih Tanggal Booking:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (!isFormValid) // Tampilkan pesan jika form belum valid
                    const Padding(
                      padding: EdgeInsets.only(left: 10),
                      // child: Text(
                      //   "(Isi nama tim/nama pemesan terlebih dahulu)",
                      //   style: TextStyle(
                      //     fontSize: 14,
                      //     color: Colors.red,
                      //   ),
                      // ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              AbsorbPointer(
                absorbing:
                    !isFormValid, // Nonaktifkan widget jika form belum valid
                child: Opacity(
                  opacity:
                      isFormValid ? 1.0 : 0.5, // Kurangi opacity jika nonaktif
                  child: WeeklyCalendar(
                    currentStartOfWeek: _currentStartOfWeek,
                    onDateSelected: (date) {
                      setState(() {
                        selectedDate = date;
                      });
                      _fetchUnavailableTimes();
                      // _fetchBookedSlots();
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (!isFormValid || selectedDate == null)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                ),
              const SizedBox(height: 10),
              AbsorbPointer(
                  absorbing: !isFormValid || selectedDate == null,
                  child: Opacity(
                      opacity: isFormValid && selectedDate != null ? 1.0 : 0.5,
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
                            final isBooked =
                                unavailableTimes.contains("$hour:00");

                            return ChoiceChip(
                              label: Text("$hour:00"),
                              selected: selectedHour == "$hour:00",
                              onSelected: (isPast || isBooked)
                                  ? null
                                  : (bool selected) {
                                      setState(() {
                                        selectedHour = "$hour:00";
                                      });
                                    },
                              backgroundColor: isPast || isBooked
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade100,
                              labelStyle: TextStyle(
                                color: selectedHour == "$hour:00"
                                    ? Colors.black
                                    : Colors.black,
                              ),
                            );
                          },
                        ),
                      )))
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (!isFormValid || selectedDate == null || selectedHour.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
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
                        final int currentStartHour = selectedHour.isNotEmpty
                            ? int.parse(selectedHour.split(":")[0])
                            : 0;
                        final int maxAllowedDuration = selectedHour.isNotEmpty
                            ? (22 - currentStartHour)
                            : 5;

                        final bool isWithinClosingTime =
                            duration <= maxAllowedDuration;

                        bool isDurationAvailable = selectedHour.isNotEmpty
                            ? this
                                .isDurationAvailable(currentStartHour, duration)
                            : true;

                        return ChoiceChip(
                          label: Text("$duration Jam"),
                          selected: bookingDuration == duration,
                          onSelected: (isFormValid &&
                                  selectedDate != null &&
                                  selectedHour.isNotEmpty &&
                                  isWithinClosingTime &&
                                  isDurationAvailable)
                              ? (bool selected) {
                                  setState(() {
                                    bookingDuration = duration;
                                    _updateTotalPrice();
                                  });
                                }
                              : null,
                          selectedColor: Colors.grey.shade300,
                          backgroundColor: isDurationAvailable
                              ? Colors.grey.shade100
                              : Colors.grey
                                  .shade300, // Nonaktifkan jika tidak tersedia
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
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Tampilkan layanan tambahan hanya jika bukan lapang Gokart
        if (widget.lapang.name != "Gokart")
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tambahan Layanan:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      _updateTotalPrice(); // Panggil fungsi ini
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
                      _updateTotalPrice(); // Panggil fungsi ini
                    });
                  },
                ),
              ],
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
