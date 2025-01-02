// ignore_for_file: deprecated_member_use, unused_local_variable, unused_element, avoid_print
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

  @override
  void initState() {
  super.initState();
  SharedPreferences.getInstance().then((prefs) {
    print("SharedPreferences initialized"); // Debug log
    _loadLovedState();
  }).catchError((error) {
    print("Error initializing SharedPreferences: $error");
  });
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

  Future<void> addToCart() async {
    if (selectedHour.isNotEmpty &&
        bookingDuration > 0 &&
        selectedDate != null) {
      final cart = context.read<Cart>();
      final formattedDate = DateFormat('dd MMMM yyyy').format(selectedDate!);
      final selectedTime = DateTime(selectedDate!.year, selectedDate!.month,
          selectedDate!.day, int.parse(selectedHour.split(":")[0]));

      if (widget.lapang.bookings?.contains(selectedTime.toIso8601String()) ??
          false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Jam ini sudah terbooking!")),
        );
        return;
      }

      cart.addToCart(widget.lapang, bookingDuration, formattedDate);
      popUpDialog();
      widget.lapang.bookings?.add(selectedTime.toIso8601String());
      for (int i = 0; i < bookingDuration; i++) {
        final blockedTime = selectedTime.add(Duration(hours: i));
        widget.lapang.bookings?.add(blockedTime.toIso8601String());
      }
      await FirebaseFirestore.instance
          .collection('lapang')
          .doc(widget.lapang.id)
          .update({
        'bookings': widget.lapang.bookings,
      });
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
        padding: const EdgeInsets.all(8.0),
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
        padding: const EdgeInsets.all(8.0),
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
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Fasilitas:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...?widget.lapang.facilities?.map((facility) => Text("- $facility")),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          "Pilih Tanggal Booking:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () async {
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
            }
          },
          child: Text(
            selectedDate != null
                ? "${selectedDate?.toLocal().toString().split(' ')[0]}"
                : "Pilih Tanggal",
          ),
        ),
      ),
      const SizedBox(height: 20),
      const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          "Pilih Jam Booking:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      Wrap(
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

            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: ChoiceChip(
                label: Text("$hour:00"),
                selected: selectedHour == "$hour:00",
                onSelected: isPast || isDisabled
                    ? null
                    : (bool selected) {
                        setState(() {
                          selectedHour = "$hour:00";
                        });
                      },
                selectedColor: Colors.blue,
                backgroundColor: isPast || isDisabled
                    ? Colors.grey.shade300
                    : null,
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 20),
      const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          "Pilih Durasi Booking (jam):",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      Wrap(
        children: List.generate(
          5,
          (index) {
            final duration = index + 1;
            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: ChoiceChip(
                label: Text("$duration Jam"),
                selected: bookingDuration == duration,
                onSelected: (bool selected) {
                  setState(() {
                    bookingDuration = duration;
                    totalPrice = bookingDuration *
                        int.parse(widget.lapang.price.toString());
                  });
                },
              ),
            );
          },
        ),
      ),
    ],
  );
}
}