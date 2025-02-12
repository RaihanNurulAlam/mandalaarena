import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SparringTeam {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> availableDays;
  final List<String> availableHours;
  final String contact;
  final String category;
  final String createdBy;

  SparringTeam({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.availableDays,
    required this.availableHours,
    required this.contact,
    required this.category,
    required this.createdBy,
  });

  // Convert SparringTeam to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'availableDays': availableDays,
      'availableHours': availableHours,
      'contact': contact,
      'category': category,
      'createdBy': createdBy,
    };
  }

  // Create SparringTeam from a Map
  factory SparringTeam.fromMap(Map<String, dynamic> map) {
    return SparringTeam(
      id: map['id'] ?? '', // Berikan nilai default jika null
      name: map['name'] ?? '', // Berikan nilai default jika null
      imageUrl: map['imageUrl'] ?? '', // Berikan nilai default jika null
      availableDays: List<String>.from(map['availableDays'] ?? []),
      availableHours: List<String>.from(map['availableHours'] ?? []),
      contact: map['contact'] ?? '', // Berikan nilai default jika null
      category: map['category'] ?? '', // Berikan nilai default jika null
      createdBy: map['createdBy'] ?? '', // Berikan nilai default jika null
    );
  }
}

class SparringTeamItem extends StatelessWidget {
  final SparringTeam team;
  final VoidCallback onDelete;

  const SparringTeamItem({
    super.key,
    required this.team,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser?.uid;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(team.imageUrl),
        ),
        title: Text(team.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kategori: ${team.category}'),
            Text('Hari Tersedia: ${team.availableDays.join(", ")}'),
            Text('Jam Tersedia: ${team.availableHours.join(", ")}'),
            Text('Kontak: ${team.contact}'),
          ],
        ),
        trailing: currentUser == team.createdBy
            ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              )
            : null, // Hanya tampilkan ikon hapus jika pengguna adalah pembuat tim
      ),
    );
  }
}

class SparringTeamList extends StatelessWidget {
  final List<SparringTeam> teams;

  const SparringTeamList({super.key, required this.teams});

  Future<void> _deleteTeam(String teamId) async {
    try {
      await FirebaseFirestore.instance
          .collection('sparringTeams')
          .doc(teamId)
          .delete();
    } catch (e) {
      debugPrint('Gagal menghapus tim: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        return SparringTeamItem(
          team: team,
          onDelete: () async {
            // Tampilkan dialog konfirmasi sebelum menghapus
            final confirmed = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Hapus Tim'),
                content:
                    const Text('Apakah Anda yakin ingin menghapus tim ini?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Hapus',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              await _deleteTeam(team.id);
            }
          },
        );
      },
    );
  }
}
