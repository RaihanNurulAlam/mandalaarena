// ignore_for_file: use_build_context_synchronously, library_prefixes, avoid_print, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as Path;

class AddArticlePage extends StatefulWidget {
  @override
  _AddArticlePageState createState() => _AddArticlePageState();
}

class _AddArticlePageState extends State<AddArticlePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _contentController = TextEditingController();

  Uint8List? _imageFileBytes;
  String? _imageUrl;
  bool _isUploading = false;
  String _fileName = ''; // To display the selected file name

  Future<void> _pickImage() async {
    final html.FileUploadInputElement input = html.FileUploadInputElement()
      ..accept = 'image/*';
    input.click();

    input.onChange.listen((event) {
      final html.File? file = input.files?.first;
      if (file != null) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((event) {
          setState(() {
            _imageFileBytes = reader.result as Uint8List;
            _fileName = file.name; // Store the file name
          });
        });
      }
    });
  }

  Future<void> _addArticle() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an image.')),
        );
        return;
      }

      setState(() {
        _isUploading = true;
      });

      try {
        // Upload image to Firebase Storage
        firebase_storage.Reference ref =
            firebase_storage.FirebaseStorage.instance.ref(
                'article_images/${Path.basename(_fileName)}'); // Use original file name

        await ref.putData(_imageFileBytes!);
        _imageUrl = await ref.getDownloadURL();

        // Add article data to Firestore
        List<String> contentList = _contentController.text.split('\n');

        await FirebaseFirestore.instance.collection('articles').add({
          'title': _titleController.text,
          'subtitle': _subtitleController.text,
          'imagePath': _imageUrl,
          'content': contentList,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Article added successfully.')),
        );

        Navigator.of(context).pop();
      } catch (e) {
        print('Error adding article: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add article.')),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Artikel')),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _imageFileBytes != null
                              ? Image.memory(_imageFileBytes!,
                                  fit: BoxFit.cover) // Use Image.memory
                              : const Icon(Icons.add_photo_alternate, size: 48),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_fileName.isNotEmpty)
                        Text('Selected file: $_fileName'), // Display file name

                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Judul'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Judul harus diisi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _subtitleController,
                        decoration:
                            const InputDecoration(labelText: 'Sub Judul'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Sub Judul harus diisi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _contentController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration:
                            const InputDecoration(labelText: 'Isi Artikel'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Isi artikel harus diisi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _addArticle,
                        child: const Text('Tambahkan'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
