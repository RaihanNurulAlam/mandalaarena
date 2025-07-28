// ignore_for_file: unnecessary_null_comparison, use_build_context_synchronously, avoid_print, unused_field, prefer_interpolation_to_compose_strings

// import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class EditProfilePage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String profileImageUrl;
  final String phoneNumber;

  const EditProfilePage({
    required this.userName,
    required this.userEmail,
    required this.profileImageUrl,
    required this.phoneNumber,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  Uint8List? _imageBytes;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  File? _imageFile;
  bool isLoading = false;
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userName;
    _emailController.text = widget.userEmail;
    _phoneController.text = widget.phoneNumber;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      final imageBytes = await pickedImage.readAsBytes();
      setState(() {
        _imageBytes = imageBytes;
        _imageFile = File(pickedImage.path);
      });
    }
  }

  Future<void> _deleteOldImage(String imageUrl) async {
    try {
      // Dapatkan referensi ke file gambar lama di Firebase Storage
      Reference storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.delete();
    } catch (e) {
      print('Error deleting old image: $e');
    }
  }

  Future<String?> _uploadImage(String userName) async {
    try {
      if (_imageFile == null && _imageBytes == null) {
        return null; // Jika tidak ada gambar baru, kembalikan null
      }

      // Format nama file: hapus spasi dan karakter khusus, lalu tambahkan .jpg
      String fileName =
          userName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase() +
              '.jpg';

      // Referensi ke Firebase Storage dengan nama file yang sesuai
      Reference storageRef =
          FirebaseStorage.instance.ref().child('profile/$fileName');

      UploadTask uploadTask;
      if (kIsWeb && _imageBytes != null) {
        uploadTask = storageRef.putData(_imageBytes!);
      } else if (_imageFile != null) {
        uploadTask = storageRef.putFile(_imageFile!);
      } else {
        throw Exception("Gambar tidak ditemukan");
      }

      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        final userId = user?.uid;

        if (user == null) throw Exception('Pengguna tidak ditemukan');

        // Validasi password lama sebelum mengganti password
        if (_oldPasswordController.text.isNotEmpty ||
            _newPasswordController.text.isNotEmpty ||
            _confirmPasswordController.text.isNotEmpty) {
          final cred = EmailAuthProvider.credential(
            email: user.email!,
            password: _oldPasswordController.text,
          );

          try {
            await user.reauthenticateWithCredential(cred);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Password lama anda salah, sehingga ganti password tidak bisa dilakukan')),
            );
            setState(() {
              isLoading = false;
            });
            return;
          }

          if (_newPasswordController.text != _confirmPasswordController.text) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Password baru dan konfirmasi password tidak sinkron, sehingga tidak bisa melakukan perubahan')),
            );
            setState(() {
              isLoading = false;
            });
            return;
          }

          await user.updatePassword(_newPasswordController.text);
        }

        String? newProfileUrl = widget.profileImageUrl;

        // Jika ada gambar baru, hapus gambar lama dan upload gambar baru
        if (_imageFile != null || _imageBytes != null) {
          // Hapus gambar lama dari Firebase Storage
          if (widget.profileImageUrl.isNotEmpty) {
            await _deleteOldImage(widget.profileImageUrl);
          }

          // Upload gambar baru ke Firebase Storage dengan nama pengguna yang baru
          newProfileUrl = await _uploadImage(_nameController.text.trim());
          if (newProfileUrl == null) throw Exception('Gagal mengunggah gambar');
        }

        // Update data profil di Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'profileImageUrl': newProfileUrl,
        });

        // Update display name di Firebase Auth
        await user.updateDisplayName(_nameController.text);
        await user.reload();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil berhasil diperbarui!')),
        );

        Navigator.pop(context, {
          'userName': _nameController.text,
          'userEmail': _emailController.text,
          'profileImageUrl': newProfileUrl,
          'phoneNumber': _phoneController.text,
        });
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui profil: $e')),
        );
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ubah Profil'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _imageBytes != null
                          ? MemoryImage(_imageBytes!)
                          : NetworkImage(widget.profileImageUrl)
                              as ImageProvider?,
                      child:
                          _imageBytes == null && widget.profileImageUrl.isEmpty
                              ? Icon(Icons.person,
                                  size: 70, color: Colors.grey.shade700)
                              : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.black,
                          child: Icon(Icons.edit, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              _buildTextField(_nameController, 'Nama'),
              SizedBox(height: 20),
              _buildTextField(_emailController, 'Email'),
              SizedBox(height: 20),
              _buildTextField(
                  _phoneController, 'Nomor Telepon', TextInputType.phone),
              SizedBox(height: 20),
              Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text('Ganti Password',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 20),
              _buildPasswordField(_oldPasswordController, 'Password Lama',
                  _isOldPasswordVisible, () {
                setState(() {
                  _isOldPasswordVisible = !_isOldPasswordVisible;
                });
              }),
              SizedBox(height: 20),
              _buildPasswordField(_newPasswordController, 'Password Baru',
                  _isNewPasswordVisible, () {
                setState(() {
                  _isNewPasswordVisible = !_isNewPasswordVisible;
                });
              }),
              SizedBox(height: 20),
              _buildPasswordField(_confirmPasswordController,
                  'Konfirmasi Password Baru', _isConfirmPasswordVisible, () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              }),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IntrinsicWidth(
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      ),
                      child: Text(
                        'Simpan Perubahan',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      [TextInputType? keyboardType]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String labelText,
      bool isVisible, VoidCallback toggleVisibility) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
            onPressed: toggleVisibility,
          ),
        ),
      ),
    );
  }
}
