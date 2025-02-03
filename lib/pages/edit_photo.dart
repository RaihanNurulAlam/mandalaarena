// ignore_for_file: annotate_overrides, library_private_types_in_public_api, unused_field, unused_local_variable, unused_element, non_constant_identifier_names, unnecessary_import, prefer_typing_uninitialized_variables

import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SingleImagePicker extends StatefulWidget {
  const SingleImagePicker({super.key});

  @override
  _SingleImagePickerState createState() => _SingleImagePickerState();
}

class _SingleImagePickerState extends State<SingleImagePicker> {
  Uint8List? _imageBytes;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final pickedImage = await picker.pickImage(
        source: ImageSource.gallery); // Fix nama variabel

    if (pickedImage != null) {
      final imageBytes = await pickedImage.readAsBytes();
      setState(() {
        _imageBytes = imageBytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          children: [
            CircleAvatar(
              radius: 70,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  _imageBytes != null ? MemoryImage(_imageBytes!) : null,
              child: _imageBytes == null
                  ? Icon(
                      Icons.person,
                      size: 70,
                      color: Colors.grey.shade700,
                    )
                  : null,
            ),
            Positioned(
              right: 5,
              bottom: 5,
              child: InkWell(
                onTap: _pickImage, // Fix pemanggilan fungsi
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue,
                  child: Icon(
                    Icons.edit,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
