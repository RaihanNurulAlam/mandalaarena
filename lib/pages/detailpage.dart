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
  // =======================================================================
  // [LOGIKA TIDAK BERUBAH] - Semua variabel state dan logika inti tetap sama
  // =======================================================================
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
  DateTime _currentStartOfWeek =
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

  // --- [LOGIKA TIDAK BERUBAH] Fungsi untuk menampilkan dialog jika ada booking ---
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

  // --- [LOGIKA TIDAK BERUBAH] Fungsi terpusat untuk menangani aksi booking ---
  void _handleBookingAction() {
    final cart = context.read<Cart>();
    final user = FirebaseAuth.instance.currentUser;

    if (cart.cart.isNotEmpty) {
      _showExistingBookingDialog();
      return;
    }

    if (user == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Diperlukan'),
          content:
              const Text('Harap login terlebih dahulu untuk booking jadwal'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
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

  // --- [LOGIKA TIDAK BERUBAH] Fungsi untuk mendapatkan harga per jam ---
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

  // --- [LOGIKA TIDAK BERUBAH] Fungsi untuk format rentang harga ---
  String _getPriceRangeString() {
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

  // --- [LOGIKA TIDAK BERUBAH] Fungsi untuk update total harga ---
  void _updateTotalPrice() {
    totalPrice = 0;

    if (selectedHour.isNotEmpty && bookingDuration > 0) {
      final int startHour = int.parse(selectedHour.split(":")[0]);
      int hoursCounted = 0;
      double cumulativePrice = 0;

      for (int i = 0; hoursCounted < bookingDuration; i++) {
        final int currentHour = startHour + i;
        if (currentHour >= 23) break;

        double priceForThisHour = _getPriceForHour(currentHour).toDouble();
        if (isMember) {
          priceForThisHour *= 0.9;
        }
        cumulativePrice += priceForThisHour;
        hoursCounted++;
      }
      totalPrice = cumulativePrice.round();

      if (usePhotographer) totalPrice += photographerPrice;
      if (useReferee) totalPrice += refereePrice;
      if (useIceBath && isMember && widget.lapang.name == "Lapang Minisoccer") {
        totalPrice += iceBathPrice;
      }
    }
    setState(() {});
  }

  // --- [LOGIKA TIDAK BERUBAH] Fungsi untuk cek ketersediaan durasi ---
  bool isDurationAvailable(int startHour, int duration) {
    int hoursCounted = 0;
    for (int i = 0; hoursCounted < duration; i++) {
      final int currentHour = startHour + i;
      if (currentHour >= 23) return false;
      if (unavailableTimes.contains("$currentHour:00")) return false;
      hoursCounted++;
    }
    return true;
  }

  // --- [LOGIKA TIDAK BERUBAH] Fungsi untuk cek ketersediaan slot waktu ---
  bool isTimeSlotAvailable(int hour) {
    if (hour < 7 || hour >= 23) return false;
    return !unavailableTimes.contains("$hour:00");
  }

  // --- [LOGIKA TIDAK BERUBAH] initState & fungsi lifecycle ---
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

  // --- [LOGIKA TIDAK BERUBAH] Fungsi untuk mengambil data booking dari Firestore ---
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

  // --- [LOGIKA TIDAK BERUBAH] Fungsi untuk menambahkan item ke keranjang ---
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
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final int currentStartHour = int.parse(selectedHour.split(":")[0]);
      if (!isDurationAvailable(currentStartHour, bookingDuration)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Slot waktu yang dipilih sudah dibooking atau melebihi jam operasional!"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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
          SnackBar(
            content: Text("Terjadi kesalahan: $e"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // --- [LOGIKA TIDAK BERUBAH] Fungsi untuk menampilkan pop-up sukses ---
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
                '${widget.lapang.name} pada $formattedDate jam $selectedHour ($bookingDuration jam) telah masuk keranjang',
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

  // --- [LOGIKA TIDAK BERUBAH] Fungsi navigasi dan date picker ---
  void goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookingSummaryPage()),
    );
  }

  Future<void> _showDatePicker() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
        _currentStartOfWeek = date.subtract(Duration(days: date.weekday - 1));
        selectedHour = "";
        bookingDuration = 0;
      });
      _fetchUnavailableTimes();
      _updateTotalPrice();
    }
  }

  // =======================================================================
  // [UI BERUBAH] - Build method utama dan semua widget UI
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    isMember = userProvider.isMember;
    final cart = context.watch<Cart>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, cart),
      body: _buildContent(context, cart),
      bottomNavigationBar:
          _buildBottomBar(cart), // [PERUBAHAN] Menggunakan bottomNavigationBar
    );
  }

  /// AppBar Transparan
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

  /// Konten Utama Halaman
  Widget _buildContent(BuildContext context, Cart cart) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageHeader(context),
              _buildInfoSection(context),
              const SizedBox(height: 8),
              _buildFacilitiesSection(context),
              const SizedBox(height: 8),
              _buildBookingForm(context, cart),
              if (widget.lapang.name != "Gokart") ...[
                const SizedBox(height: 8),
                _buildAddonServicesSection(context),
              ],
              const SizedBox(height: 120), // Spacer for bottom bar
            ],
          ),
        ),

        // Overlay jika ada item di keranjang
        if (cart.cart.isNotEmpty)
          Positioned.fill(
            top: 300, // Mulai overlay di bawah gambar
            child: Container(
              color: Colors.white.withOpacity(0.95),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 50),
                  const SizedBox(height: 16),
                  const Text(
                    'Selesaikan Booking Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      'Anda tidak dapat membuat booking baru jika masih ada yang belum selesai di keranjang.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: goToCart,
                    icon: const Icon(
                      CupertinoIcons.bag,
                      color: Colors.white,
                    ),
                    label: const Text('Lihat Keranjang',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Header Gambar
  Widget _buildImageHeader(BuildContext context) {
    return Hero(
      tag: widget.lapang.imagePath.toString(),
      child: Container(
        height: 320,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(widget.lapang.imagePath.toString()),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3), BlendMode.darken),
          ),
        ),
      ),
    );
  }

  /// Widget untuk Judul setiap section
  Widget _buildSectionTitle(String title, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: enabled ? Colors.black : Colors.grey,
        ),
      ),
    );
  }

  /// Section Info (Nama, Harga, Deskripsi)
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
            widget.lapang.name.toString(),
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
            widget.lapang.description.toString(),
            style:
                TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
          ),
        ],
      ),
    );
  }

  /// Section Fasilitas
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

  /// Section Form Booking Utama
  Widget _buildBookingForm(BuildContext context, Cart cart) {
    bool isFormDisabled = cart.cart.isNotEmpty;

    return IgnorePointer(
      ignoring: isFormDisabled,
      child: Opacity(
        opacity: isFormDisabled ? 0.4 : 1.0,
        child: Container(
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
                        borderSide:
                            const BorderSide(color: Colors.black, width: 2),
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
                        isFormValid =
                            _formKey.currentState?.validate() ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle("Pilih Tanggal", enabled: isFormValid),
                WeeklyCalendar(
                  currentStartOfWeek: _currentStartOfWeek,
                  onDateSelected: (date) {
                    setState(() {
                      selectedDate = date;
                      selectedHour = ""; // Reset pilihan
                      bookingDuration = 0;
                    });
                    _fetchUnavailableTimes();
                    _updateTotalPrice();
                  },
                  selectedDate: selectedDate,
                  onCalendarIconPressed: _showDatePicker,
                  enabled: isFormValid,
                ),
                const SizedBox(height: 20),
                _buildSectionTitle("Pilih Jam",
                    enabled: isFormValid && selectedDate != null),
                _buildTimePicker(),
                const SizedBox(height: 20),
                _buildSectionTitle("Pilih Durasi",
                    enabled: isFormValid && selectedHour.isNotEmpty),
                _buildDurationPicker(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Picker Jam Booking (Dengan logika visual yang diperbarui)
  Widget _buildTimePicker() {
    bool enabled = isFormValid && selectedDate != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: IgnorePointer(
          ignoring: !enabled,
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: List.generate(16, (index) {
              final hour = 7 + index;
              if (hour >= 23) return const SizedBox.shrink();

              final timeStr = "$hour:00";
              final bookingTime = DateTime(selectedDate?.year ?? 0,
                  selectedDate?.month ?? 0, selectedDate?.day ?? 0, hour);
              bool isPast = bookingTime.isBefore(DateTime.now());
              bool isBooked = unavailableTimes.contains(timeStr);

              // --- [LOGIKA VISUAL DIPERBARUI] ---
              final int startHour = selectedHour.isNotEmpty
                  ? int.parse(selectedHour.split(":")[0])
                  : -1;
              final bool isWithinSelectedDuration = selectedHour.isNotEmpty &&
                  hour >= startHour &&
                  hour < startHour + bookingDuration;

              return GestureDetector(
                onTap: (isPast || isBooked)
                    ? null
                    : () {
                        setState(() {
                          selectedHour = timeStr;
                          bookingDuration =
                              1; // Default durasi saat memilih jam
                          _updateTotalPrice();
                        });
                      },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isWithinSelectedDuration
                        ? Colors.black
                        : (isPast || isBooked
                            ? Colors.grey.shade300
                            : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isWithinSelectedDuration
                          ? Colors.black
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      color: isWithinSelectedDuration
                          ? Colors.white
                          : (isPast || isBooked
                              ? Colors.grey.shade600
                              : Colors.black),
                      fontWeight: isWithinSelectedDuration
                          ? FontWeight.bold
                          : FontWeight.normal,
                      decoration: isBooked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Picker Durasi Booking
  Widget _buildDurationPicker() {
    bool enabled =
        isFormValid && selectedDate != null && selectedHour.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: IgnorePointer(
          ignoring: !enabled,
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: List.generate(5, (index) {
              final duration = index + 1;
              final int currentStartHour = selectedHour.isNotEmpty
                  ? int.parse(selectedHour.split(":")[0])
                  : 0;

              bool isAvailable =
                  isDurationAvailable(currentStartHour, duration);
              bool isSelectionEnabled =
                  isAvailable && (currentStartHour + duration <= 23);
              bool isSelected = bookingDuration == duration;

              return GestureDetector(
                onTap: !isSelectionEnabled
                    ? null
                    : () {
                        setState(() {
                          bookingDuration = duration;
                          _updateTotalPrice();
                        });
                      },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.black
                        : (!isSelectionEnabled
                            ? Colors.grey.shade300
                            : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    "$duration Jam",
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (!isSelectionEnabled
                              ? Colors.grey.shade600
                              : Colors.black),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Section Layanan Tambahan (Add-ons)
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
              _buildSectionTitle("Layanan Tambahan", enabled: isFormValid),
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
                      price: "Rp 200,000",
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
                      price: "Rp 70,000",
                      value: useReferee,
                      onChanged: (val) => setState(() {
                        useReferee = val;
                        _updateTotalPrice();
                      }),
                    ),
                    if (isMember && widget.lapang.name == "Lapang Minisoccer")
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: _buildServiceOption(
                          icon: Icons.ac_unit,
                          title: "Ice Bath",
                          price: "Rp 50,000",
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

  /// [PERUBAHAN] Tombol Aksi Bawah (Bottom Bar) dengan layout terpisah yang responsif
  Widget _buildBottomBar(Cart cart) {
    bool canBook = selectedHour.isNotEmpty &&
        bookingDuration > 0 &&
        selectedDate != null &&
        isFormValid;

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
            // Bagian Harga (Fleksibel agar tidak terpotong)
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
            // Bagian Tombol
            ElevatedButton(
              onPressed: _handleBookingAction,
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

// =======================================================================
// [UI TIDAK BERUBAH] - Widget Kalender Mingguan
// =======================================================================
class WeeklyCalendar extends StatelessWidget {
  final DateTime currentStartOfWeek;
  final Function(DateTime) onDateSelected;
  final DateTime? selectedDate;
  final VoidCallback onCalendarIconPressed;
  final bool enabled;

  const WeeklyCalendar({
    Key? key,
    required this.currentStartOfWeek,
    required this.onDateSelected,
    this.selectedDate,
    required this.onCalendarIconPressed,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: IgnorePointer(
          ignoring: !enabled,
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(7, (index) {
                      final date =
                          currentStartOfWeek.add(Duration(days: index));
                      final now = DateTime.now();
                      final isPast = date.year < now.year ||
                          (date.year == now.year && date.month < now.month) ||
                          (date.year == now.year &&
                              date.month == now.month &&
                              date.day < now.day);
                      final isSelected = selectedDate != null &&
                          date.year == selectedDate!.year &&
                          date.month == selectedDate!.month &&
                          date.day == selectedDate!.day;

                      return GestureDetector(
                        onTap: isPast ? null : () => onDateSelected(date),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey.shade300),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: Opacity(
                            opacity: isPast ? 0.5 : 1.0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat('E', 'id_ID')
                                      .format(date)
                                      .substring(0, 3), // "Sen", "Sel"
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('d').format(date),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.calendar_month_outlined, size: 28),
                onPressed: onCalendarIconPressed,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =======================================================================
// [UI TIDAK BERUBAH] - Widget Opsi Layanan Tambahan
// =======================================================================
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
        border: Border.all(color: value ? Colors.black : Colors.grey.shade300),
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
