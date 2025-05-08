import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_prescription_page.dart';

class PatientProfilePage extends StatefulWidget {
  final String patientUid;

  const PatientProfilePage({Key? key, required this.patientUid})
    : super(key: key);

  @override
  _PatientProfilePageState createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? patientData;
  List<Map<String, dynamic>> prescriptions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPatientData();
  }

  void fetchPatientData() async {
    try {
      DocumentSnapshot patientSnapshot =
          await _firestore.collection('patient').doc(widget.patientUid).get();
      if (patientSnapshot.exists) {
        setState(() {
          patientData = patientSnapshot.data() as Map<String, dynamic>;
        });
        fetchPrescriptions();
      } else {
        setState(() {
          isLoading = false;
          patientData = null;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void fetchPrescriptions() async {
    try {
      QuerySnapshot prescriptionsSnapshot =
          await _firestore
              .collection('patient')
              .doc(widget.patientUid)
              .collection('prescriptions')
              .get();

      if (prescriptionsSnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> loadedPrescriptions = [];

        for (var doc in prescriptionsSnapshot.docs) {
          var prescription = doc.data() as Map<String, dynamic>;
          String? medecinNom;
          String? medecinPrenom;
          final medecinId = prescription['medecinId'];

          // Fetch doctor data if medecinId exists
          if (medecinId != null && medecinId.isNotEmpty) {
            DocumentSnapshot medecinSnapshot =
                await _firestore.collection('medecin').doc(medecinId).get();
            if (medecinSnapshot.exists) {
              var medecinData = medecinSnapshot.data() as Map<String, dynamic>;
              medecinNom = medecinData['nom'];
              medecinPrenom = medecinData['prenom'];
            }
          }

          var compartiments =
              prescription['compartiments']
                  ?.map(
                    (compartiment) => {
                      'idcompartiment': compartiment['idcompartiment'],
                      'name': compartiment['name'],
                      'madicament_name': compartiment['madicament_name'],
                      'horaires': compartiment['horaires'],
                      'statut_prise': compartiment['statut_prise'],
                    },
                  )
                  .toList();

          loadedPrescriptions.add({
            'prescriptionId':
                doc.id, // Adding the prescriptionId from Firestore
            'date': prescription['date'],
            'medecinNom': medecinNom,
            'medecinPrenom': medecinPrenom,
            'compartiments': compartiments,
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
                  builder:
                      (context) =>
                          PrescriptionPage(patientUid: widget.patientUid),
                ),
              );
            },
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : patientData == null
              ? Center(child: Text("Données du patient non trouvées."))
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Displaying patient data
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
                                      if (prescription['compartiments'] != null)
                                        ...List.generate(
                                          (prescription['compartiments']
                                                  as List)
                                              .length,
                                          (i) {
                                            final compartiment =
                                                (prescription['compartiments']
                                                    as List)[i];

                                            if (compartiment['name'] == null ||
                                                compartiment['name']
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
                                                        "Médicament : ${compartiment['madicament_name']}",
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 6),
                                                  if (compartiment['horaires'] !=
                                                      null)
                                                    ...List.generate(
                                                      (compartiment['horaires']
                                                              as List)
                                                          .length,
                                                      (j) {
                                                        final horaire =
                                                            (compartiment['horaires']
                                                                as List)[j];
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 2.0,
                                                                horizontal:
                                                                    12.0,
                                                              ),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .access_time,
                                                                size: 18,
                                                                color:
                                                                    Colors
                                                                        .grey[700],
                                                              ),
                                                              SizedBox(
                                                                width: 6,
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  "${horaire['description'] ?? 'Non spécifiée'} à ${horaire['horaire'] ?? 'Non spécifié'}",
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
