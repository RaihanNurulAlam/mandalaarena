// ignore_for_file: deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/Login%20Signup/Screen/login.dart';
import 'package:mandalaarenaapp/pages/add_sparring_team_page.dart';
import 'package:mandalaarenaapp/pages/edit_sparring_team_page.dart';
import 'package:mandalaarenaapp/pages/models/sparring_team_model.dart';
import 'package:mandalaarenaapp/pages/sparring_booking_page.dart';
import 'package:url_launcher/url_launcher.dart';

class SparringTeamPage extends StatefulWidget {
  const SparringTeamPage({super.key});

  @override
  _SparringTeamPageState createState() => _SparringTeamPageState();
}

class _SparringTeamPageState extends State<SparringTeamPage> {
  // --- LOGIKA TIDAK DIUBAH ---
  String _selectedCategory = 'Semua';
  String? _selectedSort = 'Hari';
  String _searchQuery = '';
  final List<String> _categories = [
    'Semua',
    'Tim Basket',
    'Tim Minisoccer',
  ];
  final List<String> _sorts = ['Hari', 'Abjad A-Z', 'Abjad Z-A'];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isAdmin = false;

  final Map<String, int> _dayOrder = {
    'Senin': 1,
    'Selasa': 2,
    'Rabu': 3,
    'Kamis': 4,
    'Jumat': 5,
    'Sabtu': 6,
    'Minggu': 7,
  };

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && mounted) {
          setState(() {
            _isAdmin = userDoc.get('isAdmin') as bool;
          });
        }
      } catch (e) {
        print("Error checking admin status: $e");
      }
    }
  }

  void _launchWhatsApp(String phoneNumber) async {
    String formattedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (formattedNumber.startsWith('0')) {
      formattedNumber = '62${formattedNumber.substring(1)}';
    }
    final url = 'https://wa.me/$formattedNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
      );
    }
  }

  Future<void> _deleteTeam(String teamId) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus tim ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestore.collection('sparring_teams').doc(teamId).delete();
    }
  }

  void _editTeam(SparringTeam team) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSparringTeamPage(team: team),
      ),
    );
  }

  void _navigateToBookingPage(SparringTeam team) {
    String lapangCategory = '';
    if (team.category == 'Tim Minisoccer') {
      lapangCategory = 'Lapang Minisoccer';
    } else if (team.category == 'Tim Basket 3x3') {
      lapangCategory = 'Lapang Basket 3x3';
    } else if (team.category == 'Tim Basket') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pilih Jenis Lapangan'),
          content: const Text(
              'Silakan pilih jenis lapangan basket yang ingin Anda booking.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _openBookingPage(team, 'Lapang Basket Vynil');
              },
              child: const Text('Vynil'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _openBookingPage(team, 'Lapang Basket Karet');
              },
              child: const Text('Karet'),
            ),
          ],
        ),
      );
      return;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori tim tidak valid.')),
      );
      return;
    }

    if (lapangCategory.isNotEmpty) {
      _openBookingPage(team, lapangCategory);
    }
  }

  void _openBookingPage(SparringTeam team, String lapangCategory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SparringBookingPage(
          team: team,
          lapangCategory: lapangCategory,
        ),
      ),
    );
  }

  void _sortTeams(List<SparringTeam> teams) {
    if (_selectedSort == 'Hari') {
      teams.sort((a, b) {
        final aDay = a.availableDays.isNotEmpty ? a.availableDays.first : '';
        final bDay = b.availableDays.isNotEmpty ? b.availableDays.first : '';
        return (_dayOrder[aDay] ?? 8).compareTo(_dayOrder[bDay] ?? 8);
      });
    } else if (_selectedSort == 'Abjad A-Z') {
      teams
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_selectedSort == 'Abjad Z-A') {
      teams
          .sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text("Cari Lawan Sparring",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              floating: true,
              pinned: true,
              snap: true,
              forceElevated: innerBoxIsScrolled,
              // --- PERUBAHAN DI SINI ---
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.black, size: 28),
                    tooltip: 'Buat Tim Sparring',
                    onPressed: () {
                      if (_auth.currentUser == null) {
                        _showLoginDialog();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const AddSparringTeamPage()),
                        );
                      }
                    },
                  ),
                ),
              ],
              // --- AKHIR PERUBAHAN ---
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(130.0),
                child: _buildFilterSection(),
              ),
            ),
          ];
        },
        body: _buildTeamList(),
      ),
      // --- FloatingActionButton DIHAPUS DARI SINI ---
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari nama tim...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSort,
                    items: _sorts
                        .map((sort) =>
                            DropdownMenuItem(value: sort, child: Text(sort)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedSort = val),
                    hint: const Text('Urutkan'),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _buildCategoryChip(category);
              },
              separatorBuilder: (context, index) => const SizedBox(width: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    bool isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedCategory = category);
        }
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.black,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? Colors.black : Colors.grey[300]!,
        ),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildTeamList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('sparring_teams').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Belum ada tim sparring.'));
        }

        final teams = snapshot.data!.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return SparringTeam.fromMap(data);
        }).toList();

        final filteredTeams = teams.where((team) {
          final categoryMatch = _selectedCategory == 'Semua' ||
              team.category == _selectedCategory;
          final searchMatch =
              team.name.toLowerCase().contains(_searchQuery.toLowerCase());
          return categoryMatch && searchMatch;
        }).toList();

        _sortTeams(filteredTeams);

        if (filteredTeams.isEmpty) {
          return const Center(child: Text('Tim tidak ditemukan.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredTeams.length,
          itemBuilder: (context, index) {
            final team = filteredTeams[index];
            final isCreator = team.createdBy == _auth.currentUser?.uid;
            return _buildTeamCard(team, isCreator);
          },
        );
      },
    );
  }

  Widget _buildTeamCard(SparringTeam team, bool isCreator) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.grey[200],
                backgroundImage: NetworkImage(team.imageUrl),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildInfoTag(
                            Icons.sports_soccer, team.category, Colors.blue),
                        _buildInfoTag(
                            Icons.calendar_today,
                            '${team.availableDays.join(', ')} at ${team.availableHours.join(', ')}',
                            Colors.orange),
                      ],
                    )
                  ],
                ),
              ),
              if (isCreator || _isAdmin)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _editTeam(team);
                    if (value == 'delete') _deleteTeam(team.id);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  tooltip: "Opsi",
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchWhatsApp(team.contact),
                  icon: Image.network(
                    'https://img.icons8.com/?size=100&id=16733&format=png&color=2ECC71', // URL dengan warna hijau
                    width: 18,
                    height: 18,
                  ),
                  label: const Text('Kontak'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_auth.currentUser == null) {
                      _showLoginDialog();
                    } else {
                      _navigateToBookingPage(team);
                    }
                  },
                  icon: const Icon(
                    Icons.sports_kabaddi,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text('Tanding'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
              child: Text(text,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                      fontSize: 12))),
        ],
      ),
    );
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Diperlukan'),
        content: const Text(
            'Anda harus login terlebih dahulu untuk melakukan aksi ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
