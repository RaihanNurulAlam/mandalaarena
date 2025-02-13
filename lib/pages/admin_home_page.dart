// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/widgets/drawer_widget.dart';
import 'package:mandalaarenaapp/pages/sparring_team_page.dart';

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Halaman Admin'),
      ),
      drawer: DrawerWidget(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Selamat Datang, Admin!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SparringTeamPage(),
                  ),
                );
              },
              child: Text('Kelola Tim Sparring'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageBookingsPage(),
                  ),
                );
              },
              child: Text('Kelola Booking Lapangan'),
            ),
          ],
        ),
      ),
    );
  }
}

class ManageBookingsPage extends StatefulWidget {
  @override
  _ManageBookingsPageState createState() => _ManageBookingsPageState();
}

class _ManageBookingsPageState extends State<ManageBookingsPage> {
  String? selectedLapangan;
  DateTime? selectedDate;
  List<String> lapanganList = [];

  @override
  void initState() {
    super.initState();
    _fetchLapanganList();
  }

  Future<void> _fetchLapanganList() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('bookings').get();
    final lapanganSet = <String>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('lapangan')) {
        lapanganSet.add(data['lapangan']);
      }
    }

    setState(() {
      lapanganList = lapanganSet.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Booking'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: selectedLapangan,
              hint: Text('Pilih Lapangan'),
              items: lapanganList.map((String lapangan) {
                return DropdownMenuItem<String>(
                  value: lapangan,
                  child: Text(lapangan),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  selectedLapangan = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (pickedDate != null) {
                  setState(() {
                    selectedDate = pickedDate;
                  });
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Pilih Tanggal',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  selectedDate != null
                      ? DateFormat('dd MMMM yyyy').format(selectedDate!)
                      : 'Pilih Tanggal',
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('lapangan', isEqualTo: selectedLapangan)
                  .where('tanggal',
                      isEqualTo: selectedDate != null
                          ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                          : null)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Tidak ada booking.'));
                }
                final bookings = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final bookingData =
                        bookings[index].data() as Map<String, dynamic>?;
                    if (bookingData == null) {
                      return SizedBox.shrink();
                    }
                    final booking = bookingData;
                    final bookingId = bookings[index].id;
                    final lapangan = booking['lapangan'] as String? ?? '';
                    final tanggal = (booking['tanggal'] as String?) != null
                        ? DateFormat('yyyy-MM-dd').parse(booking['tanggal'])
                        : DateTime.now();
                    final jamMulai = booking['jamMulai'] as String? ?? '';
                    final jamSelesai = booking['jamSelesai'] as String? ?? '';
                    final status =
                        booking['statusBooking'] as String? ?? 'Pending';
                    final namaPengguna =
                        booking['namaPengguna'] as String? ?? 'Tidak Diketahui';
                    final noWhatsapp = booking['noWhatsapp'] as String? ?? '-';
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('Lapangan: $lapangan'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Tanggal: ${DateFormat('dd MMMM yyyy').format(tanggal)}'),
                            Text('Jam: $jamMulai - $jamSelesai'),
                            Text('Status: $status'),
                            Text('Nama: $namaPengguna'),
                            Text('No WhatsApp: $noWhatsapp'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final shouldDelete = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Konfirmasi Hapus'),
                                content:
                                    Text('Yakin ingin menghapus booking ini?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: Text('Hapus'),
                                  ),
                                ],
                              ),
                            );
                            if (shouldDelete == true) {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('bookings')
                                    .doc(bookingId)
                                    .delete();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Gagal menghapus booking.')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
