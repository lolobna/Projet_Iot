// pages/add_patient_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPatientPage extends StatefulWidget {
  @override
  _AddPatientPageState createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final cinController = TextEditingController();
  final _db = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> foundPatients = [];

  Future<void> searchPatients(String cinInput) async {
    final snapshot = await _db.child("users").get();
    List<Map<String, dynamic>> patients = [];

    for (var child in snapshot.children) {
      final data = child.value as Map?;
      if (data != null &&
          data['role'] == 'patient' &&
          data['CIN'] != null &&
          data['CIN'].toString().startsWith(cinInput)) {
        patients.add({
          'uid': child.key!,
          'cin': data['CIN'],
          'nom': data['nom'],
          'prenom': data['prenom'],
        });
      }
    }

    setState(() {
      foundPatients = patients;
    });
  }

  Future<void> addPatientToDoctor(String patientUid) async {
    final medecinUid = FirebaseAuth.instance.currentUser!.uid;
    await _db.child("medecins/$medecinUid/patients/$patientUid").set(true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Patient ajouté avec succès !')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ajouter un patient")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: cinController,
              decoration: InputDecoration(labelText: "Rechercher par CIN"),
              onChanged: searchPatients,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: foundPatients.length,
                itemBuilder: (_, index) {
                  final patient = foundPatients[index];
                  return ListTile(
                    title: Text("${patient['nom']} ${patient['prenom']}"),
                    subtitle: Text("CIN: ${patient['cin']}"),
                    trailing: IconButton(
                      icon: Icon(Icons.person_add),
                      onPressed: () => addPatientToDoctor(patient['uid']),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
