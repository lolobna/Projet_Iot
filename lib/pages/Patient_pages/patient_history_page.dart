import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class PatientHistoryPage extends StatefulWidget {
  const PatientHistoryPage({Key? key}) : super(key: key);

  @override
  State<PatientHistoryPage> createState() => _PatientHistoryPageState();
}

class _PatientHistoryPageState extends State<PatientHistoryPage> {
  List<String> compartments = ['Tous'];
  String selectedCompartment = 'Tous';
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchCompartments();
  }

  String get userId => FirebaseAuth.instance.currentUser!.uid;

  Future<List<Map<String, dynamic>>> _fetchPrises() async {
    try {
      final databaseRef = FirebaseDatabase.instance.ref();
      final prisesSnapshot = await databaseRef.child('prises').get();

      if (prisesSnapshot.exists) {
        List<Map<String, dynamic>> prises = [];

        for (var doc in prisesSnapshot.children) {
          final prise = Map<String, dynamic>.from(doc.value as Map);

          if (prise['patientId'] == userId && prise.containsKey('date')) {
            final priseDate = DateTime.parse(prise['date']);

            if (DateFormat('yyyy-MM-dd').format(priseDate) ==
                DateFormat('yyyy-MM-dd').format(selectedDate)) {
              if (selectedCompartment == 'Tous' ||
                  prise['compartiment'] == selectedCompartment) {
                prises.add({
                  'compartiment': prise['compartiment'],
                  'date': prise['date'],
                  'status': prise['status'],
                  'retard': prise['retard'],
                });
              }
            }
          }
        }

        prises.sort((a, b) => a['date'].compareTo(b['date']));
        return prises;
      } else {
        return [];
      }
    } catch (e) {
      print('Erreur lors de la récupération des prises : $e');
      return [];
    }
  }

  Future<void> _fetchCompartments() async {
    try {
      final databaseRef = FirebaseDatabase.instance.ref();
      final prisesSnapshot = await databaseRef.child('prises').get();

      if (prisesSnapshot.exists) {
        Set<String> uniqueCompartments = {};

        for (var doc in prisesSnapshot.children) {
          final prise = Map<String, dynamic>.from(doc.value as Map);
          if (prise['patientId'] == userId && prise['compartiment'] != null) {
            uniqueCompartments.add(prise['compartiment'].toString());
          }
        }

        setState(() {
          compartments = ['Tous', ...uniqueCompartments.toList()..sort()];
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération des compartiments : $e');
    }
  }

  Future<Map<String, dynamic>> _fetchPrescription() async {
    try {
      final databaseRef = FirebaseDatabase.instance.ref();
      final prescriptionsSnapshot =
          await databaseRef.child('prescriptions').get();

      if (prescriptionsSnapshot.exists) {
        for (var doc in prescriptionsSnapshot.children) {
          final prescription = Map<String, dynamic>.from(doc.value as Map);

          if (prescription['patientId'] == userId) {
            return Map<String, dynamic>.from(
              prescription['compartiments'] as Map,
            );
          }
        }
      }

      return {};
    } catch (e) {
      print('Erreur lors de la récupération des prescriptions : $e');
      return {};
    }
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children:
            compartments.map((compartment) {
              final isSelected = selectedCompartment == compartment;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(
                    compartment,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.blue.shade800,
                  backgroundColor: Colors.grey.shade200,
                  onSelected: (selected) {
                    setState(() {
                      selectedCompartment = compartment;
                    });
                  },
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                selectedDate = selectedDate.subtract(Duration(days: 1));
              });
            },
          ),
          Text(
            DateFormat('yyyy-MM-dd').format(selectedDate),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () {
              setState(() {
                selectedDate = selectedDate.add(Duration(days: 1));
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPriseCard(Map<String, dynamic> prise) {
    IconData icon;
    Color iconColor;
    final status = (prise['status'] ?? '').toString().toLowerCase();

    if (status == 'valide' || status == 'respectée' || status == 'respecte') {
      icon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (status == 'en retard') {
      icon = Icons.warning_amber_rounded;
      iconColor = Colors.orange;
    } else {
      icon = Icons.cancel;
      iconColor = Colors.red;
    }

    final priseDate = DateTime.parse(prise['date']);
    final retard = (prise['retard'] ?? 0) as int;
    final horaireTheorique = priseDate.subtract(Duration(minutes: retard));

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Compartiment : ${prise['compartiment']}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Pour raté : n'affiche que l'heure prévue
                  if (status == 'raté' || status == 'ratée' || status == 'manquée' || status == 'manque')
                    Text(
                      "Heure prévue : ${DateFormat('HH:mm').format(horaireTheorique)}",
                      style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                    )
                  else ...[
                    Text(
                      "Heure réelle : ${DateFormat('HH:mm').format(priseDate)}",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    Text(
                      "Heure prévue : ${DateFormat('HH:mm').format(horaireTheorique)}",
                      style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                    ),
                    if ((status == 'valide' || status == 'en retard') && retard > 0)
                      Text(
                        "Retard : $retard min",
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionInfo(Map<String, dynamic> prescription) {
    if (selectedCompartment == 'Tous' ||
        !prescription.containsKey(selectedCompartment)) {
      return SizedBox();
    }

    final compartimentDetails = Map<String, dynamic>.from(
      prescription[selectedCompartment] as Map,
    );

    final String medicamentName =
        compartimentDetails['medicament_name'] ?? 'Inconnu';
    final horaires = compartimentDetails['horaires'];
    final List horairesList =
        horaires is List
            ? horaires
            : (horaires is Map ? horaires.values.toList() : []);
    final String note = compartimentDetails['note'] ?? 'Aucune note';

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.blueGrey.withOpacity(0.3),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.medication_rounded,
                    color: Colors.blueAccent,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Compartiment : $selectedCompartment",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.local_pharmacy,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Médicament : $medicamentName",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.teal, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Horaires : ${horairesList.join(', ')}",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.note_alt_outlined, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Note : $note",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Historique des Prises"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildFilterChips(),
            _buildDateSelector(),
            FutureBuilder<Map<String, dynamic>>(
              future: _fetchPrescription(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Erreur lors du chargement des prescriptions.",
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                final prescription = snapshot.data ?? {};

                if (prescription.isEmpty) {
                  return Center(
                    child: Text(
                      "Aucune prescription trouvée.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return _buildPrescriptionInfo(prescription);
              },
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchPrises(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Erreur lors du chargement des données.",
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                final prises = snapshot.data ?? [];

                if (prises.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        "Aucune prise trouvée pour cette date.",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: prises.length,
                  itemBuilder: (context, index) {
                    final prise = prises[index];
                    return _buildPriseCard(prise);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
