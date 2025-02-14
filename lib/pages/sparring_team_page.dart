// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/pages/add_sparring_team_page.dart';
import 'package:mandalaarenaapp/pages/edit_sparring_team_page.dart';
import 'package:mandalaarenaapp/pages/models/sparring_team_model.dart';
import 'package:url_launcher/url_launcher.dart'; // Import Firebase Auth

class SparringTeamPage extends StatefulWidget {
  @override
  _SparringTeamPageState createState() => _SparringTeamPageState();
}

class _SparringTeamPageState extends State<SparringTeamPage> {
  String? _selectedCategory;
  final List<String> _categories = [
    'Semua',
    'Tim Basket',
    'Tim Basket 3x3',
    'Tim Minisoccer',
  ];

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

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sparring Tim'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddSparringTeamPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
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
              decoration: InputDecoration(
                labelText: 'Filter Kategori',
                border: OutlineInputBorder(),
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
                  return SparringTeam.fromMap(
                      doc.data() as Map<String, dynamic>);
                }).toList();

                // Filter teams based on selected category
                final filteredTeams =
                    _selectedCategory == null || _selectedCategory == 'Semua'
                        ? teams
                        : teams
                            .where((team) => team.category == _selectedCategory)
                            .toList();

                return ListView.builder(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(team.name,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                      'Hari: ${team.availableDays.join(', ')}'),
                                  Text(
                                      'Jam: ${team.availableHours.join(', ')}'),
                                  Text('Kontak: ${team.contact}'),
                                ],
                              ),
                            ),
                            if (isCreator || isAdmin)
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editTeam(team),
                              ),
                            if (isAdmin)
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteTeam(team.id),
                              ),
                            IconButton(
                              icon: Icon(Icons.chat, color: Colors.green),
                              onPressed: () => _launchWhatsApp(team.contact),
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
      ),
    );
  }
}
