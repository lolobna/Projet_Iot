import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_prescription_page.dart';
import 'PatientProfilePage.dart';
import 'package:flutter_application_1/pages/Medecin_pages/add_patient_page.dart';
import 'package:flutter_application_1/pages/Medecin_pages/medecin_home_page.dart';

class SelectPatientPage extends StatefulWidget {
  @override
  _SelectPatientPageState createState() => _SelectPatientPageState();
}

class _SelectPatientPageState extends State<SelectPatientPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> allPatientsList = [];
  List<Map<String, dynamic>> filteredPatientsList = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPatients();
    searchController.addListener(filterPatients);
  }

  // Récupération des patients
  void fetchPatients() async {
    final medecinId = FirebaseAuth.instance.currentUser?.uid;
    if (medecinId == null) return;

    try {
      final medecinDoc = await _firestore.collection('medecin').doc(medecinId).get();

      if (medecinDoc.exists && medecinDoc.data() != null) {
        final data = medecinDoc.data()!;
        final List<dynamic> patientIds = data['My_patients'] ?? [];

        List<Map<String, dynamic>> loadedPatients = [];

        for (var patientId in patientIds) {
          final patientDoc = await _firestore.collection('patient').doc(patientId).get();

          if (patientDoc.exists && patientDoc.data() != null) {
            final patientDetails = patientDoc.data()!;
            loadedPatients.add({
              "uid": patientId,
              "nom": patientDetails["nom"] ?? "Sans nom",
              "prenom": patientDetails["prenom"] ?? "",
              "cin": patientDetails["CIN"] ?? "",
            });
          }
        }

        setState(() {
          allPatientsList = loadedPatients;
          filteredPatientsList = loadedPatients;
        });
      } else {
        print("Aucun patient lié à ce médecin.");
        setState(() {
          allPatientsList = [];
          filteredPatientsList = [];
        });
      }
    } catch (e) {
      print("Erreur lors de la récupération des patients: $e");
    }
  }

  // Filtrage des patients
  void filterPatients() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredPatientsList = allPatientsList.where((patient) {
        final fullName = "${patient['prenom']} ${patient['nom']}".toLowerCase();
        return fullName.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.blueAccent),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Médecin',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'medecin@example.com',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Accueil'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => MedecinHomePage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.person_add),
              title: Text('Ajouter un patient'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AddPatientPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('Voir les patients'),
              onTap: () {
                Navigator.pop(context); // éviter de pousser la même page
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Déconnexion'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop(); // Fermer le drawer
                Navigator.of(context).pop(); // Revenir à la page de login
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Rechercher un patient",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            "${patient['prenom']} ${patient['nom']}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("CIN: ${patient['cin']}"),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == "Profil") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PatientProfilePage(patientUid: patient['uid']),
                                  ),
                                );
                              } else if (value == "Prescription") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PrescriptionPage(patientUid: patient['uid']),
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
}
