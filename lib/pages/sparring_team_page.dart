// ignore_for_file: deprecated_member_use, use_build_context_synchronously

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
    await _firestore.collection('sparring_teams').doc(teamId).delete();
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
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: isAndroid
            ? Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari lawan sparring...',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownButton<String>(
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
                      DropdownButton<String>(
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
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AddSparringTeamPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari lawan sparring...',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownButton<String>(
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
                      DropdownButton<String>(
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
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AddSparringTeamPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('sparring_teams').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Tidak ada tim sparring.'));
          }

          final teams = snapshot.data!.docs.map((doc) {
            return SparringTeam.fromMap(doc.data() as Map<String, dynamic>);
          }).toList();

          // Filter teams based on selected category, cost, time, and search query
          final filteredTeams = teams.where((team) {
            final categoryMatch = _selectedCategory == null ||
                _selectedCategory == 'Semua' ||
                team.category == _selectedCategory;
            final searchMatch =
                team.name.toLowerCase().contains(_searchQuery.toLowerCase());
            return categoryMatch && searchMatch;
          }).toList();

          // Sort teams based on selected sort option
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
              return (_dayOrder[aDay] ?? 0).compareTo(_dayOrder[bDay] ?? 0);
            });
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
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

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 2.2, // Sesuaikan aspek rasio
                      ),
                      itemCount: filteredTeams.length,
                      itemBuilder: (context, index) {
                        final team = filteredTeams[index];
                        final isAdmin = user?.email ==
                            'raihannurulalam14@gmail.com'; // Ganti dengan email admin yang valid
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
                                  child: Image.network(
                                    team.imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        team.name,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                          'Hari: ${team.availableDays.join(', ')}'),
                                      Text(
                                          'Jam: ${team.availableHours.join(', ')}'),
                                      Text('Kategori: ${team.category}'),
                                      Text('Kontak: ${team.contact}'),
                                      Text('Biaya: ${team.cost}'),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isCreator || isAdmin)
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () => _editTeam(team),
                                      ),
                                    if (isAdmin)
                                      IconButton(
                                        icon: Icon(
                                          CupertinoIcons.trash_circle,
                                          color: Colors.black,
                                        ),
                                        onPressed: () => _deleteTeam(team.id),
                                      ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.chat, color: Colors.green),
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
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
