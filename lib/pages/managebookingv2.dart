// // ignore_for_file: unnecessary_to_list_in_spreads

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:mandalaarenaapp/pages/booking_schedule_page.dart';
// import 'package:mandalaarenaapp/provider/cart.dart';
// import 'package:provider/provider.dart';

// class ManageBookingsPage extends StatefulWidget {
//   @override
//   _ManageBookingsPageState createState() => _ManageBookingsPageState();
// }

// class _ManageBookingsPageState extends State<ManageBookingsPage> {
//   String? selectedLapangan;
//   DateTime? selectedDate;
//   List<String> lapanganList = ['Semua Lapangan'];

//   @override
//   void initState() {
//     super.initState();
//     _fetchLapanganList();
//   }

//   Future<void> _fetchLapanganList() async {
//     final snapshot =
//         await FirebaseFirestore.instance.collection('bookings').get();
//     final lapanganSet = <String>{};

//     for (var doc in snapshot.docs) {
//       final data = doc.data();
//       if (data.containsKey('lapangan')) {
//         lapanganSet.add(data['lapangan']);
//       }
//     }

//     setState(() {
//       lapanganList = ['Semua Lapangan', ...lapanganSet.toList()];
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     int crossAxisCount;

//     // Pengkondisian jumlah kolom berdasarkan lebar layar
//     if (screenWidth > 1250) {
//       crossAxisCount = 3;
//     } else if (screenWidth > 800) {
//       crossAxisCount = 2;
//     } else {
//       crossAxisCount = 1;
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Kelola Booking'),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 20.0), // Padding kanan 20
//             child: IconButton(
//               icon: Icon(Icons.calendar_today), // Ikon untuk melihat jadwal
//               onPressed: () {
//                 // Navigasi ke halaman jadwal booking
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => BookingSchedulePage(),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: DropdownButtonFormField<String>(
//                     value: selectedLapangan,
//                     hint: Text('Pilih Lapangan'),
//                     items: lapanganList.map((String lapangan) {
//                       return DropdownMenuItem<String>(
//                         value: lapangan == 'Semua Lapangan' ? null : lapangan,
//                         child: Text(lapangan),
//                       );
//                     }).toList(),
//                     onChanged: (String? value) {
//                       setState(() {
//                         selectedLapangan = value;
//                       });
//                     },
//                   ),
//                 ),
//                 SizedBox(width: 8.0),
//                 IconButton(
//                   icon: Icon(Icons.calendar_today),
//                   onPressed: () async {
//                     final DateTime? pickedDate = await showDatePicker(
//                       context: context,
//                       initialDate: selectedDate ?? DateTime.now(),
//                       firstDate: DateTime(1900),
//                       lastDate: DateTime.now().add(Duration(days: 365)),
//                     );
//                     if (pickedDate != null) {
//                       setState(() {
//                         selectedDate = pickedDate;
//                       });
//                     }
//                   },
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('bookings')
//                   .where('lapangan',
//                       isEqualTo: selectedLapangan == 'Semua Lapangan'
//                           ? null
//                           : selectedLapangan)
//                   .where('tanggal',
//                       isEqualTo: selectedDate != null
//                           ? DateFormat('yyyy-MM-dd').format(selectedDate!)
//                           : null)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return Center(child: CircularProgressIndicator());
//                 }
//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return Center(child: Text('Tidak ada booking.'));
//                 }
//                 final bookings = snapshot.data!.docs;
//                 return GridView.builder(
//                   padding: EdgeInsets.all(20),
//                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: crossAxisCount,
//                     crossAxisSpacing: 20,
//                     mainAxisSpacing: 20,
//                     childAspectRatio: 1.5,
//                   ),
//                   itemCount: bookings.length,
//                   itemBuilder: (context, index) {
//                     final bookingData =
//                         bookings[index].data() as Map<String, dynamic>?;
//                     if (bookingData == null) {
//                       return SizedBox.shrink();
//                     }
//                     final booking = bookingData;
//                     final bookingId = bookings[index].id;
//                     final lapangan = booking['lapangan'] as String? ?? '';
//                     final tanggal = (booking['tanggal'] as String?) != null
//                         ? DateFormat('yyyy-MM-dd').parse(booking['tanggal'])
//                         : DateTime.now();
//                     final jamMulai = booking['jamMulai'] as String? ?? '';
//                     final jamSelesai = booking['jamSelesai'] as String? ?? '';
//                     final status =
//                         booking['statusBooking'] as String? ?? 'Pending';
//                     final namaPengguna =
//                         booking['namaPengguna'] as String? ?? 'Tidak Diketahui';
//                     final noWhatsapp = booking['noWhatsapp'] as String? ?? '-';
//                     final imagePath = booking['imagePath'] as String? ?? '';
//                     final teamName = booking['teamName'] as String? ?? '';
//                     final usePhotographer =
//                         booking['usePhotographer'] as bool? ?? false;
//                     final useReferee = booking['useReferee'] as bool? ?? false;
//                     final totalPrice = booking['totalPrice'] as int? ?? 0;

//                     return Card(
//                       margin: EdgeInsets.all(8),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Expanded(
//                             child: imagePath.isNotEmpty
//                                 ? Image.network(imagePath,
//                                     width: double.infinity,
//                                     height: 150,
//                                     fit: BoxFit.cover)
//                                 : Icon(Icons.image_not_supported, size: 50),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.only(
//                                 left: 20, top: 10, bottom: 10),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Text('Lapangan: $lapangan',
//                                               style: TextStyle(
//                                                   fontWeight: FontWeight.bold)),
//                                           Text(
//                                               'Tanggal: ${DateFormat('dd MMMM yyyy').format(tanggal)}'),
//                                           Text('Jam: $jamMulai - $jamSelesai'),
//                                           Text('Status: $status'),
//                                           Text('Nama: $namaPengguna'),
//                                           Text('No WhatsApp: $noWhatsapp'),
//                                           Text('Nama Tim/Atas Nama: $teamName'),
//                                           if (usePhotographer)
//                                             Text(
//                                                 'Layanan: Photographer (+Rp 200,000)'),
//                                           if (useReferee)
//                                             Text('Layanan: Wasit (+Rp 70,000)'),
//                                           Text(
//                                               'Total Harga: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(totalPrice)}'),
//                                         ],
//                                       ),
//                                     ),
//                                     IconButton(
//                                       icon: Icon(
//                                         CupertinoIcons.trash_circle,
//                                         color: Colors.black,
//                                       ),
//                                       onPressed: () async {
//                                         final shouldDelete =
//                                             await showDialog<bool>(
//                                           context: context,
//                                           builder: (context) => AlertDialog(
//                                             title: Text('Konfirmasi Hapus'),
//                                             content: Text(
//                                                 'Yakin ingin menghapus booking ini?'),
//                                             actions: [
//                                               TextButton(
//                                                 onPressed: () =>
//                                                     Navigator.of(context)
//                                                         .pop(false),
//                                                 style: TextButton.styleFrom(
//                                                   backgroundColor: Colors
//                                                       .black, // Warna hitam
//                                                   foregroundColor: Colors
//                                                       .white, // Font warna putih
//                                                 ),
//                                                 child: Text('Batal'),
//                                               ),
//                                               TextButton(
//                                                 onPressed: () =>
//                                                     Navigator.of(context)
//                                                         .pop(true),
//                                                 style: TextButton.styleFrom(
//                                                   backgroundColor: Colors
//                                                       .black, // Warna hitam
//                                                   foregroundColor: Colors
//                                                       .white, // Font warna putih
//                                                 ),
//                                                 child: Text('Hapus'),
//                                               ),
//                                             ],
//                                           ),
//                                         );

//                                         if (shouldDelete == true) {
//                                           try {
//                                             await FirebaseFirestore.instance
//                                                 .collection('bookings')
//                                                 .doc(bookingId)
//                                                 .delete();

//                                             final cart = Provider.of<Cart>(
//                                                 context,
//                                                 listen: false);
//                                             cart.removeItemByDocId(bookingId);

//                                             final User? user = FirebaseAuth
//                                                 .instance.currentUser;
//                                             if (user != null) {
//                                               await cart.loadCart(user
//                                                   .uid); // Pastikan cart diperbarui
//                                             }

//                                             ScaffoldMessenger.of(context)
//                                                 .showSnackBar(
//                                               SnackBar(
//                                                   content: Text(
//                                                       'Booking berhasil dihapus.')),
//                                             );
//                                           } catch (e) {
//                                             ScaffoldMessenger.of(context)
//                                                 .showSnackBar(
//                                               SnackBar(
//                                                   content: Text(
//                                                       'Gagal menghapus booking.')),
//                                             );
//                                           }
//                                         }
//                                       },
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/pages/booking_schedule_page.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:provider/provider.dart';

class ManageBookingsPage extends StatefulWidget {
  @override
  _ManageBookingsPageState createState() => _ManageBookingsPageState();
}

class _ManageBookingsPageState extends State<ManageBookingsPage> {
  String? selectedLapangan;
  DateTime? selectedDate;
  List<String> lapanganList = ['Semua Lapangan'];

  @override
  void initState() {
    super.initState();
    _fetchLapanganList();
  }

  Future<void> _fetchLapanganList() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('items', isNotEqualTo: null)
        .get();

    final lapanganSet = <String>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final items = data['items'] as List<dynamic>?;
      if (items != null && items.isNotEmpty) {
        final firstItem = items[0];
        if (firstItem['name'] != null) {
          lapanganSet.add(firstItem['name']);
        }
      }
    }

    setState(() {
      lapanganList = ['Semua Lapangan', ...lapanganSet.toList()];
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;

    if (screenWidth > 1250) {
      crossAxisCount = 3;
    } else if (screenWidth > 800) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Booking'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingSchedulePage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedLapangan,
                    hint: Text('Pilih Lapangan'),
                    items: lapanganList.map((String lapangan) {
                      return DropdownMenuItem<String>(
                        value: lapangan == 'Semua Lapangan' ? null : lapangan,
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
                SizedBox(width: 8.0),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Tidak ada booking.'));
                }

                final bookings = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final items = data['items'] as List<dynamic>? ?? [];

                  // Filter berdasarkan lapangan jika dipilih
                  if (selectedLapangan != null && items.isNotEmpty) {
                    final firstItem = items[0];
                    return firstItem['name'] == selectedLapangan;
                  }

                  // Filter berdasarkan tanggal jika dipilih
                  if (selectedDate != null && items.isNotEmpty) {
                    final firstItem = items[0];
                    final bookingDate = firstItem['bookingDate'] as String?;
                    if (bookingDate != null) {
                      final date = DateFormat('yyyy-MM-dd').parse(bookingDate);
                      return date.year == selectedDate!.year &&
                          date.month == selectedDate!.month &&
                          date.day == selectedDate!.day;
                    }
                  }

                  return true;
                }).toList();

                if (bookings.isEmpty) {
                  return Center(
                      child: Text(
                          'Tidak ada booking dengan filter yang dipilih.'));
                }

                return GridView.builder(
                  padding: EdgeInsets.all(20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final bookingData =
                        bookings[index].data() as Map<String, dynamic>;
                    final bookingId = bookings[index].id;
                    final items = bookingData['items'] as List<dynamic>? ?? [];
                    final firstItem = items.isNotEmpty ? items[0] : {};

                    // Extract data dari items
                    final lapangan =
                        firstItem['name'] ?? 'Lapangan Tidak Diketahui';
                    final bookingDate = firstItem['bookingDate'] ?? '';
                    final time = firstItem['time'] ?? '';
                    final status = bookingData['statusBooking'] ?? 'Pending';
                    final totalAmount = bookingData['totalAmount'] ?? 0;
                    final namaPengguna =
                        bookingData['userName'] ?? 'Tidak Diketahui';
                    final noWhatsapp = bookingData['userPhone'] ?? '-';
                    final imagePath = firstItem['imagePath'] ?? '';
                    final teamName = firstItem['teamName'] ?? '';
                    final usePhotographer =
                        firstItem['usePhotographer'] ?? false;
                    final useReferee = firstItem['useReferee'] ?? false;

                    Color statusColor = Colors.grey;
                    IconData statusIcon = Icons.access_time;

                    if (status.contains('Sudah Bayar')) {
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                    } else if (status.contains('Booking')) {
                      statusColor = Colors.blue;
                      statusIcon = Icons.calendar_today;
                    } else if (status.contains('Gagal') ||
                        status.contains('expire')) {
                      statusColor = Colors.red;
                      statusIcon = Icons.error;
                    }

                    return Card(
                      margin: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: imagePath.isNotEmpty
                                ? Image.network(
                                    imagePath,
                                    width: double.infinity,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(Icons.image_not_supported, size: 50),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 20, top: 10, bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Lapangan: $lapangan',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text('Tanggal: $bookingDate'),
                                          Text('Jam: $time'),
                                          Row(
                                            children: [
                                              Icon(statusIcon,
                                                  size: 16, color: statusColor),
                                              SizedBox(width: 4),
                                              Text(
                                                status,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text('Nama: $namaPengguna'),
                                          Text('No WhatsApp: $noWhatsapp'),
                                          if (teamName.isNotEmpty)
                                            Text('Atas Nama: $teamName'),
                                          if (usePhotographer)
                                            Text('Photographer: Rp 200,000'),
                                          if (useReferee)
                                            Text('Wasit: Rp 70,000'),
                                          Text(
                                            'Total Harga: Rp ${NumberFormat.currency(locale: 'id', symbol: '').format(totalAmount)}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        CupertinoIcons.trash_circle,
                                        color: Colors.black,
                                      ),
                                      onPressed: () async {
                                        final shouldDelete =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('Konfirmasi Hapus'),
                                            content: Text(
                                                'Yakin ingin menghapus booking ini?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                style: TextButton.styleFrom(
                                                  backgroundColor: Colors.black,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: Text('Batal'),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true),
                                                style: TextButton.styleFrom(
                                                  backgroundColor: Colors.black,
                                                  foregroundColor: Colors.white,
                                                ),
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

                                            final cart = Provider.of<Cart>(
                                                context,
                                                listen: false);
                                            cart.removeItemByDocId(bookingId);

                                            final User? user = FirebaseAuth
                                                .instance.currentUser;
                                            if (user != null) {
                                              await cart.loadCart(user.uid);
                                            }

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Booking berhasil dihapus.')),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Gagal menghapus booking.')),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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
