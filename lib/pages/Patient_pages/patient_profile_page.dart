import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class PatientProfilePage extends StatefulWidget {
  const PatientProfilePage({super.key});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _profile = {};
  bool _loading = true;
  File? _image;
  String? _imageUrl;
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _cinController = TextEditingController();
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
    loadProfile();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      final doc = await FirebaseFirestore.instance.collection('patient').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _profile = data;
          _nomController.text = data['nom'] ?? '';
          _prenomController.text = data['prenom'] ?? '';
          _cinController.text = data['CIN'] ?? '';
          _imageUrl = data['photoUrl'];
        });
      }
    } catch (e) {
      print("Erreur Firestore : $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> updateProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    Map<String, dynamic> updates = {
      'nom': _nomController.text.trim(),
      'prenom': _prenomController.text.trim(),
      'CIN': _cinController.text.trim(),
    };
    if (_image != null) {
      final ref = FirebaseStorage.instance.ref("profile_images/$uid.jpg");
      await ref.putFile(_image!);
      final url = await ref.getDownloadURL();
      updates['photoUrl'] = url;
    }
    await FirebaseFirestore.instance.collection('patient').doc(uid).update(updates);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Profil mis à jour !")),
    );

    loadProfile();
  }

  Future<void> pickImage({ImageSource source = ImageSource.gallery}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Choisir depuis la galerie'),
            onTap: () {
              Navigator.pop(context);
              pickImage(source: ImageSource.gallery);
            },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Prendre une photo'),
            onTap: () {
              Navigator.pop(context);
              pickImage(source: ImageSource.camera);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F6FB),
      appBar: AppBar(
        title: Text("My Profile"),
        backgroundColor: Color(0xFF2196F3),
        elevation: 0,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _profile.isEmpty
              ? Center(child: Text("Aucun profil trouvé."))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, child) {
                              return Container(
                                width: 140 + (_glowController.value * 20),
                                height: 140 + (_glowController.value * 20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blueAccent.withOpacity(0.2 * _glowController.value),
                                ),
                              );
                            },
                          ),
                          GestureDetector(
                            onTap: showPhotoOptions,
                            child: CircleAvatar(
                              radius: 70,
                              backgroundColor: Color(0xFF64B5F6),
                              backgroundImage: _image != null
                                  ? FileImage(_image!)
                                  : (_imageUrl != null ? NetworkImage(_imageUrl!) : null) as ImageProvider?,
                              child: _image == null && _imageUrl == null
                                  ? Icon(Icons.person, size: 70, color: Colors.white)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text("${_profile['prenom'] ?? ''} ${_profile['nom'] ?? ''}",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      if (_profile['email'] != null)
                        Text("Email: ${_profile['email']}", style: TextStyle(fontSize: 16, color: Colors.black54)),
                      if (_profile['CIN'] != null)
                        Text("CIN: ${_profile['CIN']}", style: TextStyle(fontSize: 16, color: Colors.black54)),
                      SizedBox(height: 30),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _prenomController,
                              decoration: InputDecoration(labelText: 'Prénom'),
                              validator: (value) => value!.isEmpty ? 'Requis' : null,
                            ),
                            SizedBox(height: 12),
                            TextFormField(
                              controller: _nomController,
                              decoration: InputDecoration(labelText: 'Nom'),
                              validator: (value) => value!.isEmpty ? 'Requis' : null,
                            ),
                            SizedBox(height: 12),
                            TextFormField(
                              controller: _cinController,
                              decoration: InputDecoration(labelText: 'CIN'),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  updateProfile();
                                }
                              },
                              icon: Icon(Icons.save),
                              label: Text("Enregistrer"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF2196F3),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back),
                        label: Text("Retour"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1976D2),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
