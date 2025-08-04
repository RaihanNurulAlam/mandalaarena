// ignore_for_file: unnecessary_to_list_in_spreads, avoid_print, sort_child_properties_last, use_super_parameters, curly_braces_in_flow_control_structures

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandalaarenaapp/pages/admin_add_booking_page.dart';
import 'package:mandalaarenaapp/pages/edit_bookingpage.dart';

class ManageBookingsPage extends StatefulWidget {
  const ManageBookingsPage({super.key});
  @override
  _ManageBookingsPageState createState() => _ManageBookingsPageState();
}

enum PaymentStatusFilter { semua, sudahBayar, booking, dp }

class _ManageBookingsPageState extends State<ManageBookingsPage> {
  String? selectedLapangan;
  String? selectedMonthYear;
  DateTime? selectedDate;
  PaymentStatusFilter _selectedPaymentStatus = PaymentStatusFilter.semua;

  List<String> lapanganList = ['Semua Lapangan'];
  List<String> availableMonths = ['Semua Bulan'];
  bool _isFetchingMonths = false;

  @override
  void initState() {
    super.initState();
    _fetchLapanganList();
    Intl.defaultLocale = 'id_ID';
  }

  // --- FUNGSI LOGIKA (TIDAK ADA PERUBAHAN) ---
  Future<void> _fetchLapanganList() async {
    if (!mounted) return;
    final snapshot =
        await FirebaseFirestore.instance.collection('bookings').get();
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
    final sortedLapangan = lapanganSet.toList()..sort();
    if (mounted) {
      setState(() {
        lapanganList = ['Semua Lapangan', ...sortedLapangan];
      });
    }
  }

