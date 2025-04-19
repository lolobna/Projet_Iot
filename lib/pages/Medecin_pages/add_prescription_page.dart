import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_application_1/pages/Medecin_pages/add_patient_page.dart';
import 'package:flutter_application_1/pages/Medecin_pages/SelectPatientPage.dart';

import 'package:flutter_application_1/pages/Medecin_pages/medecin_home_page.dart';


class PrescriptionPage extends StatefulWidget {
  final String patientUid;

  PrescriptionPage({required this.patientUid});

  @override
  _PrescriptionPageState createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<PrescriptionPage> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  List<List<TextEditingController>> descControllers = [];
  List<List<TimeOfDay?>> times = [];
  List<TextEditingController> nomControllers = [];

  String patientName = "";
  String patientSurname = "";
  String patientCIN = "";

  @override
  void initState() {
    super.initState();
    // Ajouter le premier médicament par défaut
    addMedicament();
    // Charger les informations du patient
    fetchPatientInfo();
  }

  void addMedicament() {
    if (nomControllers.length < 4) {
      setState(() {
        nomControllers.add(TextEditingController());
        descControllers.add(List.generate(3, (_) => TextEditingController()));
        times.add(List.generate(3, (_) => null));
      });
    }
  }

  Future<void> selectTime(BuildContext context, int medIndex, int timeIndex) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        times[medIndex][timeIndex] = picked;
      });
    }
  }

  Future<void> fetchPatientInfo() async {
    final snapshot = await _db.child("users/patients/${widget.patientUid}").get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      setState(() {
        patientName = data["nom"] ?? "Inconnu";
        patientSurname = data["prenom"] ?? "Inconnu";
        patientCIN = data["CIN"] ?? "Inconnu";
      });
    }
  }

  Future<void> submitPrescription() async {
    if (widget.patientUid.isEmpty) return;
    final medecinUid = FirebaseAuth.instance.currentUser!.uid;

    final Map<String, dynamic> medicaments = {};

    for (int i = 0; i < nomControllers.length; i++) {
      String medKey = String.fromCharCode(65 + i); // A, B, C, D
      medicaments[medKey] = {
        "nom": nomControllers[i].text,
        "prises": List.generate(3, (j) {
          return {
            "horaire": times[i][j]?.format(context) ?? "",
            "description": descControllers[i][j].text,
            "etat": {
              "status": "non pris",
              "heureReelle": "",
              "retardMinutes": "",
            },
            "notificationEnvoyee": false,
          };
        }),
      };
    }

    final prescription = {
      "medecinId": medecinUid,
      "date": DateTime.now().toIso8601String().split("T")[0],
      "medicaments": medicaments,
    };

    await _db.child("users/patients/${widget.patientUid}/prescriptions").push().set(prescription);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Prescription enregistrée")),
    );
  }

  Widget medicamentForm(String label, int index) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 10),
            TextField(
              controller: nomControllers[index],
              decoration: InputDecoration(
                labelText: 'Nom du médicament',
                prefixIcon: Icon(Icons.medical_services, color: Colors.blueAccent),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            for (int i = 0; i < 3; i++) ...[
              Text("Prise ${i + 1}", style: TextStyle(fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Text("Heure : ${times[index][i]?.format(context) ?? "--:--"}"),
                  SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => selectTime(context, index, i),
                    child: Text("Choisir l'heure"),
                  ),
                ],
              ),
              SizedBox(height: 8),
              TextField(
                controller: descControllers[index][i],
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description, color: Colors.blueAccent),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
            ]
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var list in descControllers) {
      for (var controller in list) {
        controller.dispose();
      }
    }
    for (var controller in nomControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ajouter une prescription"),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueAccent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blueAccent,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Médecin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'medecin@example.com',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
             ListTile(
              leading: Icon(Icons.home),
              title: Text('Accueil'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MedecinHomePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person_add),
              title: Text('Ajouter un patient'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddPatientPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('Voir les patients'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SelectPatientPage()),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Déconnexion'),
              onTap: () {
                // Ajoutez ici la logique de déconnexion
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations du patient
            Card(
              margin: EdgeInsets.only(bottom: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Informations du patient",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Nom : $patientName",
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      "Prénom : $patientSurname",
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      "CIN : $patientCIN",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            // Formulaire des médicaments
            for (int i = 0; i < nomControllers.length; i++)
              medicamentForm("Médicament ${String.fromCharCode(65 + i)}", i),
            if (nomControllers.length < 4)
              ElevatedButton.icon(
                onPressed: addMedicament,
                icon: Icon(Icons.add),
                label: Text("Ajouter un médicament"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: submitPrescription,
              child: Text(
                "Enregistrer la prescription",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
