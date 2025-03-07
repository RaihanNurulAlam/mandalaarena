// ignore_for_file: deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/pages/add_sparring_team_page.dart';
import 'package:mandalaarenaapp/pages/edit_sparring_team_page.dart';
import 'package:mandalaarenaapp/pages/models/sparring_team_model.dart';
import 'package:url_launcher/url_launcher.dart';

class SparringTeamPage extends StatefulWidget {
  @override
  _SparringTeamPageState createState() => _SparringTeamPageState();
}

class _SparringTeamPageState extends State<SparringTeamPage> {
  String? _selectedCategory;
  String? _selectedSort;
  String _searchQuery = '';
  final List<String> _categories = [
    'Semua',
    'Tim Basket',
    'Tim Basket 3x3',
    'Tim Minisoccer',
  ];
  final List<String> _sorts = ['Hari', 'Biaya Terendah', 'Biaya Tertinggi'];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _isAdmin = userDoc.get('isAdmin') as bool;
        });
      }
    }
  }

  void _launchWhatsApp(String phoneNumber) async {
    final url = 'https://wa.me/$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
      );
    }
  }

  Future<void> _deleteTeam(String teamId) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi'),
        content: Text('Apakah Anda yakin ingin menghapus tim ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestore.collection('sparring_teams').doc(teamId).delete();
    }
  }

  void _editTeam(SparringTeam team) async {
    final updatedTeam = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSparringTeamPage(team: team),
      ),
    );

    if (updatedTeam != null) {
      await _firestore
          .collection('sparring_teams')
          .doc(updatedTeam.id)
          .update(updatedTeam.toMap());
    }
  }

  // Urutan hari untuk sorting
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
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari lawan sparring...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      prefixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.fromLTRB(18, 0, 18, 0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          hint: Text('Pilih Olahraga'),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedSort,
                          hint: Text('Urutkan Berdasarkan'),
                          onChanged: (value) {
                            setState(() {
                              _selectedSort = value;
                            });
                          },
                          items: _sorts.map((sort) {
                            return DropdownMenuItem(
                              value: sort,
                              child: Text(sort),
                            );
                          }).toList(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AddSparringTeamPage()),
                          );

                          if (result == true) {
                            // Refresh data di SparringTeamPage
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('sparring_teams').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Tidak ada tim sparring.'));
                }

                final teams = snapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;

                  return SparringTeam.fromMap({
                    'id': doc.id,
                    'name': data['name'] ?? '',
                    'category': data['category'] ?? '',
                    'imageUrl': data['imageUrl'] ?? '',
                    'contact': data['contact'] ?? '',
                    'cost': data['cost'] ?? 0.0,
                    'availableDays': data['availableDays'] ?? [],
                    'availableHours': data['availableHours'] ?? [],
                    'createdAt': data['createdAt'] ?? Timestamp.now(),
                    'createdBy': data['createdBy'] ?? '',
                  });
                }).toList();

                // Filter dan sort teams (sesuai kebutuhan)
                final filteredTeams = teams.where((team) {
                  final categoryMatch = _selectedCategory == null ||
                      _selectedCategory == 'Semua' ||
                      team.category == _selectedCategory;
                  final searchMatch = team.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                  return categoryMatch && searchMatch;
                }).toList();

                if (_selectedSort == 'Biaya Terendah') {
                  filteredTeams.sort((a, b) => a.cost.compareTo(b.cost));
                } else if (_selectedSort == 'Biaya Tertinggi') {
                  filteredTeams.sort((a, b) => b.cost.compareTo(a.cost));
                } else if (_selectedSort == 'Hari') {
                  filteredTeams.sort((a, b) {
                    final aDay =
                        a.availableDays.isNotEmpty ? a.availableDays.first : '';
                    final bDay =
                        b.availableDays.isNotEmpty ? b.availableDays.first : '';
                    return (_dayOrder[aDay] ?? 0)
                        .compareTo(_dayOrder[bDay] ?? 0);
                  });
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Center(
                        child: Text(
                          'Menampilkan ${filteredTeams.length} tim',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount;
                          if (screenWidth > 1200) {
                            crossAxisCount = 3;
                          } else if (screenWidth > 750) {
                            crossAxisCount = 2;
                          } else {
                            crossAxisCount = 1;
                          }

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: 2.2,
                              ),
                              itemCount: filteredTeams.length,
                              itemBuilder: (context, index) {
                                final team = filteredTeams[index];
                                final isCreator = team.createdBy == user?.uid;

                                return Card(
                                  margin: EdgeInsets.all(8),
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 80,
                                          height: 80,
                                          child: team.imageUrl.isNotEmpty
                                              ? Image.network(
                                                  team.imageUrl,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context,
                                                      child, loadingProgress) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        value: loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Icon(
                                                      Icons.image_not_supported,
                                                      size: 50,
                                                      color: Colors.grey,
                                                    );
                                                  },
                                                )
                                              : Icon(
                                                  Icons.image,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                team.name,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                  'Hari: ${team.availableDays.join(', ')}'),
                                              Text(
                                                  'Jam: ${team.availableHours.join(', ')}'),
                                              Text(
                                                  'Kategori: ${team.category}'),
                                              Text('Kontak: ${team.contact}'),
                                              Text(
                                                  'Biaya: ${team.cost.toString()}'),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (isCreator || _isAdmin)
                                              IconButton(
                                                icon: Icon(Icons.edit,
                                                    color: Colors.blue),
                                                onPressed: () =>
                                                    _editTeam(team),
                                              ),
                                            if (_isAdmin)
                                              IconButton(
                                                icon: Icon(
                                                    CupertinoIcons.trash_circle,
                                                    color: Colors.black),
                                                onPressed: () =>
                                                    _deleteTeam(team.id),
                                              ),
                                            IconButton(
                                              icon: Icon(Icons.chat,
                                                  color: Colors.green),
                                              onPressed: () =>
                                                  _launchWhatsApp(team.contact),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