  Future<void> _updateAvailableMonths(String? lapanganName) async {
    if (!mounted) return;
    setState(() {
      selectedMonthYear = null;
      selectedDate = null;
      _isFetchingMonths = true;
      availableMonths = [];
    });

    if (lapanganName == null || lapanganName == 'Semua Lapangan') {
      if (mounted) {
        setState(() {
          availableMonths = ['Semua Bulan'];
          _isFetchingMonths = false;
        });
      }
      return;
    }

    try {
      final monthSet = <String>{};
      final query = FirebaseFirestore.instance
          .collection('bookings')
          .where('items.0.name', isEqualTo: lapanganName);

      final snapshot = await query.get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final items = data['items'] as List<dynamic>?;
        if (items != null && items.isNotEmpty) {
          final bookingDateStr = items[0]['bookingDate'] as String?;
          if (bookingDateStr != null && bookingDateStr.length >= 7) {
            monthSet.add(bookingDateStr.substring(0, 7));
          }
        }
      }

      final sortedMonths = monthSet.toList()..sort((a, b) => b.compareTo(a));
      if (mounted) {
        setState(() {
          availableMonths = ['Semua Bulan', ...sortedMonths];
        });
      }
    } catch (e) {
      print("Error fetching months: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingMonths = false;
        });
      }
    }
  }

  String _formatMonthYear(String monthYear) {
    if (monthYear == 'Semua Bulan' || monthYear == 'Gagal memuat') {
      return monthYear;
    }
    try {
      final date = DateFormat('yyyy-MM').parse(monthYear);
      return DateFormat.yMMMM().format(date);
    } catch (e) {
      return monthYear;
    }
  }

  void _clearFilters() {
    setState(() {
      selectedLapangan = null;
      selectedMonthYear = null;
      selectedDate = null;
      _selectedPaymentStatus = PaymentStatusFilter.semua;
      availableMonths = ['Semua Bulan'];
    });
  }

  Future<void> _deleteBooking(String bookingId) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus data booking ini secara permanen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
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
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking berhasil dihapus.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print("Error deleting booking: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Booking'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            tooltip: 'Tambah Booking Manual',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminAddBookingPage()),
              );
            },
          ),
          IconButton(
            tooltip: 'Hapus Filter',
            icon: const Icon(Icons.refresh),
            onPressed: _clearFilters,
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _buildFilterWidgets(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Terjadi kesalahan: ${snapshot.error}'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text('Tidak ada data booking.'));
                    }

                    final filteredBookings = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final items = data['items'] as List<dynamic>? ?? [];
                      if (items.isEmpty) return false;
                      final bookingDateStr =
                          items[0]['bookingDate'] as String? ?? '';

                      if (selectedLapangan != null &&
                          items[0]['name'] != selectedLapangan) return false;
                      if (selectedMonthYear != null &&
                          !bookingDateStr.startsWith(selectedMonthYear!))
                        return false;
                      if (selectedDate != null) {
                        try {
                          final bookingDate =
                              DateFormat('yyyy-MM-dd').parse(bookingDateStr);
                          if (bookingDate.year != selectedDate!.year ||
                              bookingDate.month != selectedDate!.month ||
                              bookingDate.day != selectedDate!.day)
                            return false;
                        } catch (e) {
                          return false;
                        }
                      }
                      if (_selectedPaymentStatus != PaymentStatusFilter.semua) {
                        final status = data['statusBooking'] as String? ?? '';
                        if (_selectedPaymentStatus ==
                                PaymentStatusFilter.sudahBayar &&
                            !status.contains('Sudah Bayar')) return false;
                        if (_selectedPaymentStatus ==
                                PaymentStatusFilter.booking &&
                            !status.contains('Booking')) return false;
                        if (_selectedPaymentStatus == PaymentStatusFilter.dp &&
                            !status.toUpperCase().contains('DP')) return false;
                      }
                      return true;
                    }).toList();

                    if (filteredBookings.isEmpty) {
                      return const Center(
                        child: Text(
                            'Tidak ada booking dengan filter yang dipilih.'),
                      );
                    }

                    double totalIncome = 0.0;
                    for (var doc in filteredBookings) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['statusBooking']?.toString() ?? '';
                      if (status.contains('Sudah Bayar')) {
                        totalIncome +=
                            (data['totalAmount'] as num? ?? 0).toDouble();
                      } else if (status.toUpperCase().contains('DP')) {
                        totalIncome +=
                            (data['downPaymentAmount'] as num? ?? 0).toDouble();
                      }
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount = 1;
                              if (constraints.maxWidth > 1200) {
                                crossAxisCount = 4;
                              } else if (constraints.maxWidth > 900) {
                                crossAxisCount = 3;
                              } else if (constraints.maxWidth > 600) {
                                crossAxisCount = 2;
                              }

                              return GridView.builder(
                                padding: const EdgeInsets.all(12),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  // --- PERUBAHAN DI SINI ---
                                  childAspectRatio:
                                      crossAxisCount == 1 ? (3 / 2) : (3 / 2.3),
                                ),
                                itemCount: filteredBookings.length,
                                itemBuilder: (context, index) {
                                  final doc = filteredBookings[index];
                                  return _BookingCard(
                                    bookingData:
                                        doc.data() as Map<String, dynamic>,
                                    bookingId: doc.id,
                                    onTap: () => _showBookingDetails(
                                        context,
                                        doc.data() as Map<String, dynamic>,
                                        doc.id),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        _buildTotalIncomeCard(totalIncome),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingDetails(BuildContext context,
      Map<String, dynamic> bookingData, String bookingId) {
    final items = bookingData['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return;

    final firstItem = items[0] as Map<String, dynamic>;
    final lapangan = firstItem['name'] ?? 'N/A';
    final bookingDate = firstItem['bookingDate'] ?? 'N/A';
    final formattedDate =
        DateFormat('EEEE, dd MMMM yyyy').format(DateTime.parse(bookingDate));
    final time = firstItem['time'] ?? 'N/A';
    final duration = firstItem['quantity'] ?? '1';
    final status = bookingData['statusBooking'] ?? 'Pending';
    final totalAmount = bookingData['totalAmount'] ?? 0;
    final dpAmount = bookingData['downPaymentAmount'] ?? 0;
    final remainingAmount = bookingData['remainingAmount'] ?? 0;
    final userName = bookingData['userName'] ?? 'N/A';
    final userPhone = bookingData['userPhone'] ?? '-';
    final teamName = firstItem['teamName'] ?? '';
    final usePhotographer = firstItem['usePhotographer'] ?? false;
    final useReferee = firstItem['useReferee'] ?? false;
    final isMember = bookingData['isMember'] ?? false;
    final useIceBath = firstItem['useIceBath'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      children: [
                        Text('Detail Booking',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        _buildDetailRow(context, Icons.sports_basketball,
                            'Lapangan', lapangan),
                        _buildDetailRow(context, Icons.calendar_today,
                            'Tanggal', formattedDate),
                        _buildDetailRow(context, Icons.access_time_filled,
                            'Jam', '$time ($duration jam)'),
                        const Divider(height: 30),
                        _buildDetailRow(
                            context, Icons.person, 'Nama Pemesan', userName),
                        _buildDetailRow(
                            context, Icons.phone, 'No. WhatsApp', userPhone),
                        if (teamName.isNotEmpty)
                          _buildDetailRow(
                              context, Icons.group, 'Nama Tim', teamName),
                        if (isMember)
                          _buildDetailRow(context, CupertinoIcons.star_fill,
                              'Status User', 'Member',
                              valueColor: Colors.purple.shade700),
                        const Divider(height: 30),
                        if (usePhotographer)
                          _buildDetailRow(
                              context, Icons.camera_alt, 'Photographer', 'Ya'),
                        if (useReferee)
                          _buildDetailRow(context, Icons.sports, 'Wasit', 'Ya'),
                        if (useIceBath)
                          _buildDetailRow(
                              context, Icons.ac_unit, 'Ice Bath', 'Ya'),
                        if (usePhotographer || useReferee || useIceBath)
                          const Divider(height: 30),
                        _buildDetailRow(
                            context, Icons.payment, 'Status Pembayaran', status,
                            valueColor: status.contains('Sudah Bayar')
                                ? Colors.green
                                : (status.toUpperCase().contains('DP')
                                    ? Colors.orange.shade800
                                    : Colors.blue)),
                        _buildDetailRow(context, Icons.money, 'Total Harga',
                            'Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(totalAmount)}'),
                        if (status.toUpperCase().contains('DP')) ...[
                          _buildDetailRow(
                              context,
                              CupertinoIcons.arrow_down_right_square_fill,
                              'Jumlah DP',
                              'Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(dpAmount)}',
                              valueColor: Colors.green),
                          _buildDetailRow(
                              context,
                              CupertinoIcons.arrow_right_square_fill,
                              'Sisa Bayar',
                              'Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(remainingAmount)}',
                              valueColor: Colors.red),
                        ],
                        _buildPaymentProofSection(bookingData),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                          tooltip: 'Hapus Booking',
                          onPressed: () => _deleteBooking(bookingId),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Tutup'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditBookingPage(
                                    bookingId: bookingId,
                                    initialData: bookingData,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50)),
                              backgroundColor: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentProofSection(Map<String, dynamic> bookingData) {
    final paymentProofUrl = bookingData['paymentProofUrl'] as String?;
    if (paymentProofUrl == null || paymentProofUrl.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 30),
        _buildDetailRow(context, Icons.receipt_long, 'Bukti Pembayaran', ''),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            paymentProofUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Expanded(
              child:
                  Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.black87,
                ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalIncomeCard(double totalIncome) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      elevation: 4,
      child: ListTile(
        leading:
            const Icon(Icons.monetization_on, color: Colors.green, size: 36),
        title: const Text(
          'Total Pendapatan Diterima (Sesuai Filter)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          NumberFormat.currency(
                  locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
              .format(totalIncome),
          style: const TextStyle(
            color: Colors.green,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterWidgets() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    _buildLapanganDropdown(),
                    const SizedBox(height: 12),
                    _buildMonthAndDateFilter(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildLapanganDropdown()),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: _buildMonthAndDateFilter()),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<PaymentStatusFilter>(
              segments: const <ButtonSegment<PaymentStatusFilter>>[
                ButtonSegment(
                    value: PaymentStatusFilter.semua,
                    label: Text('Semua'),
                    icon: Icon(Icons.list)),
                ButtonSegment(
                    value: PaymentStatusFilter.sudahBayar,
                    label: Text('Lunas'),
                    icon: Icon(Icons.check_circle, color: Colors.green)),
                ButtonSegment(
                    value: PaymentStatusFilter.dp,
                    label: Text('DP'),
                    icon: Icon(CupertinoIcons.checkmark_seal_fill,
                        color: Colors.orange)),
                ButtonSegment(
                    value: PaymentStatusFilter.booking,
                    label: Text('Booking'),
                    icon: Icon(Icons.bookmark, color: Colors.blue)),
              ],
              selected: <PaymentStatusFilter>{_selectedPaymentStatus},
              onSelectionChanged: (Set<PaymentStatusFilter> newSelection) {
                setState(() {
                  _selectedPaymentStatus = newSelection.first;
                });
              },
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLapanganDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedLapangan,
      hint: const Text('Pilih Lapangan'),
      items: lapanganList.map((String lapangan) {
        return DropdownMenuItem<String>(
          value: lapangan == 'Semua Lapangan' ? null : lapangan,
          child: Text(lapangan),
        );
      }).toList(),
      onChanged: (String? value) {
        setState(() => selectedLapangan = value);
        _updateAvailableMonths(value);
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      ),
    );
  }

  Widget _buildMonthAndDateFilter() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedMonthYear,
            hint: _isFetchingMonths
                ? const Row(
                    children: [
                      SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Mencari...'),
                    ],
                  )
                : const Text('Pilih Bulan'),
            items: availableMonths.map((String monthYear) {
              return DropdownMenuItem<String>(
                value: monthYear == 'Semua Bulan' || monthYear == 'Gagal memuat'
                    ? null
                    : monthYear,
                child: Text(_formatMonthYear(monthYear)),
              );
            }).toList(),
            onChanged: _isFetchingMonths
                ? null
                : (String? value) {
                    setState(() {
                      selectedMonthYear = value;
                      selectedDate = null;
                    });
                  },
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Pilih Tanggal Spesifik',
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (pickedDate != null && mounted) {
              setState(() {
                selectedDate = pickedDate;
                final monthFromDate = DateFormat('yyyy-MM').format(pickedDate);
                if (availableMonths.contains(monthFromDate)) {
                  selectedMonthYear = monthFromDate;
                } else {
                  selectedMonthYear = null;
                }
              });
            }
          },
        ),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final String bookingId;
  final VoidCallback onTap;

  const _BookingCard({
    Key? key,
    required this.bookingData,
    required this.bookingId,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = bookingData['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return const SizedBox.shrink();

    final firstItem = items[0] as Map<String, dynamic>;
    final lapangan = firstItem['name'] ?? 'N/A';
    final teamName = firstItem['teamName'] ?? '';
    final status = bookingData['statusBooking'] ?? 'Pending';
    final totalAmount = bookingData['totalAmount'] ?? 0;

    Color statusColor;
    String statusText = status;

    switch (status) {
      case var s when s.contains('Sudah Bayar'):
        statusColor = Colors.green;
        statusText = 'Lunas';
        break;
      case var s when s.toUpperCase().contains('DP'):
        statusColor = Colors.orange.shade700;
        statusText = 'DP';
        break;
      case var s when s.contains('Booking'):
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lapangan,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (teamName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              teamName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey.shade700),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(statusText),
                    labelStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                    backgroundColor: statusColor,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                  context, Icons.person, bookingData['userName'] ?? 'N/A'),
              const SizedBox(height: 6),
              _buildInfoRow(
                  context,
                  Icons.calendar_today,
                  DateFormat('dd MMMM yyyy').format(DateTime.parse(
                      firstItem['bookingDate'] ??
                          DateTime.now().toIso8601String()))),
              const SizedBox(height: 6),
              _buildInfoRow(context, Icons.access_time,
                  '${firstItem['time'] ?? 'N/A'} (${firstItem['quantity'] ?? '1'} jam)'),

              // --- PERUBAHAN DI SINI ---
              // Spacer dihapus agar konten rapat ke atas
              const Expanded(child: SizedBox()),

              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  NumberFormat.currency(
                          locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                      .format(totalAmount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
