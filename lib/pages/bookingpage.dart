import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';

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
  int bookingDuration = 1;
  bool isMember = false;
  bool usePhotographer = false;
  bool useReferee = false;
  String teamName = "";
  final _formKey = GlobalKey<FormState>();
  List<String> unavailableTimes = [];
  String? userName;
  String? userPhone;
  User? user;
  Uint8List? _webImage;
  File? _imageFile;
  String _paymentStatus = 'Booking'; // 'Booking', 'DP', or 'Sudah Bayar'
  int _downPaymentAmount = 0;
  int _remainingAmount = 0;
  final TextEditingController _downPaymentController = TextEditingController();

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
    _downPaymentController.addListener(_updateDownPayment);
  }

  @override
  void dispose() {
    _downPaymentController.dispose();
    super.dispose();
  }

  void _updateDownPayment() {
    setState(() {
      _downPaymentAmount = int.tryParse(_downPaymentController.text) ?? 0;
      _remainingAmount = totalPrice - _downPaymentAmount;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        if (kIsWeb) {
          _webImage = await pickedFile.readAsBytes();
        } else {
          _imageFile = File(pickedFile.path);
        }
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: ${e.toString()}')),
      );
    }
  }

  Future<String?> _uploadImage() async {
    try {
      if (_imageFile == null && _webImage == null) return null;

      String fileName =
          'buktipembayaran/${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

      UploadTask uploadTask;
      if (kIsWeb && _webImage != null) {
        uploadTask = storageRef.putData(_webImage!);
      } else if (_imageFile != null) {
        uploadTask = storageRef.putFile(_imageFile!);
      } else {
        throw Exception("Gambar tidak ditemukan");
      }

      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  void _updateTotalPrice() {
    final selectedLapang = lapangData.firstWhere(
      (lapang) => lapang['name'] == widget.lapangan,
      orElse: () => {},
    );

    if (selectedLapang.isEmpty) return;

    int pricePerHour = int.parse(selectedLapang['price']);

    if (isMember) {
      pricePerHour = (pricePerHour * 0.6).round();
    }

    totalPrice = bookingDuration * pricePerHour;

    if (usePhotographer && widget.lapangan != "Gokart") {
      totalPrice += photographerPrice;
    }

    if (useReferee && widget.lapangan != "Gokart") {
      totalPrice += refereePrice;
    }

    // Update remaining amount based on payment status
    if (_paymentStatus == 'Sudah Bayar') {
      _downPaymentAmount = totalPrice;
      _remainingAmount = 0;
    } else if (_paymentStatus == 'DP') {
      _remainingAmount = totalPrice - _downPaymentAmount;
    } else {
      _downPaymentAmount = 0;
      _remainingAmount = totalPrice;
    }

    setState(() {});
  }

  Future<List<String>> _getUnavailableTimesForDate(String formattedDate) async {
    final bookings = await FirebaseFirestore.instance
        .collection('bookings')
        .where('items', arrayContains: {
      'name': widget.lapangan,
      'bookingDate': formattedDate,
    }).get();

    List<String> times = [];
    for (var doc in bookings.docs) {
      final items = doc['items'] as List<dynamic>;
      if (items.isNotEmpty) {
        for (var item in items) {
          if (item['name'] == widget.lapangan &&
              item['bookingDate'] == formattedDate) {
            final quantity = int.tryParse(item['quantity'].toString()) ?? 1;
            final startHour = int.parse(item['time'].split(":")[0]);
            for (int i = 0; i < quantity; i++) {
              times.add("${startHour + i}:00");
            }
          }
        }
      }
    }
    return times;
  }

  bool _isDurationAvailable(int duration) {
    final currentStartHour = int.parse(widget.selectedTime.split(":")[0]);
    for (int i = 0; i < duration; i++) {
      final timeToCheck = "${currentStartHour + i}:00";
      if (unavailableTimes.contains(timeToCheck)) {
        return false;
      }
    }
    return true;
  }

  void _fetchUnavailableTimes() async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    final times = await _getUnavailableTimesForDate(formattedDate);
    setState(() {
      unavailableTimes = times;
    });
  }

  void _confirmBooking() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi nama tim/nama pemesan!")),
      );
      return;
    }

    final currentStartHour = int.parse(widget.selectedTime.split(":")[0]);
    final maxAllowedQuantity = 22 - currentStartHour;
    if (bookingDuration > maxAllowedQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Tidak bisa booking pada jam tersebut karena melebihi jam tutup!"),
        ),
      );
      return;
    }

    if (!_isDurationAvailable(bookingDuration)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak bisa booking di jam tersebut!")),
      );
      return;
    }

    if (_paymentStatus == 'DP' && _downPaymentAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi jumlah DP yang dibayarkan!")),
      );
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (!userDoc.exists) throw Exception("User data not found");

      final userData = userDoc.data() as Map<String, dynamic>;
      userName = userData['name'];
      userPhone = userData['phone'] as String?;

      String? paymentProofUrl =
          _paymentStatus != 'Booking' ? await _uploadImage() : null;

      final selectedLapang = lapangData.firstWhere(
        (lapang) => lapang['name'] == widget.lapangan,
        orElse: () => {},
      );

      // Generate orderId
      final orderId =
          'ORDER-${DateTime.now().millisecondsSinceEpoch}-${user!.uid.substring(0, 5)}';

      final bookingData = {
        'orderId': orderId,
        'statusBooking': _paymentStatus,
        'userId': user!.uid,
        'userName': userName,
        'userPhone': userPhone ?? "",
        'totalAmount': totalPrice,
        'paymentStatus': _paymentStatus == 'Sudah Bayar' ? 'Lunas' : 'DP',
        'downPaymentAmount': _downPaymentAmount,
        'remainingAmount': _remainingAmount,
        'paymentProofUrl': paymentProofUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'items': [
          {
            'name': widget.lapangan,
            'bookingDate': DateFormat('yyyy-MM-dd').format(widget.selectedDate),
            'time': widget.selectedTime,
            'endTime': DateFormat('HH:mm').format(
              DateTime(
                widget.selectedDate.year,
                widget.selectedDate.month,
                widget.selectedDate.day,
                currentStartHour + bookingDuration,
              ),
            ),
            'quantity': bookingDuration.toString(),
            'isMember': isMember,
            'teamName': teamName,
            'usePhotographer': usePhotographer,
            'useReferee': useReferee,
            'price': int.parse(selectedLapang['price']),
            'imagePath': selectedLapang['image_path'],
            'lapangId': selectedLapang['id'],
            'dayOfWeek': DateFormat('EEEE').format(widget.selectedDate),
            'isRecurring': false,
          }
        ],
      };

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(orderId)
          .set(bookingData);

      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
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
        title: const Text('Booking Berhasil'),
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
            if (_paymentStatus == 'DP') ...[
              const SizedBox(height: 10),
              Text(
                'DP: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(_downPaymentAmount)}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                'Sisa: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(_remainingAmount)}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            ],
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

    final selectedLapang = lapangData.firstWhere(
      (lapang) => lapang['name'] == widget.lapangan,
      orElse: () => {},
    );

    if (selectedLapang.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking')),
        body: const Center(child: Text('Lapangan tidak ditemukan')),
      );
    }

    int pricePerHour = int.parse(selectedLapang['price']);
    if (isMember) pricePerHour = (pricePerHour * 0.6).round();
    _updateTotalPrice();

    final currentStartHour = int.parse(widget.selectedTime.split(":")[0]);
    final maxAllowedQuantity = 22 - currentStartHour;

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
                            ? "Harga (Diskon 40%): Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(pricePerHour)} / jam"
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Pilih Durasi Booking (jam):",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: List.generate(5, (index) {
                            final quantity = index + 1;
                            final bool isWithinClosingTime =
                                quantity <= maxAllowedQuantity;
                            final bool isQuantityAvailable =
                                _isDurationAvailable(quantity);

                            return ChoiceChip(
                              label: Text("$quantity Jam"),
                              selected: bookingDuration == quantity,
                              onSelected:
                                  isWithinClosingTime && isQuantityAvailable
                                      ? (bool selected) {
                                          setState(() {
                                            bookingDuration = quantity;
                                            _updateTotalPrice();
                                          });
                                        }
                                      : null,
                              selectedColor: Colors.grey.shade300,
                              backgroundColor: isQuantityAvailable
                                  ? Colors.grey.shade100
                                  : Colors.grey.shade300,
                              labelStyle: const TextStyle(
                                color: Colors.black,
                              ),
                            );
                          }),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Pembayaran:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Lunas'),
                                selected: _paymentStatus == 'Sudah Bayar',
                                onSelected: (selected) {
                                  setState(() {
                                    _paymentStatus = 'Sudah Bayar';
                                    _downPaymentController.text =
                                        totalPrice.toString();
                                    _downPaymentAmount = totalPrice;
                                    _remainingAmount = 0;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('DP'),
                                selected: _paymentStatus == 'DP',
                                onSelected: (selected) {
                                  setState(() {
                                    _paymentStatus = 'DP';
                                    _downPaymentController.text =
                                        _downPaymentAmount > 0
                                            ? _downPaymentAmount.toString()
                                            : '';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Tanpa DP'),
                                selected: _paymentStatus == 'Booking',
                                onSelected: (selected) {
                                  setState(() {
                                    _paymentStatus = 'Booking';
                                    _downPaymentController.text = '0';
                                    _downPaymentAmount = 0;
                                    _remainingAmount = totalPrice;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_paymentStatus == 'DP') ...[
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _downPaymentController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Jumlah DP',
                              hintText: 'Masukkan jumlah DP',
                              border: OutlineInputBorder(),
                              prefixText: 'Rp ',
                            ),
                            validator: (value) {
                              if (_paymentStatus == 'DP' &&
                                  (value == null || value.isEmpty)) {
                                return 'Harap isi jumlah DP';
                              }
                              final amount = int.tryParse(value ?? '0') ?? 0;
                              if (_paymentStatus == 'DP' && amount <= 0) {
                                return 'Jumlah DP harus lebih dari 0';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bukti Pembayaran:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _paymentStatus != 'Booking' ? _pickImage : null,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _imageFile != null
                          ? Image.file(_imageFile!, fit: BoxFit.cover)
                          : _webImage != null
                              ? Image.memory(_webImage!, fit: BoxFit.cover)
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, size: 40),
                                      Text('Tambah Bukti Pembayaran'),
                                    ],
                                  ),
                                ),
                    ),
                  ),
                  if (_paymentStatus == 'DP') ...[
                    const SizedBox(height: 10),
                    Text(
                      'Sisa Pembayaran: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(_remainingAmount)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
              if (widget.lapangan != "Gokart") ...[
                const SizedBox(height: 20),
                Column(
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
                  ],
                ),
              ],
              const SizedBox(height: 30),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.black,
                  ),
                  onPressed: _confirmBooking,
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
      onTap: () => onChanged(!value),
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
