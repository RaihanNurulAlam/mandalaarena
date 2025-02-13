// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Booking'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
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

              // Handle jika bookingData null (dokumen kosong atau error)
              if (bookingData == null) {
                return SizedBox.shrink(); // Atau tampilkan pesan error
              }
              final booking = bookingData;
              final bookingId = bookings[index].id;
              final lapangan =
                  booking['lapangan'] as String? ?? ''; // Gunakan ?? ''
              final tanggal = (booking['tanggal'] as Timestamp?)?.toDate() ??
                  DateTime.now(); // Handle null timestamp
              final jamMulai =
                  booking['jamMulai'] as String? ?? ''; // Gunakan ?? ''
              final jamSelesai =
                  booking['jamSelesai'] as String? ?? ''; // Gunakan ?? ''
              final status = booking['statusBooking'] as String? ??
                  'Pending'; // Gunakan ?? 'Pending'

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
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          // Tampilkan dialog konfirmasi
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
                                    content: Text('Gagal menghapus booking.')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
