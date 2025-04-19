import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'add_prescription_page.dart';
import 'PatientProfilePage.dart';

import 'package:flutter_application_1/pages/Medecin_pages/add_patient_page.dart';
import 'package:flutter_application_1/pages/Medecin_pages/SelectPatientPage.dart';

import 'package:flutter_application_1/pages/Medecin_pages/medecin_home_page.dart';

class SelectPatientPage extends StatefulWidget {
  @override
  _SelectPatientPageState createState() => _SelectPatientPageState();
}

class _SelectPatientPageState extends State<SelectPatientPage> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> patientsList = [];
  List<Map<String, dynamic>> filteredPatientsList = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPatients();
    searchController.addListener(() {
      filterPatients();
    });
  }

  void fetchPatients() async {
    final medecinId = FirebaseAuth.instance.currentUser?.uid;
    if (medecinId == null) return;

    final patientsRef = _db.child('users/medecins/$medecinId/patients');
    final patientsSnapshot = await patientsRef.get();

    if (patientsSnapshot.exists && patientsSnapshot.value != null) {
      final patientIdsMap = Map<String, dynamic>.from(patientsSnapshot.value as Map);

      List<Map<String, dynamic>> loadedPatients = [];

      for (String patientUid in patientIdsMap.keys) {
        final patientSnapshot = await _db.child('users/patients/$patientUid').get();
        if (patientSnapshot.exists && patientSnapshot.value != null) {
          final patientData = Map<String, dynamic>.from(patientSnapshot.value as Map);

          loadedPatients.add({
            "uid": patientUid,
            "nom": patientData["nom"] ?? "Sans nom",
            "prenom": patientData["prenom"] ?? "",
            "cin": patientData["CIN"] ?? "",
          });
        }
      }

      setState(() {
        patientsList = loadedPatients;
        filteredPatientsList = loadedPatients; // Initialement, tous les patients sont affichés
      });
    } else {
      print("Aucun patient lié à ce médecin.");
      setState(() {
        patientsList = [];
        filteredPatientsList = [];
      });
    }
  }

  void filterPatients() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredPatientsList = patientsList.where((patient) {
        final fullName = "${patient['prenom']} ${patient['nom']}".toLowerCase();
        return fullName.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sélectionner un patient"),
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
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Rechercher un patient",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // Liste des patients
          Expanded(
            child: filteredPatientsList.isEmpty
                ? Center(
                    child: Text(
                      "Aucun patient trouvé.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredPatientsList.length,
                    itemBuilder: (context, index) {
                      final patient = filteredPatientsList[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            "${patient['prenom']} ${patient['nom']}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "CIN: ${patient['cin']}", // Correction : affichage du CIN au lieu de l'UID
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == "Profil") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PatientProfilePage(
                                      patientUid: patient['uid'],
                                    ),
                                  ),
                                );
                              } else if (value == "Prescription") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PrescriptionPage(
                                      patientUid: patient['uid'],
                                    ),
                                  ),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: "Profil",
                                child: Row(
                                  children: [
                                    Icon(Icons.person, color: Colors.blueAccent),
                                    SizedBox(width: 8),
                                    Text("Profil"),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: "Prescription",
                                child: Row(
                                  children: [
                                    Icon(Icons.note_add, color: Colors.blueAccent),
                                    SizedBox(width: 8),
                                    Text("Prescription"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}