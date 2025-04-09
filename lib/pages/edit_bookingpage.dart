// ignore_for_file: use_super_parameters

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

  const EditBookingPage({
    Key? key,
    required this.bookingId,
    required this.initialData,
  }) : super(key: key);

  @override
  _EditBookingPageState createState() => _EditBookingPageState();
}

class _EditBookingPageState extends State<EditBookingPage> {
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
  late bool _isPaidFull;
  late int _downPaymentAmount;
  final TextEditingController _downPaymentController = TextEditingController();
  String? _paymentProofUrl;
  late String lapangan;
  late String bookingDate;
  late String time;

  @override
  void initState() {
    super.initState();
    // Extract data from items array
    final items = widget.initialData['items'] as List<dynamic>? ?? [];
    final firstItem = items.isNotEmpty ? items[0] : {};

    // Initialize values
    totalAmount = widget.initialData['totalAmount'] ?? 0;
    bookingDuration =
        int.tryParse(firstItem['duration']?.toString() ?? '1') ?? 1;
    usePhotographer = firstItem['usePhotographer'] ?? false;
    useReferee = firstItem['useReferee'] ?? false;
    teamName = firstItem['teamName'] ?? "";
    userName = widget.initialData['userName'] ?? "";
    userPhone = widget.initialData['userPhone'] ?? "";
    lapangan = firstItem['name'] ?? "";
    bookingDate = firstItem['bookingDate'] ?? "";
    time = firstItem['time'] ?? "";

    // Payment information
    _isPaidFull =
        widget.initialData['statusBooking']?.contains('Sudah Bayar') ?? false;
    _downPaymentAmount = widget.initialData['downPaymentAmount'] ?? 0;
    _downPaymentController.text = _downPaymentAmount.toString();
    _paymentProofUrl = widget.initialData['paymentProofUrl'];
  }

  void _updateDownPayment() {
    setState(() {
      _downPaymentAmount = int.tryParse(_downPaymentController.text) ?? 0;
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

  Future<void> _deleteImage() async {
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

  void _calculateTotalPrice() {
    int basePrice = 0;

    // Determine base price based on lapangan and duration
    // This should match your pricing logic from the booking page
    if (lapangan.contains('Minisoccer')) {
      basePrice = 150000 * bookingDuration;
    } else if (lapangan.contains('Basket')) {
      basePrice = 120000 * bookingDuration;
    } else if (lapangan == 'Gokart') {
      basePrice = 100000 * bookingDuration;
    }

    // Add services if not Gokart
    if (lapangan != 'Gokart') {
      if (usePhotographer) basePrice += 200000;
      if (useReferee) basePrice += 70000;
    }

    setState(() {
      totalAmount = basePrice;
      if (_isPaidFull) {
        _downPaymentController.text = basePrice.toString();
        _downPaymentAmount = basePrice;
      }
    });
  }

  Future<void> _updateBooking() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi semua field yang diperlukan!")),
      );
      return;
    }

    if (!_isPaidFull && _downPaymentAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi jumlah DP yang dibayarkan!")),
      );
      return;
    }

    try {
      String? newPaymentProofUrl = await _uploadImage();

      // Update the booking document
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'userName': userName,
        'userPhone': userPhone,
        'statusBooking': _isPaidFull ? 'Sudah Bayar' : 'DP',
        'downPaymentAmount': _downPaymentAmount,
        'remainingAmount': _isPaidFull ? 0 : totalAmount - _downPaymentAmount,
        'paymentProofUrl': newPaymentProofUrl,
        'totalAmount': totalAmount,
        'updatedAt': FieldValue.serverTimestamp(),
        'items': FieldValue.arrayUnion([
          {
            'name': lapangan,
            'bookingDate': bookingDate,
            'time': time,
            'duration': bookingDuration.toString(),
            'teamName': teamName,
            'usePhotographer': lapangan != 'Gokart' ? usePhotographer : false,
            'useReferee': lapangan != 'Gokart' ? useReferee : false,
            'price': totalAmount,
          }
        ]),
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

  @override
  Widget build(BuildContext context) {
    final isGokart = lapangan == 'Gokart';

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Booking - Admin'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: IconButton(
              icon: Icon(Icons.save),
              onPressed: _updateBooking,
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteImage,
            tooltip: 'Hapus Bukti Pembayaran',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display booking information (read-only)
                ListTile(
                  title: Text('Lapangan'),
                  subtitle: Text(lapangan),
                ),
                ListTile(
                  title: Text('Tanggal'),
                  subtitle: Text(bookingDate),
                ),
                ListTile(
                  title: Text('Jam'),
                  subtitle: Text(time),
                ),

                // Editable fields
                const SizedBox(height: 20),
                const Text(
                  "Informasi Pemesan:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: userName,
                  decoration: InputDecoration(
                    labelText: "Nama Pemesan",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Nama pemesan wajib diisi!";
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      userName = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: userPhone,
                  decoration: InputDecoration(
                    labelText: "No. WhatsApp",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Nomor WhatsApp wajib diisi!";
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      userPhone = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: teamName,
                  decoration: InputDecoration(
                    labelText: "Nama Tim / Atas Nama",
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

                const SizedBox(height: 20),
                const Text(
                  "Durasi Booking (jam):",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: bookingDuration,
                  items: List.generate(5, (index) => index + 1)
                      .map((duration) => DropdownMenuItem<int>(
                            value: duration,
                            child: Text('$duration Jam'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      bookingDuration = value!;
                      _calculateTotalPrice();
                    });
                  },
                ),

                if (!isGokart) ...[
                  const SizedBox(height: 20),
                  const Text(
                    "Tambahan Layanan:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Photographer (Rp 200,000)'),
                    value: usePhotographer,
                    onChanged: (value) {
                      setState(() {
                        usePhotographer = value;
                        _calculateTotalPrice();
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Wasit (Rp 70,000)'),
                    value: useReferee,
                    onChanged: (value) {
                      setState(() {
                        useReferee = value;
                        _calculateTotalPrice();
                      });
                    },
                  ),
                ],

                const SizedBox(height: 20),
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
                        selected: _isPaidFull,
                        onSelected: (selected) {
                          setState(() {
                            _isPaidFull = true;
                            _downPaymentController.text =
                                totalAmount.toString();
                            _downPaymentAmount = totalAmount;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('DP'),
                        selected: !_isPaidFull,
                        onSelected: (selected) {
                          setState(() {
                            _isPaidFull = false;
                            _downPaymentController.text = '';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (!_isPaidFull) ...[
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
                      if (!_isPaidFull && (value == null || value.isEmpty)) {
                        return 'Harap isi jumlah DP';
                      }
                      final amount = int.tryParse(value ?? '0') ?? 0;
                      if (!_isPaidFull && amount <= 0) {
                        return 'Jumlah DP harus lebih dari 0';
                      }
                      if (amount > totalAmount) {
                        return 'DP tidak boleh melebihi total harga';
                      }
                      return null;
                    },
                    onChanged: (value) => _updateDownPayment(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sisa Pembayaran: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(totalAmount - _downPaymentAmount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
                if (_isPaidFull) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Jumlah DP: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(_downPaymentAmount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                const Text(
                  "Bukti Pembayaran:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickImage,
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
                                            child: Text('Gagal memuat gambar')),
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
                          "Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(totalAmount)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
