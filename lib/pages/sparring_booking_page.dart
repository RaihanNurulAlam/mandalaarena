// ignore_for_file: avoid_print, deprecated_member_use, unnecessary_null_comparison, unused_element
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/pages/cart_page.dart';
import 'package:mandalaarenaapp/pages/models/sparring_team_model.dart';
import 'package:mandalaarenaapp/pages/models/lapang.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
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
  int bookingDuration = 1;
  DateTime? selectedDate;
  List<String> unavailableTimes = [];
  bool isLoved = false;
  final DateTime _currentStartOfWeek =
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  bool isMember = false;
  bool usePhotographer = false;
  bool useReferee = false;
  String teamName = "";
  final _formKey = GlobalKey<FormState>();
  bool isFormValid = false;
  bool useIceBath = false;
  int iceBathPrice = 50000;

  @override
  void initState() {
    super.initState();
    _fetchLapangData();
    _loadLovedState();
    _setInitialBookingTime();
    // Get member status from UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    isMember = userProvider.isMember;
  }

  void _updateTotalPrice() {
    if (selectedLapang == null) return;
    int pricePerHour = int.parse(selectedLapang!.price.toString());
    if (isMember) {
      pricePerHour = (pricePerHour * 0.9).round(); // Diskon 10% untuk member
    }
    totalPrice = bookingDuration * pricePerHour;

    // Tambahkan biaya tambahan untuk jam tertentu jika bukan member
    if (!isMember) {
      final int startHour = int.parse(selectedHour.split(":")[0]);
      if (startHour >= 13 && startHour < 18) {
        totalPrice += 50000; // Tambahan 50 ribu untuk jam 13:00 - 17:59
      } else if (startHour >= 19 && startHour <= 21) {
        totalPrice += 100000; // Tambahan 100 ribu untuk jam 19:00 - 21:00
      }
    }

    // Tambahkan biaya tambahan untuk layanan
    if (usePhotographer && selectedLapang!.name != "Gokart") {
      totalPrice += 200000;
    }
    if (useReferee && selectedLapang!.name != "Gokart") {
      totalPrice += 70000;
    }

    // Add Ice Bath price for Mini Soccer members
    if (useIceBath && isMember && selectedLapang!.name == "Lapang Minisoccer") {
      totalPrice += iceBathPrice;
    }
    setState(() {});
  }

  Future<void> _fetchLapangData() async {
    try {
      final List<Lapang> lapangList = await Lapang.getLapangFromJson(context);
      final lapang = lapangList.firstWhere(
        (lapang) => lapang.name == widget.lapangCategory,
        orElse: () => Lapang(),
      );
      if (lapang.name != null) {
        setState(() {
          selectedLapang = lapang;
          _updateTotalPrice();
        });
        _fetchUnavailableTimes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lapang tidak ditemukan!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data lapang: $e')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _fetchUnavailableTimes() async {
    if (selectedDate == null || selectedLapang == null) return;
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
                lapangName == selectedLapang!.name) {
              final startHour = int.parse(time.split(":")[0]);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data ketersediaan jam')),
      );
    }
  }

  bool _isTimeSlotAvailable(int hour) {
    // Jam 18:00 tidak bisa dibooking
    if (hour == 18) {
      return false;
    }
    // Periksa apakah jam tersedia dalam daftar tim dan belum dibooking
    final isTeamAvailable = widget.team.availableHours.contains("$hour:00");
    final isNotBooked = !unavailableTimes.contains("$hour:00");
    // Periksa apakah jam tidak berada di masa lalu
    final now = DateTime.now();
    final bookingTime = DateTime(
      selectedDate?.year ?? now.year,
      selectedDate?.month ?? now.month,
      selectedDate?.day ?? now.day,
      hour,
    );
    final isNotPast =
        bookingTime.isAfter(now) || bookingTime.isAtSameMomentAs(now);
    return isTeamAvailable && isNotBooked && isNotPast;
  }

  bool _isDurationAvailable(int startHour, int duration) {
    for (int i = 0; i < duration; i++) {
      final hour = startHour + i;
      // Jam 18:00 tidak bisa dibooking
      if (hour == 18) {
        return false;
      }
      if (!_isTimeSlotAvailable(hour)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _setInitialBookingTime() async {
    final now = DateTime.now();
    final availableDays = widget.team.availableDays;
    final availableHours = widget.team.availableHours;
    DateTime? nearestDate;
    int weekOffset = 0;

    while (nearestDate == null && weekOffset < 52) {
      for (var day in availableDays) {
        final dayIndex = _getDayIndex(day);
        final date = _currentStartOfWeek
            .add(Duration(days: dayIndex + (7 * weekOffset)));
        if (date.isAfter(now) ||
            (date.isAtSameMomentAs(now) && _isTimeAvailable(availableHours))) {
          final isBooked = await _isDayBooked(date);
          if (!isBooked) {
            nearestDate = date;
            break;
          }
        }
      }
      weekOffset++;
    }

    if (nearestDate != null) {
      setState(() {
        selectedDate = nearestDate;
        selectedHour = availableHours.isNotEmpty ? availableHours.first : "";
        bookingDuration = 1;
      });
      _fetchUnavailableTimes();
    }
  }

  Future<bool> _isDayBooked(DateTime date) async {
    if (selectedLapang == null) return false;
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final bookings = await FirebaseFirestore.instance
        .collection('bookings')
        .where('items', isNotEqualTo: null)
        .get();

    for (var doc in bookings.docs) {
      final data = doc.data();
      final items = data['items'] as List<dynamic>?;
      if (items != null) {
        for (var item in items) {
          final bookingDate = item['bookingDate'] as String?;
          final lapangName = item['name'] as String?;
          if (bookingDate == formattedDate &&
              lapangName == selectedLapang!.name) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _isTimeAvailable(List<String> availableHours) {
    final now = DateTime.now();
    final currentHour = now.hour;
    for (var hour in availableHours) {
      final bookingHour = int.parse(hour.split(":")[0]);
      if (bookingHour > currentHour) {
        return true;
      }
    }
    return false;
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
    setState(() {
      isLoved = prefs.getBool(key) ?? false;
    });
  }

  Future<void> _saveLovedState() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'isLoved_${selectedLapang?.id}';
    await prefs.setBool(key, isLoved);
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

    if (selectedHour.isEmpty ||
        bookingDuration <= 0 ||
        selectedDate == null ||
        selectedLapang == null) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anda harus login terlebih dahulu!')),
      );
      return;
    }

    final currentStartHour = int.parse(selectedHour.split(":")[0]);
    final maxAllowedDuration = 22 - currentStartHour;
    if (bookingDuration > maxAllowedDuration) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Tidak bisa booking pada jam tersebut karena melebihi jam tutup!"),
        ),
      );
      return;
    }

    if (!_isDurationAvailable(currentStartHour, bookingDuration)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Slot waktu yang dipilih sudah dibooking oleh orang lain!"),
        ),
      );
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception("User data not found in Firestore.");
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userName = userData['name'];
      final userPhone = userData['phone'] as String?;

      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      final bookingData = {
        'lapangan': selectedLapang!.name,
        'tanggal': formattedDate,
        'jamMulai': selectedHour,
        'jamSelesai': DateFormat('HH:mm').format(
          DateTime(
            selectedDate!.year,
            selectedDate!.month,
            selectedDate!.day,
            currentStartHour + bookingDuration,
          ),
        ),
        'statusBooking': 'Pending',
        'lapangId': selectedLapang!.id,
        'userId': user.uid,
        'namaPengguna': userName,
        'noWhatsapp': userPhone ?? "",
        'duration': bookingDuration.toString(),
        'isMember': isMember,
        'teamName': teamName,
        'usePhotographer': usePhotographer,
        'useReferee': useReferee,
        'totalPrice': totalPrice,
        'createdAt': FieldValue.serverTimestamp(),
        'items': [
          {
            'name': selectedLapang!.name,
            'bookingDate': formattedDate,
            'time': selectedHour,
            'quantity': bookingDuration.toString(),
            'price': selectedLapang!.price,
            'discountedPrice': isMember ? totalPrice : null,
            'teamName': teamName,
            'usePhotographer': usePhotographer,
            'useReferee': useReferee,
            'useIceBath': useIceBath,
          }
        ],
      };

      final docRef = await FirebaseFirestore.instance
          .collection('bookings')
          .add(bookingData);

      final cart = context.read<Cart>();
      cart.addToCart(
        user.uid,
        docRef.id,
        selectedLapang!,
        bookingDuration,
        formattedDate,
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
    final userProvider = Provider.of<UserProvider>(context);
    isMember = userProvider.isMember;

    if (selectedLapang == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Booking Lapang')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    int pricePerHour = int.parse(selectedLapang!.price.toString());
    if (isMember) {
      pricePerHour = (pricePerHour * 0.9).round();
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
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.yellow),
                            Text(
                              selectedLapang!.rating.toString(),
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isMember
                          ? "Harga (Diskon 10%): Rp $pricePerHour / jam"
                          : "Harga: Rp ${selectedLapang!.price} / jam",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Deskripsi:",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      selectedLapang!.description.toString(),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Fasilitas:",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: selectedLapang!.facilities?.map((facility) {
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
                    const SizedBox(height: 20),
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
                                isFormValid = _formKey.currentState!.validate();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Pilih Tanggal Booking:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                          availableDays: widget.team.availableDays,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Pilih Jam Booking:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                          children: List.generate(14, (index) {
                            final hour = 8 + index;
                            final timeLabel = "$hour:00";
                            final isAvailable = _isTimeSlotAvailable(hour);
                            final isSelected = selectedHour == timeLabel;
                            return ChoiceChip(
                              label: Text(timeLabel),
                              selected: isSelected,
                              onSelected: isAvailable
                                  ? (bool selected) {
                                      if (selected) {
                                        setState(() {
                                          selectedHour = timeLabel;
                                          bookingDuration =
                                              1; // Default durasi 1 jam
                                          _updateTotalPrice();
                                        });
                                      }
                                    }
                                  : null,
                              backgroundColor: isAvailable
                                  ? Colors.grey.shade100
                                  : Colors.grey.shade300,
                              labelStyle: TextStyle(
                                color: isAvailable ? Colors.black : Colors.grey,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Pilih Durasi Booking (jam):",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                          children: List.generate(5, (index) {
                            final duration = index + 1;
                            final int currentStartHour = selectedHour.isNotEmpty
                                ? int.parse(selectedHour.split(":")[0])
                                : 0;
                            final int maxAllowedDuration =
                                selectedHour.isNotEmpty
                                    ? (22 - currentStartHour)
                                    : 5;
                            final bool isWithinClosingTime =
                                duration <= maxAllowedDuration;
                            final bool isDurationAvailable =
                                selectedHour.isNotEmpty
                                    ? _isDurationAvailable(
                                        currentStartHour, duration)
                                    : false;
                            return ChoiceChip(
                              label: Text("$duration Jam"),
                              selected: bookingDuration == duration,
                              onSelected:
                                  isDurationAvailable && isWithinClosingTime
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
                                  : Colors.grey.shade300,
                              labelStyle: TextStyle(
                                color: bookingDuration == duration
                                    ? Colors.black
                                    : Colors.black,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (selectedLapang!.name != "Gokart")
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Tambahan Layanan:",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
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
                            if (isMember &&
                                selectedLapang!.name == "Lapang Minisoccer")
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: _buildServiceOption(
                                  icon: Icons.ac_unit,
                                  title: "Ice Bath",
                                  price: "Rp 50,000",
                                  value: useIceBath,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      useIceBath = value ?? false;
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
                      final isPast = date
                          .isBefore(DateTime.now().subtract(Duration(days: 1)));
                      final isSelected = selectedDate != null &&
                          date.year == selectedDate!.year &&
                          date.month == selectedDate!.month &&
                          date.day == selectedDate!.day;
                      final dayName = DateFormat('EEEE').format(date);
                      final isAvailable = availableDays.contains(dayName);
                      return GestureDetector(
                        onTap: isPast || !isAvailable
                            ? null
                            : () => onDateSelected(date),
                        child: Container(
                          padding: const EdgeInsets.all(12),
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
