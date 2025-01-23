// ignore_for_file: unused_local_variable, avoid_print, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      print("SharedPreferences initialized"); // Debug log
      _loadLovedState();
    }).catchError((error) {
      print("Error initializing SharedPreferences: $error");
    });
    _fetchUnavailableTimes();
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
      final bookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('lapangId', isEqualTo: widget.lapang.id)
          .where('date',
              isEqualTo: selectedDate!.toIso8601String().split('T')[0])
          .get();
      List<String> times = [];
      for (var doc in bookings.docs) {
        final startTime = int.parse(doc['time'].split(":")[0]);
        final duration = doc['duration'];
        for (int i = 0; i < duration; i++) {
          times.add("${startTime + i}:00");
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
        selectedDate != null) {
      final cart = context.read<Cart>();
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      final selectedTime = DateTime(selectedDate!.year, selectedDate!.month,
          selectedDate!.day, int.parse(selectedHour.split(":")[0]));

      bool isAvailable = true;
      for (int i = 0; i < bookingDuration; i++) {
        final timeToCheck = selectedTime.add(Duration(hours: i));
        if (unavailableTimes
            .contains(DateFormat('HH:mm').format(timeToCheck))) {
          isAvailable = false;
          break;
        }
      }

      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Jam ini sudah terbooking!")),
        );
        return;
      }

      // Add booking to Firebase
      await FirebaseFirestore.instance.collection('bookings').add({
        'date': formattedDate,
        'time': selectedHour,
        'duration': bookingDuration,
        'lapangId': widget.lapang.id,
      }).then((value) {
        print("Booking added successfully");
      }).catchError((error) {
        print("Failed to add booking: $error");
      });

      // Add to cart
      cart.addToCart(widget.lapang, bookingDuration, formattedDate,
          selectedHour, bookingDuration);
      popUpDialog();
      for (int i = 0; i < bookingDuration; i++) {
        final blockedTime = selectedTime.add(Duration(hours: i));
        unavailableTimes.add(DateFormat('HH:mm').format(blockedTime));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Harap pilih tanggal, jam, dan durasi booking!")),
      );
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
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
          padding: const EdgeInsets.all(16.0),
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Harga: Rp ${widget.lapang.price}",
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Pilih Tanggal Booking:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ChoiceChip(
            label: Text(
              selectedDate != null
                  ? DateFormat('dd MMM yyyy').format(selectedDate!)
                  : "Pilih Tanggal",
            ),
            selected: selectedDate != null,
            onSelected: (bool selected) async {
              if (selected) {
                DateTime? date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  setState(() {
                    selectedDate = date;
                  });
                  _fetchUnavailableTimes();
                }
              }
            },
            selectedColor: Colors.grey.shade300,
            backgroundColor: Colors.grey.shade100,
            labelStyle: TextStyle(
              color: selectedDate != null ? Colors.black : Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Pilih Jam Booking:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: List.generate(
              14,
              (index) {
                final hour = 8 + index;
                final bookingTime = DateTime(
                    selectedDate?.year ?? currentTime.year,
                    selectedDate?.month ?? currentTime.month,
                    selectedDate?.day ?? currentTime.day,
                    hour);
                bool isPast = bookingTime.isBefore(currentTime);
                final selectedStartHour = selectedHour.isNotEmpty
                    ? int.parse(selectedHour.split(":")[0])
                    : null;
                final isDisabled = selectedStartHour != null &&
                    hour >= selectedStartHour &&
                    hour < selectedStartHour + bookingDuration;
                final isUnavailable = unavailableTimes.contains("$hour:00");

                return ChoiceChip(
                  label: Text("$hour:00"),
                  selected: selectedHour == "$hour:00",
                  onSelected: isPast || isDisabled || isUnavailable
                      ? null
                      : (bool selected) {
                          setState(() {
                            selectedHour = "$hour:00";
                          });
                        },
                  backgroundColor: isPast || isUnavailable
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
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Pilih Durasi Booking (jam):",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: List.generate(
              5,
              (index) {
                final duration = index + 1;
                return ChoiceChip(
                  label: Text("$duration Jam"),
                  selected: bookingDuration == duration,
                  onSelected: (bool selected) {
                    setState(() {
                      bookingDuration = duration;
                      totalPrice = bookingDuration *
                          int.parse(widget.lapang.price.toString());
                    });
                  },
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
