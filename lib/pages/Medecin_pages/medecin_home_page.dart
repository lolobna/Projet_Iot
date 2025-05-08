import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/pages/Medecin_pages/add_patient_page.dart';
import 'package:flutter_application_1/pages/Medecin_pages/SelectPatientPage.dart';

class MedecinHomePage extends StatefulWidget {
  @override
  _MedecinHomePageState createState() => _MedecinHomePageState();
}

class _MedecinHomePageState extends State<MedecinHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchPatients() async {
    final medecinId = FirebaseAuth.instance.currentUser?.uid;
    if (medecinId == null) return [];

    final medecinDoc = await _firestore.collection('medecin').doc(medecinId).get();

    if (!medecinDoc.exists || !(medecinDoc.data()?['patient'] is List)) return [];

    final List<dynamic> patientsList = medecinDoc.data()?['patients'];

    List<Map<String, dynamic>> loadedPatients = [];

    for (var patientRef in patientsList) {
      final patientUid = patientRef['uid'];
      final patientDoc = await _firestore.collection('patient').doc(patientUid).get();

      if (patientDoc.exists) {
        final patientData = patientDoc.data()!;
        loadedPatients.add({
          "uid": patientUid,
          "nom": patientData["nom"] ?? "Sans nom",
          "prenom": patientData["prenom"] ?? "",
          "cin": patientData["cin"] ?? "",
          "pourcentagePrise": patientData["pourcentagePrise"] ?? 0,
        });
      }
    }

    return loadedPatients;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accueil Médecin'),
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
                    'medecin@example.com', // À remplacer dynamiquement si nécessaire
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
                FirebaseAuth.instance.signOut();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchPatients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur lors du chargement des patients."));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Aucun patient trouvé."));
          } else {
            final patients = snapshot.data!;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Nom')),
                  DataColumn(label: Text('CIN')),
                  DataColumn(label: Text('Pourcentage de prise')),
                  DataColumn(label: Text('État')),
                ],
                rows: patients.map((patient) {
                  final pourcentagePrise = (patient['pourcentagePrise'] ?? 0).toDouble();
                  final etat = pourcentagePrise > 90 ? "Bien" : "Mal";

                  return DataRow(cells: [
                    DataCell(Text("${patient['nom']} ${patient['prenom']}")),
                    DataCell(Text(patient['cin'])),
                    DataCell(Text("${pourcentagePrise.toStringAsFixed(2)}%")),
                    DataCell(Text(etat)),
                  ]);
                }).toList(),
              ),
            );
          }
        },
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: MedecinHomePage(),
  ));
}
