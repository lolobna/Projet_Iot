import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'add_prescription_page.dart';

import 'package:flutter_application_1/pages/Medecin_pages/medecin_home_page.dart';
import 'package:flutter_application_1/pages/Medecin_pages/add_patient_page.dart';
import 'package:flutter_application_1/pages/Medecin_pages/SelectPatientPage.dart';

class PatientProfilePage extends StatefulWidget {
  final String patientUid;

  const PatientProfilePage({Key? key, required this.patientUid})
    : super(key: key);

  @override
  _PatientProfilePageState createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  Map<String, dynamic>? patientData;
  List<Map<String, dynamic>> prescriptions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPatientData();
  }

  void fetchPatientData() async {
    final snapshot =
        await _db.child('users/patients/${widget.patientUid}').get();
    if (snapshot.exists && snapshot.value != null) {
      setState(() {
        patientData = Map<String, dynamic>.from(snapshot.value as Map);
      });
      fetchPrescriptions();
    } else {
      setState(() {
        isLoading = false;
        patientData = null;
      });
    }
  }

  void fetchPrescriptions() async {
    try {
      final prescriptionsSnapshot =
          await _db.child('users/patients/${widget.patientUid}/prescriptions').get();
      if (prescriptionsSnapshot.exists && prescriptionsSnapshot.value != null) {
        final data = Map<String, dynamic>.from(prescriptionsSnapshot.value as Map);
        final List<Map<String, dynamic>> loadedPrescriptions = [];

        for (var entry in data.entries) {
          final prescription = Map<String, dynamic>.from(entry.value as Map);

          // Récupérer les informations du médecin
          final medecinId = prescription['medecinId'];
          String? medecinNom;
          String? medecinPrenom;

          if (medecinId != null) {
            final medecinSnapshot = await _db.child('users/medecins/$medecinId').get();
            if (medecinSnapshot.exists && medecinSnapshot.value != null) {
              final medecinData = Map<String, dynamic>.from(medecinSnapshot.value as Map);
              medecinNom = medecinData['nom'];
              medecinPrenom = medecinData['prenom'];
            }
          }

          final medicaments = (prescription['medicaments'] as Map?)?.entries.map((medicamentEntry) {
            final medicament = Map<String, dynamic>.from(medicamentEntry.value as Map);
            return {
              'nom': medicament['nom'],
              'prises': (medicament['prises'] as List<dynamic>?)?.map((prise) {
                return Map<String, dynamic>.from(prise as Map);
              }).toList(),
            };
          }).toList();

          loadedPrescriptions.add({
            'date': prescription['date'],
            'medecinNom': medecinNom,
            'medecinPrenom': medecinPrenom,
            'medicaments': medicaments,
          });
        }

        setState(() {
          prescriptions = loadedPrescriptions;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profil du patient"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            tooltip: "Ajouter une prescription",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrescriptionPage(patientUid: widget.patientUid),
                ),
              );
            },
          ),
        ],
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
     
    body: isLoading
          ? Center(child: CircularProgressIndicator())
          : patientData == null
              ? Center(child: Text("Données du patient non trouvées."))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.blueAccent,
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.person, color: Colors.blueAccent),
                                    SizedBox(width: 10),
                                    Text(
                                      "Nom : ${patientData!['nom'] ?? 'Inconnu'}",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.email, color: Colors.blueAccent),
                                    SizedBox(width: 10),
                                    Text(
                                      "Email : ${patientData!['email'] ?? 'Non fourni'}",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.phone, color: Colors.blueAccent),
                                    SizedBox(width: 10),
                                    Text(
                                      "Téléphone : ${patientData!['telephone'] ?? 'Non fourni'}",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Prescriptions :",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        prescriptions.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text("Aucune prescription trouvée."),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: prescriptions.length,
                                itemBuilder: (context, index) {
                                  final prescription = prescriptions[index];
                                  return Card(
                                    margin: EdgeInsets.symmetric(vertical: 10.0),
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ListTile(
                                            leading: Icon(
                                              Icons.calendar_today,
                                              color: Colors.blueAccent,
                                            ),
                                            title: Text(
                                              "Date : ${prescription['date'] ?? 'Non spécifiée'}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Text(
                                              "Médecin : ${prescription['medecinPrenom'] ?? ''} ${prescription['medecinNom'] ?? ''}",
                                            ),
                                          ),
                                          Divider(),
                                          if (prescription['medicaments'] != null)
                                            ...List.generate(
                                              (prescription['medicaments']
                                                      as List)
                                                  .length,
                                              (i) {
                                                final medicament =
                                                    (prescription['medicaments']
                                                        as List)[i];

                                                if (medicament['nom'] == null ||
                                                    medicament['nom']
                                                        .toString()
                                                        .trim()
                                                        .isEmpty) {
                                                  return SizedBox.shrink();
                                                }

                                                return Padding(
                                                  padding: const EdgeInsets.only(
                                                    left: 8.0,
                                                    bottom: 10,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.medication,
                                                            color: Colors.green,
                                                          ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            "Médicament : ${medicament['nom']}",
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight.w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 6),
                                                      if (medicament['prises'] !=
                                                          null)
                                                        ...List.generate(
                                                          (medicament['prises']
                                                                  as List)
                                                              .length,
                                                          (j) {
                                                            final prise =
                                                                (medicament[
                                                                        'prises']
                                                                    as List)[j];
                                                            return Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                vertical: 2.0,
                                                                horizontal: 12.0,
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .access_time,
                                                                    size: 18,
                                                                    color: Colors
                                                                            .grey[
                                                                        700],
                                                                  ),
                                                                  SizedBox(
                                                                    width: 6,
                                                                  ),
                                                                  Expanded(
                                                                    child: Text(
                                                                      "${prise['description'] ?? 'Non spécifiée'} à ${prise['horaire'] ?? 'Non spécifié'}",
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
