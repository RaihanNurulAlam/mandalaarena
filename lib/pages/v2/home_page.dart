// ignore_for_file: library_private_types_in_public_api, use_super_parameters

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CollectionReference fields =
      FirebaseFirestore.instance.collection('fields');
  String? selectedType;
  String? sortBy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Fields'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => FilterSheet(
                  onApply: (type, sortOption) {
                    setState(() {
                      selectedType = type;
                      sortBy = sortOption;
                    });
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: fields.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          List<DocumentSnapshot> fieldDocs = snapshot.data!.docs;

          // Filter by type
          if (selectedType != null && selectedType!.isNotEmpty) {
            fieldDocs = fieldDocs
                .where((doc) => doc['type'] == selectedType)
                .toList();
          }

          // Sort by price or rating
          if (sortBy == 'price') {
            fieldDocs.sort((a, b) => a['price'].compareTo(b['price']));
          } else if (sortBy == 'rating') {
            fieldDocs.sort((a, b) => b['rating'].compareTo(a['rating']));
          }

          return ListView(
            children: fieldDocs.map((doc) {
              return ListTile(
                title: Text(doc['name']),
                subtitle: Text('Price: ${doc['price']} | Rating: ${doc['rating']}'),
                onTap: () {
                  Navigator.pushNamed(context, '/booking',
                      arguments: doc.id);
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class FilterSheet extends StatelessWidget {
  final Function(String, String) onApply;
  const FilterSheet({required this.onApply, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? selectedType;
    String? sortBy;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            items: ['Futsal', 'Basket', 'Badminton']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (value) {
              selectedType = value;
            },
            decoration: const InputDecoration(labelText: 'Filter by Type'),
          ),
          DropdownButtonFormField<String>(
            items: ['price', 'rating']
                .map((option) => DropdownMenuItem(
                      value: option,
                      child: Text(option == 'price' ? 'Sort by Price' : 'Sort by Rating'),
                    ))
                .toList(),
            onChanged: (value) {
              sortBy = value;
            },
            decoration: const InputDecoration(labelText: 'Sort by'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              onApply(selectedType ?? '', sortBy ?? '');
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
