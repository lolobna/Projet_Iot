import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AddPrescriptionPage extends StatefulWidget {
  @override
  _AddPrescriptionPageState createState() => _AddPrescriptionPageState();
}

class _AddPrescriptionPageState extends State<AddPrescriptionPage> {
  final _db = FirebaseDatabase.instance.ref();
  final searchController = TextEditingController();

  String? patientUid;
  List<Map<String, dynamic>> patientResults = [];

  List<TextEditingController> nomControllers =
      List.generate(4, (_) => TextEditingController());
  List<TextEditingController> descControllers =
      List.generate(4, (_) => TextEditingController());
  List<TimeOfDay?> times = List.generate(4, (_) => null);

  // 🔍 Recherche des patients liés au médecin
  Future<void> searchPatientByCIN() async {
    final medecinId = FirebaseAuth.instance.currentUser!.uid;

    final medecinSnapshot = await _db.child('medecins/$medecinId/patients').get();
    final patientIds = (medecinSnapshot.value as Map?)?.keys ?? [];

    final snapshot = await _db.child('users').get();
    List<Map<String, dynamic>> matches = [];

    for (final entry in snapshot.children) {
      final data = entry.value as Map;
      final uid = entry.key!;
      if (patientIds.contains(uid) &&
          data['role'] == 'patient' &&
          (data['CIN'] as String?)?.contains(searchController.text) == true) {
        matches.add({
          'uid': uid,
          'cin': data['CIN'],
          'nom': data['nom'],
          'prenom': data['prenom'],
        });
      }
    }

    setState(() {
      patientResults = matches;
    });
  }

  // 🕓 Sélection d'une heure
  Future<void> selectTime(BuildContext context, int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        times[index] = picked;
      });
    }
  }

  // 💾 Enregistrement de la prescription
  Future<void> submitPrescription() async {
    if (patientUid == null) return;
    final medecinUid = FirebaseAuth.instance.currentUser!.uid;

    final prescription = {
      "medecinId": medecinUid,
      "timestamp": DateTime.now().toIso8601String(),
      "medicamentA": {
        "nom": nomControllers[0].text,
        "heure": times[0]?.format(context) ?? "",
        "desc": descControllers[0].text,
      },
      "medicamentB": {
        "nom": nomControllers[1].text,
        "heure": times[1]?.format(context) ?? "",
        "desc": descControllers[1].text,
      },
      "medicamentC": {
        "nom": nomControllers[2].text,
        "heure": times[2]?.format(context) ?? "",
        "desc": descControllers[2].text,
      },
      "medicamentD": {
        "nom": nomControllers[3].text,
        "heure": times[3]?.format(context) ?? "",
        "desc": descControllers[3].text,
      },
    };

    await _db.child("prescriptions/$patientUid").push().set(prescription);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Prescription enregistrée")));
  }

  Widget medicamentForm(String label, int index) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 8),
          TextField(
            controller: nomControllers[index],
            decoration: InputDecoration(labelText: 'Nom médicament'),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text("Heure de prise : "),
              Text(times[index]?.format(context) ?? "--:--"),
              TextButton(
                onPressed: () => selectTime(context, index),
                child: Text("Choisir l'heure"),
              ),
            ],
          ),
          SizedBox(height: 8),
          TextField(
            controller: descControllers[index],
            decoration: InputDecoration(labelText: 'Description'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ajouter Prescription")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: "Rechercher CIN du patient",
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: searchPatientByCIN,
                ),
              ],
            ),
            ...patientResults.map((patient) => ListTile(
                  title: Text("${patient['prenom']} ${patient['nom']}"),
                  subtitle: Text("CIN: ${patient['cin']}"),
                  onTap: () {
                    setState(() {
                      patientUid = patient['uid'];
                      patientResults.clear(); // cacher la liste après sélection
                    });
                  },
                )),
            if (patientUid != null) ...[
              SizedBox(height: 16),
              medicamentForm("Médicament A", 0),
              medicamentForm("Médicament B", 1),
              medicamentForm("Médicament C", 2),
              medicamentForm("Médicament D", 3),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: submitPrescription,
                child: Text("Valider la prescription"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
