// ignore_for_file: avoid_print, deprecated_member_use, unnecessary_null_comparison, unused_element, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/pages/booking_summary_page.dart';
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
  bool isMember = false;
  bool usePhotographer = false;
  int photographerPrice = 200000;
  bool useReferee = false;
  int refereePrice = 70000;
  bool useIceBath = false;
  int iceBathPrice = 50000;
  String teamName = "";
  final _formKey = GlobalKey<FormState>();
  bool isFormValid = false;
  DateTime _currentStartOfWeek =
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

  @override
  void initState() {
    super.initState();
    _fetchLapangData();
    _loadLovedState();
    _setInitialBookingTime();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    isMember = userProvider.isMember;
  }

  // [LOGIKA BARU] - Mengadopsi fungsi harga dinamis dari DetailPage
  int _getPriceForHour(int hour) {
    if (selectedLapang == null || selectedLapang!.price == null) return 0;

    int basePrice = int.tryParse(selectedLapang!.price!) ?? 0;
    String lapangName = selectedLapang!.name.toString();

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

  // [LOGIKA BARU] - Mengadopsi format rentang harga dari DetailPage
  String _getPriceRangeString() {
    if (selectedLapang == null) return "Rp 0";
    int pagiPrice = _getPriceForHour(8);
    int malamPrice = _getPriceForHour(19);

    final formatCurrency =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    if (pagiPrice == malamPrice) {
      return "${formatCurrency.format(pagiPrice)} / jam";
    } else {
      return "${formatCurrency.format(pagiPrice)} - ${formatCurrency.format(malamPrice)}";
    }
  }

  // [LOGIKA BARU] - Mengganti fungsi update total harga dengan yang dari DetailPage
  void _updateTotalPrice() {
    if (selectedLapang == null) return;
    totalPrice = 0;

    if (selectedHour.isNotEmpty && bookingDuration > 0) {
      final int startHour = int.parse(selectedHour.split(":")[0]);
      double cumulativePrice = 0;

      for (int i = 0; i < bookingDuration; i++) {
        final int currentHour = startHour + i;
        if (currentHour >= 23) break; // Batas jam operasional

        double priceForThisHour = _getPriceForHour(currentHour).toDouble();
        if (isMember) {
          priceForThisHour *= 0.9; // Diskon 10% untuk member
        }
        cumulativePrice += priceForThisHour;
      }
      totalPrice = cumulativePrice.round();

      // Tambahkan biaya layanan tambahan
      if (usePhotographer) totalPrice += photographerPrice;
      if (useReferee) totalPrice += refereePrice;
      if (useIceBath &&
          isMember &&
          (selectedLapang!.name == "Lapang Minisoccer" ||
              useIceBath &&
                  isMember &&
                  selectedLapang!.name == "Lapang Basket Vynil")) {
        totalPrice += iceBathPrice;
      }
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
      if (lapang.name != null && mounted) {
        setState(() {
          selectedLapang = lapang;
        });
        _fetchUnavailableTimes();
        _updateTotalPrice();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lapang tidak ditemukan!')),
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
      if (mounted) {
        setState(() {
          unavailableTimes = times;
        });
      }
    } catch (e) {
      print("Error fetching unavailable times: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat data ketersediaan jam')),
      );
    }
  }

  Future<void> _setInitialBookingTime() async {
    final now = DateTime.now();
    final availableDays = widget.team.availableDays;
    final availableHours = widget.team.availableHours;
    DateTime? nearestDate;
    String? nearestHour;
    int weekOffset = 0;

    // Logika untuk menemukan hari dan jam tersedia terdekat
    while (nearestDate == null && weekOffset < 4) {
      // Cek untuk 4 minggu ke depan
      for (var dayName in availableDays) {
        int dayIndex = _getDayIndex(dayName);
        if (dayIndex == -1) continue;

        DateTime potentialDate = _currentStartOfWeek
            .add(Duration(days: dayIndex + (7 * weekOffset)));

        if (potentialDate.isBefore(now) && potentialDate.day != now.day) {
          continue; // Lewati hari yang sudah lewat
        }
        // Cari jam yang tersedia di hari itu
        for (var hourStr in availableHours) {
          final hour = int.parse(hourStr.split(":")[0]);
          final bookingTime = DateTime(
              potentialDate.year, potentialDate.month, potentialDate.day, hour);

          if (bookingTime.isAfter(now)) {
            nearestDate = potentialDate;
            nearestHour = hourStr;
            break; // Jam ditemukan
          }
        }
        if (nearestDate != null) break; // Hari ditemukan
      }
      weekOffset++;
    }

    if (mounted && nearestDate != null && nearestHour != null) {
      setState(() {
        selectedDate = nearestDate;
        _currentStartOfWeek =
            nearestDate!.subtract(Duration(days: nearestDate.weekday - 1));
        selectedHour = nearestHour!;
        bookingDuration = 1; // Default durasi
      });
      await _fetchUnavailableTimes();
      _updateTotalPrice();
    }
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

  Future<void> _loadLovedState() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'isLoved_${selectedLapang?.id}';
    if (mounted) {
      setState(() {
        isLoved = prefs.getBool(key) ?? false;
      });
    }
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
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle not logged in
      return;
    }

    // Validasi tambahan jika diperlukan
    final int currentStartHour = int.parse(selectedHour.split(":")[0]);
    if (currentStartHour + bookingDuration > 23) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Booking tidak bisa melebihi jam 23:00!"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final cart = context.read<Cart>();
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);

      cart.addToCart(
        user.uid,
        DateTime.now()
            .millisecondsSinceEpoch
            .toString(), // Unique ID for cart item
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

  // [UI BARU] - Mengadopsi dialog pop-up dari DetailPage
  void popUpDialog() {
    final formattedDate =
        DateFormat('dd MMMM yyyy', 'id_ID').format(selectedDate!);
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.check_mark_circled,
                  color: Colors.green, size: 60),
              const SizedBox(height: 16),
              const Text(
                'Berhasil Ditambahkan',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${selectedLapang!.name} pada $formattedDate jam $selectedHour ($bookingDuration jam) telah masuk keranjang',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.0, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('Selesai',
                          style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        goToCart();
                      },
                      child: const Text('Lihat Keranjang',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    isMember = userProvider.isMember;
    final cart = context.watch<Cart>();

    if (selectedLapang == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Lapang Sparing')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, cart),
      body: _buildContent(context, cart),
      bottomNavigationBar: _buildBottomBar(cart),
    );
  }

  AppBar _buildAppBar(BuildContext context, Cart cart) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.5),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.5),
            child: IconButton(
              icon: Icon(
                isLoved ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                color: isLoved ? Colors.redAccent : Colors.white,
              ),
              onPressed: () {
                setState(() => isLoved = !isLoved);
                _saveLovedState();
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: IconButton(
                  onPressed: goToCart,
                  icon: const Icon(CupertinoIcons.bag, color: Colors.white),
                ),
              ),
              if (cart.cart.isNotEmpty)
                Positioned(
                  top: 7,
                  right: 5,
                  child: CircleAvatar(
                    radius: 7,
                    backgroundColor: Colors.amber,
                    child: Text(
                      cart.cart.length.toString(),
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, Cart cart) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageHeader(context),
          _buildInfoSection(context),
          const SizedBox(height: 8),
          _buildFacilitiesSection(context),
          const SizedBox(height: 8),
          _buildBookingForm(context),
          if (selectedLapang!.name != "Gokart") ...[
            const SizedBox(height: 8),
            _buildAddonServicesSection(context),
          ],
          const SizedBox(height: 120), // Spacer for bottom bar
        ],
      ),
    );
  }

  Widget _buildImageHeader(BuildContext context) {
    return Hero(
      tag: selectedLapang!.imagePath.toString(),
      child: Container(
        height: 320,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(selectedLapang!.imagePath.toString()),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3), BlendMode.darken),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Container(
      transform: Matrix4.translationValues(0.0, -20.0, 0.0),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedLapang!.name.toString(),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _getPriceRangeString(),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const Text(
                " / jam",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey),
              ),
            ],
          ),
          if (isMember)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                "Harga belum termasuk diskon member 10%",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const Divider(height: 30, thickness: 1),
          const Text(
            "Deskripsi",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            selectedLapang!.description.toString(),
            style:
                TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Fasilitas"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
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
                        iconData = Icons.restaurant_menu;
                        break;
                      case 'Toilet':
                        iconData = Icons.wc;
                        break;
                      default:
                        iconData = Icons.check_circle_outline;
                    }
                    return Chip(
                      avatar: Icon(iconData, color: Colors.black87, size: 18),
                      label: Text(facility),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                      backgroundColor: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                    );
                  }).toList() ??
                  [],
            ),
          ),
        ],
      ),
    );
  }

  // [UI DIMODIFIKASI] - Form booking dengan tampilan read-only untuk jadwal
  Widget _buildBookingForm(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Atur Jadwal Booking"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: "Cth: Tim Futsal Bahagia",
                  labelText: "Nama Tim / Atas Nama",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Nama tim/pemesan wajib diisi!";
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    teamName = value;
                    isFormValid = _formKey.currentState?.validate() ?? false;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Jadwal Telah Ditentukan"),
            // Tampilan Read-only untuk tanggal, jam, dan durasi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  _buildReadOnlyInfo(
                    icon: Icons.calendar_today,
                    label: "Tanggal",
                    value: selectedDate != null
                        ? DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                            .format(selectedDate!)
                        : 'Memuat...',
                  ),
                  const SizedBox(height: 12),
                  _buildReadOnlyInfo(
                    icon: Icons.access_time_filled,
                    label: "Jam Mulai",
                    value: selectedHour.isNotEmpty ? selectedHour : 'Memuat...',
                  ),
                  const SizedBox(height: 12),
                  _buildReadOnlyInfo(
                    icon: Icons.hourglass_bottom,
                    label: "Durasi",
                    value: "${bookingDuration.toString()} Jam",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper untuk menampilkan info read-only
  Widget _buildReadOnlyInfo(
      {required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddonServicesSection(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Opacity(
        opacity: isFormValid ? 1.0 : 0.5,
        child: IgnorePointer(
          ignoring: !isFormValid,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Layanan Tambahan"),
              if (!isFormValid)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text("Isi nama tim/pemesan untuk mengaktifkan",
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    _buildServiceOption(
                      icon: Icons.camera_alt_outlined,
                      title: "Photographer",
                      price:
                          "Rp ${NumberFormat.decimalPattern('id').format(photographerPrice)}",
                      value: usePhotographer,
                      onChanged: (val) => setState(() {
                        usePhotographer = val;
                        _updateTotalPrice();
                      }),
                    ),
                    const SizedBox(height: 10),
                    _buildServiceOption(
                      icon: Icons.sports,
                      title: "Wasit",
                      price:
                          "Rp ${NumberFormat.decimalPattern('id').format(refereePrice)}",
                      value: useReferee,
                      onChanged: (val) => setState(() {
                        useReferee = val;
                        _updateTotalPrice();
                      }),
                    ),
                    if (isMember &&
                            selectedLapang!.name == "Lapang Minisoccer" ||
                        isMember &&
                            selectedLapang!.name == "Lapang Basket Vynil")
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: _buildServiceOption(
                          icon: Icons.ac_unit,
                          title: "Ice Bath",
                          price:
                              "Rp ${NumberFormat.decimalPattern('id').format(iceBathPrice)}",
                          value: useIceBath,
                          onChanged: (val) => setState(() {
                            useIceBath = val;
                            _updateTotalPrice();
                          }),
                        ),
                      ),
                  ],
                ),
              )
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
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: value ? Colors.black : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: value ? Colors.white : Colors.black),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
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
                  const SizedBox(height: 2),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 14,
                      color: value ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              value ? Icons.check_circle : Icons.radio_button_unchecked,
              color: value ? Colors.white : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(Cart cart) {
    bool canBook = isFormValid &&
        selectedHour.isNotEmpty &&
        bookingDuration > 0 &&
        selectedDate != null;

    if (!canBook || cart.cart.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return BottomAppBar(
      height: 90,
      color: Colors.white,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Total Bayar",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Text(
                    NumberFormat.currency(
                            locale: 'id', symbol: 'Rp ', decimalDigits: 0)
                        .format(totalPrice),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Booking Sekarang",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
