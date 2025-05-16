import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'add_prescription_page.dart';
import 'HistoriquePrisesPage.dart';

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
      final databaseRef = FirebaseDatabase.instance.ref();
      final prescriptionsSnapshot =
          await databaseRef.child('prescriptions').get();

      if (prescriptionsSnapshot.exists) {
        List<Map<String, dynamic>> loadedPrescriptions = [];

        prescriptionsSnapshot.children.forEach((doc) {
          final prescription = Map<String, dynamic>.from(doc.value as Map);

          if (prescription['patientId'] == widget.patientUid) {
            final compartimentsMap = prescription['compartiments'] as Map;
            final compartiments =
                compartimentsMap.entries.map((entry) {
                  final compartiment = Map<String, dynamic>.from(
                    entry.value as Map,
                  );
                  final horaires =
                      compartiment['horaires'] is Map
                          ? (compartiment['horaires'] as Map).values.toList()
                          : (compartiment['horaires'] as List)
                              .map((h) => h.toString())
                              .toList();

                  return {
                    'idcompartiment': entry.key,
                    'madicament_name': compartiment['medicament_name'],
                    'horaires': horaires,
                    'note': compartiment['note'],
                  };
                }).toList();

            loadedPrescriptions.add({
              'prescriptionId': doc.key,
              'date': prescription['date'],
              'medecinId': prescription['medecinId'],
              'compartiments': compartiments,
            });
          }
        });

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
      print('Erreur lors de la récupération des prescriptions : $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<double> _calculatePrisePercentage() async {
    try {
      final databaseRef = FirebaseDatabase.instance.ref();
      final prisesSnapshot = await databaseRef.child('prises').get();

      if (prisesSnapshot.exists) {
        int totalPrises = 0;
        int validPrises = 0;

        prisesSnapshot.children.forEach((doc) {
          final prise = doc.value as Map<dynamic, dynamic>;

          // Vérifier si la prise appartient au patient actuel
          if (prise['patientId'] == widget.patientUid) {
            totalPrises++;
            if (prise['priseValide'] == true) {
              validPrises++;
            }
          }
        });

        return totalPrises > 0 ? (validPrises / totalPrises) * 100 : 0.0;
      } else {
        return 0.0;
      }
    } catch (e) {
      print('Erreur lors du calcul des prises : $e');
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profil Patient",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            tooltip: "Ajouter une prescription",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PrescriptionPage(patientUid: widget.patientUid),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : patientData == null
              ? Center(child: Text("Données du patient non trouvées."))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header arrondi
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade700, Colors.lightBlue.shade400],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(32),
                          ),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person, size: 48, color: Colors.blue.shade700),
                            ),
                            SizedBox(height: 12),
                            Text(
                              patientData!['nom'] ?? 'Inconnu',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              patientData!['email'] ?? 'Email non fourni',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildInfoItem(
                                  context,
                                  Icons.phone,
                                  patientData!['telephone'] ?? 'Non fourni',
                                  'Téléphone',
                                ),
                                SizedBox(width: 24),
                                _buildInfoItem(
                                  context,
                                  Icons.calendar_today,
                                  '25 ans', // Exemple d'âge
                                  'Âge',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18),
                      // Pourcentage de prises valides
                      FutureBuilder<double>(
                        future: _calculatePrisePercentage(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final percentage = snapshot.data ?? 0.0;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HistoriquePrisesPage(
                                    patientUid: widget.patientUid,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 24),
                                child: Row(
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 54,
                                          height: 54,
                                          child: CircularProgressIndicator(
                                            value: percentage / 100,
                                            strokeWidth: 7,
                                            backgroundColor: Colors.blue.shade100,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          "${percentage.toStringAsFixed(0)}%",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: 18),
                                    Expanded(
                                      child: Text(
                                        "Prises valides sur l'ensemble",
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, color: Colors.blue.shade700, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 18),
                      // Prescriptions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Prescriptions médicales",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      if (prescriptions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.medication_outlined,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Aucune prescription trouvée",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...prescriptions.map((prescription) =>
                          _buildPrescriptionCard(context, prescription)
                        ).toList(),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blue.shade700),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildPrescriptionCard(
    BuildContext context,
    Map<String, dynamic> prescription,
  ) {
    final theme = Theme.of(context);
    final compartiments = (prescription['compartiments'] as List?) ?? [];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue.shade700, size: 20),
                SizedBox(width: 10),
                Text(
                  "Prescription du ${prescription['date'] ?? 'Non spécifiée'}",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            // Affichage 2 compartiments par ligne
            for (int i = 0; i < compartiments.length; i += 2)
              Row(
                children: [
                  Expanded(child: _buildCompCard(theme, compartiments[i])),
                  SizedBox(width: 10),
                  if (i + 1 < compartiments.length)
                    Expanded(child: _buildCompCard(theme, compartiments[i + 1]))
                  else
                    Expanded(child: SizedBox()),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompCard(ThemeData theme, Map compartiment) {
    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication, color: Colors.blue.shade700, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    compartiment['madicament_name'] ?? 'Non spécifié',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            if (compartiment['horaires'] != null)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (compartiment['horaires'] as List).map<Widget>((horaire) {
                  return Chip(
                    label: Text(
                      horaire.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.blue.shade600,
                    shape: StadiumBorder(),
                  );
                }).toList(),
              ),
            if (compartiment['note'] != null &&
                compartiment['note'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        compartiment['note'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
