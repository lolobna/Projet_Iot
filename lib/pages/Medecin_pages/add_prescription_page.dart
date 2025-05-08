import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class PrescriptionPage extends StatefulWidget {
  final String patientUid;

  PrescriptionPage({required this.patientUid});

  @override
  _PrescriptionPageState createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<PrescriptionPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<TextEditingController> nomControllers = [];
  List<List<String>> horairesList = [];
  List<TextEditingController> descControllers = [];

  final int maxMedicaments = 4;

  String patientName = "";
  String patientSurname = "";
  String patientCIN = "";

  @override
  void initState() {
    super.initState();
    fetchPatientInfo();
    addMedicament(); // Ajouter automatiquement le premier médicament
  }

  Future<void> fetchPatientInfo() async {
    final snapshot =
        await _db.collection('patient').doc(widget.patientUid).get();
    if (snapshot.exists) {
      final data = snapshot.data()!;
      setState(() {
        patientName = data["nom"] ?? "Inconnu";
        patientSurname = data["prenom"] ?? "Inconnu";
        patientCIN = data["CIN"] ?? "Inconnu";
      });
    }
  }

  void addMedicament() {
    if (nomControllers.length < maxMedicaments) {
      setState(() {
        nomControllers.add(TextEditingController());
        horairesList.add([""]);
        descControllers.add(TextEditingController());
      });
    }
  }

  Future<void> submitPrescription() async {
    if (widget.patientUid.isEmpty) return;
    final medecinUid = FirebaseAuth.instance.currentUser?.uid;

    if (medecinUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : médecin non authentifié")),
      );
      return;
    }

    final Map<String, dynamic> medicaments = {};

    for (int i = 0; i < nomControllers.length; i++) {
      String medKey = String.fromCharCode(65 + i); // A, B, C, D
      medicaments[medKey] = {
        "medicament_name": nomControllers[i].text.trim(),
        "horaires": horairesList[i],
        "note": descControllers[i].text.trim(),
        "vide": true,
      };
    }

    final prescription = {
      "medecinId": medecinUid,
      "patientId": widget.patientUid,
      "date": DateTime.now().toIso8601String().split("T")[0],
      "compartiments": {
        "A": medicaments["A"],
        "B": medicaments["B"],
        "C": medicaments["C"],
        "D": medicaments["D"],
      },
    };

    final dbRef = FirebaseDatabase.instance.ref().child("prescriptions").push();
    await dbRef.set(prescription);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Prescription enregistrée")));

    setState(() {
      nomControllers.clear();
      descControllers.clear();
      horairesList.clear();
      addMedicament(); // Réinitialiser avec un champ vide
    });
  }

  Widget medicamentForm(String label, int index) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 10),
            TextField(
              controller: nomControllers[index],
              decoration: InputDecoration(
                labelText: 'Nom du médicament',
                prefixIcon: Icon(
                  Icons.medical_services,
                  color: Colors.blueAccent,
                ),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            for (int i = 0; i < horairesList[index].length; i++) ...[
              Text(
                "Horaire ${i + 1}",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                    builder: (context, child) {
                      return MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(alwaysUse24HourFormat: true),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      final now = DateTime.now();
                      final formatted = TimeOfDay(
                        hour: picked.hour,
                        minute: picked.minute,
                      );
                      final time = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        formatted.hour,
                        formatted.minute,
                      );
                      horairesList[index][i] =
                          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                    });
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Horaire',
                    prefixIcon: Icon(
                      Icons.access_time,
                      color: Colors.blueAccent,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    horairesList[index][i].isEmpty
                        ? 'Sélectionner une heure'
                        : horairesList[index][i],
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 12),
            ],
            if (horairesList[index].length < 3)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    horairesList[index].add("");
                  });
                },
                icon: Icon(Icons.add, color: Colors.green),
                label: Text("Ajouter un horaire"),
              ),
            SizedBox(height: 12),
            TextField(
              controller: descControllers[index],
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description, color: Colors.blueAccent),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in nomControllers) {
      controller.dispose();
    }
    for (var controller in descControllers) {
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    Text("Nom : $patientName", style: TextStyle(fontSize: 16)),
                    Text(
                      "Prénom : $patientSurname",
                      style: TextStyle(fontSize: 16),
                    ),
                    Text("CIN : $patientCIN", style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            for (int i = 0; i < nomControllers.length; i++)
              medicamentForm("Médicament ${String.fromCharCode(65 + i)}", i),
            if (nomControllers.length < maxMedicaments)
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
