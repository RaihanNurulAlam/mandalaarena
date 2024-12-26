// ignore_for_file: use_super_parameters, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingPage extends StatefulWidget {
  final String fieldId;

  const BookingPage({required this.fieldId, Key? key}) : super(key: key);

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final TextEditingController dateController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> bookField() async {
    final user = _auth.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('bookings').add({
        'fieldId': widget.fieldId,
        'userId': user.uid,
        'date': dateController.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking Confirmed')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Field')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: 'Booking Date'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: bookField,
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
