// edit_booking_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  late int totalPrice;
  late int bookingDuration;
  late bool usePhotographer;
  late bool useReferee;
  late String teamName;
  final _formKey = GlobalKey<FormState>();
  Uint8List? _webImage;
  File? _imageFile;
  late bool _isPaidFull;
  late int _downPaymentAmount;
  final TextEditingController _downPaymentController = TextEditingController();
  String? _paymentProofUrl;

  @override
  void initState() {
    super.initState();
    // Initialize from initialData
    totalPrice = widget.initialData['totalPrice'] ?? 0;
    bookingDuration =
        int.tryParse(widget.initialData['duration'].toString()) ?? 1;
    usePhotographer = widget.initialData['usePhotographer'] ?? false;
    useReferee = widget.initialData['useReferee'] ?? false;
    teamName = widget.initialData['teamName'] ?? "";
    _isPaidFull = widget.initialData['paymentStatus'] == 'Lunas';
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

  Future<String?> _uploadImage() async {
    try {
      if (_imageFile == null && _webImage == null) return _paymentProofUrl;

      String fileName =
          'buktipembayaran/${FirebaseAuth.instance.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
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

  void _updateTotalPrice() {
    // Calculate based on current selections
    // This should match your booking page logic
    // ...
  }

  Future<void> _updateBooking() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi nama tim/nama pemesan!")),
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

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'teamName': teamName,
        'usePhotographer': usePhotographer,
        'useReferee': useReferee,
        'duration': bookingDuration.toString(),
        'paymentStatus': _isPaidFull ? 'Lunas' : 'DP',
        'downPaymentAmount': _isPaidFull ? totalPrice : _downPaymentAmount,
        'remainingAmount': _isPaidFull ? 0 : totalPrice - _downPaymentAmount,
        'paymentProofUrl': newPaymentProofUrl,
        'totalPrice': totalPrice,
        'updatedAt': FieldValue.serverTimestamp(),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Booking'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _updateBooking,
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
                  subtitle: Text(widget.initialData['lapangan'] ?? '-'),
                ),
                ListTile(
                  title: Text('Tanggal'),
                  subtitle: Text(widget.initialData['tanggal'] ?? '-'),
                ),
                ListTile(
                  title: Text('Jam'),
                  subtitle: Text(
                      '${widget.initialData['jamMulai']} - ${widget.initialData['jamSelesai']}'),
                ),

                // Editable fields
                const SizedBox(height: 20),
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
                      _updateTotalPrice();
                    });
                  },
                ),

                if (widget.initialData['lapangan'] != "Gokart") ...[
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
                        _updateTotalPrice();
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Wasit (Rp 70,000)'),
                    value: useReferee,
                    onChanged: (value) {
                      setState(() {
                        useReferee = value;
                        _updateTotalPrice();
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
                            _downPaymentController.text = totalPrice.toString();
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
                      return null;
                    },
                    onChanged: (value) => _updateDownPayment(),
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
                if (!_isPaidFull) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Sisa Pembayaran: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(_isPaidFull ? 0 : totalPrice - _downPaymentAmount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
