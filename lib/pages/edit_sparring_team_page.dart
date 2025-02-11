// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mandalaarenaapp/pages/models/sparring_team_model.dart';

class EditSparringTeamPage extends StatefulWidget {
  final SparringTeam team;

  const EditSparringTeamPage({required this.team});

  @override
  _EditSparringTeamPageState createState() => _EditSparringTeamPageState();
}

class _EditSparringTeamPageState extends State<EditSparringTeamPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController contactController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.team.name);
    contactController = TextEditingController(text: widget.team.contact);
  }

  void _updateTeam() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection('sparring_teams')
          .doc(widget.team.id)
          .update({
        'name': nameController.text,
        'contact': contactController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data tim berhasil diperbarui')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Tim')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Nama Tim'),
                validator: (value) =>
                    value!.isEmpty ? 'Nama tim tidak boleh kosong' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: contactController,
                decoration: InputDecoration(labelText: 'Kontak WhatsApp'),
                validator: (value) =>
                    value!.isEmpty ? 'Kontak tidak boleh kosong' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateTeam,
                child: Text('Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
