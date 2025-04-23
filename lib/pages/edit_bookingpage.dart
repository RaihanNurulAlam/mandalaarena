import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class EditBookingPage extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> initialData;
  final String lapangan;

  const EditBookingPage({
    super.key,
    required this.bookingId,
    required this.initialData,
    required this.lapangan,
  });

  @override
  _EditBookingPageState createState() => _EditBookingPageState();
}

class _EditBookingPageState extends State<EditBookingPage> {
  late int originalTotalAmount;
  late int totalAmount;
  late int bookingDuration;
  late bool usePhotographer;
  late bool useReferee;
  late String teamName;
  late String userName;
  late String userPhone;
  final _formKey = GlobalKey<FormState>();
  Uint8List? _webImage;
  File? _imageFile;
  late String _paymentStatus;
  late int _downPaymentAmount;
  late int _remainingAmount;
  final TextEditingController _downPaymentController = TextEditingController();
  String? _paymentProofUrl;
  late String lapangan;
  late String bookingDate;
  late String time;
  late String endTime;
  late int basePricePerHour;
  late int photographerPrice = 200000;
  late int refereePrice = 70000;

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
  void didChangeDependencies() {
    super.didChangeDependencies();

    final items = widget.initialData['items'] as List<dynamic>? ?? [];
    final firstItem = items.isNotEmpty ? items[0] : {};

    setState(() {
      lapangan = firstItem['name'] ?? "";
      bookingDuration =
          int.tryParse(firstItem['quantity']?.toString() ?? '1') ?? 1;
      usePhotographer = firstItem['usePhotographer'] ?? false;
      useReferee = firstItem['useReferee'] ?? false;
      teamName = firstItem['teamName'] ?? "";
      userName = widget.initialData['userName'] ?? "";
      userPhone = widget.initialData['userPhone'] ?? "";
      bookingDate = firstItem['bookingDate'] ?? "";
      time = firstItem['time'] ?? "";
      endTime = firstItem['endTime'] ?? "";

      originalTotalAmount = widget.initialData['totalAmount'] ?? 0;
      totalAmount = originalTotalAmount;
      _paymentStatus = widget.initialData['statusBooking'] ?? 'Booking';
      _downPaymentAmount = widget.initialData['downPaymentAmount'] ?? 0;
      _remainingAmount = widget.initialData['remainingAmount'] ??
          totalAmount - _downPaymentAmount;
      _downPaymentController.text = _downPaymentAmount.toString();
      _paymentProofUrl = widget.initialData['paymentProofUrl'];

      basePricePerHour = (originalTotalAmount -
              (usePhotographer ? photographerPrice : 0) -
              (useReferee ? refereePrice : 0)) ~/
          bookingDuration;
    });
    if (firstItem == null || firstItem.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Data booking tidak valid.")),
      );
      Navigator.of(context).pop();
      return;
    }
  }

  void _updatePaymentInfo() {
    setState(() {
      _downPaymentAmount = int.tryParse(_downPaymentController.text) ?? 0;
      _remainingAmount = totalAmount - _downPaymentAmount;
    });
  }

  void _updateTotalPrice() {
    setState(() {
      // Start with base price
      int newTotal = basePricePerHour * bookingDuration;

      // Add services if selected
      if (usePhotographer) newTotal += photographerPrice;
      if (useReferee) newTotal += refereePrice;

      totalAmount = newTotal;

      // Update remaining amount
      if (_paymentStatus == 'DP') {
        _remainingAmount = totalAmount - _downPaymentAmount;
      } else if (_paymentStatus == 'Booking') {
        _remainingAmount = totalAmount;
      }
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

  Future<void> _deletePaymentProof() async {
    setState(() {
      _imageFile = null;
      _webImage = null;
      _paymentProofUrl = null;
    });
  }

  Future<String?> _uploadImage() async {
    try {
      if (_imageFile == null && _webImage == null) return _paymentProofUrl;

      String fileName =
          'buktipembayaran/${DateTime.now().millisecondsSinceEpoch}.jpg';
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
      return _paymentProofUrl;
    }
  }

  Future<void> _updateBooking() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi semua field yang diperlukan!")),
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
      String? newPaymentProofUrl = await _uploadImage();

      // Ambil email pengguna dari Firestore atau sumber lain
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.initialData['userId'])
          .get();

      if (!userDoc.exists) throw Exception("User data not found");

      final userEmail = userDoc['email'] ?? 'unknown';

      final selectedLapang = lapangData.firstWhere(
        (lapang) => lapang['name'] == widget.lapangan,
        orElse: () => {},
      );

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'userName': userName,
        'userPhone': userPhone,
        'statusBooking': _paymentStatus,
        'downPaymentAmount':
            _paymentStatus == 'Booking' ? 0 : _downPaymentAmount,
        'remainingAmount': _paymentStatus == 'Sudah Bayar'
            ? 0
            : _paymentStatus == 'Booking'
                ? totalAmount
                : totalAmount - _downPaymentAmount,
        'paymentProofUrl':
            _paymentStatus == 'Booking' ? null : newPaymentProofUrl,
        'totalAmount': totalAmount,
        'updatedAt': FieldValue.serverTimestamp(),
        'items': [
          {
            'name': lapangan,
            'bookingDate': bookingDate,
            'time': time,
            'endTime': endTime,
            'quantity': bookingDuration.toString(),
            'teamName': teamName,
            'usePhotographer': usePhotographer,
            'useReferee': useReferee,
            'price': basePricePerHour,
            'imagePath': selectedLapang['image_path'],
          }
        ],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking berhasil diperbarui!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
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

  @override
  Widget build(BuildContext context) {
    final isGokart = lapangan == 'Gokart';

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Booking - $lapangan'),
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
                        lapangan,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tanggal: ${DateFormat('EEEE, dd MMMM yyyy').format(DateTime.parse(bookingDate))}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Jam: $time - $endTime',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Harga Dasar: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(basePricePerHour)}/jam',
                        style: const TextStyle(fontSize: 16),
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
                      initialValue: teamName,
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
                            return ChoiceChip(
                              label: Text("$quantity Jam"),
                              selected: bookingDuration == quantity,
                              onSelected: (bool selected) {
                                setState(() {
                                  bookingDuration = quantity;
                                  _updateTotalPrice();
                                });
                              },
                              selectedColor: Colors.grey.shade300,
                              backgroundColor: Colors.grey.shade100,
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
                                        totalAmount.toString();
                                    _downPaymentAmount = totalAmount;
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
                                    _remainingAmount = totalAmount;
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
                            onChanged: (value) => _updatePaymentInfo(),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Bukti Pembayaran:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_paymentStatus != 'Booking' &&
                          (_paymentProofUrl != null ||
                              _imageFile != null ||
                              _webImage != null))
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: _deletePaymentProof,
                          tooltip: 'Hapus Bukti Pembayaran',
                        ),
                    ],
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
                              : _paymentProofUrl != null
                                  ? Image.network(
                                      _paymentProofUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error,
                                              stackTrace) =>
                                          const Center(
                                              child:
                                                  Text('Gagal memuat gambar')),
                                    )
                                  : const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
              if (!isGokart) ...[
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
                      onChanged: (value) {
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
                      onChanged: (value) {
                        setState(() {
                          useReferee = value;
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
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Harga Dasar:",
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(basePricePerHour * bookingDuration)}",
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (usePhotographer) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Photographer:",
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(photographerPrice)}",
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (useReferee) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Wasit:",
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(refereePrice)}",
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 20),
                      Row(
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
                            "Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(totalAmount)}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                  onPressed: _updateBooking,
                  child: const Text(
                    "Simpan Perubahan",
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
}
