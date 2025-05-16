import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class HistoriquePrisesPage extends StatefulWidget {
  final String patientUid;

  const HistoriquePrisesPage({Key? key, required this.patientUid})
    : super(key: key);

  @override
  _HistoriquePrisesPageState createState() => _HistoriquePrisesPageState();
}

class _HistoriquePrisesPageState extends State<HistoriquePrisesPage> {
  List<String> compartments = [
    'Tous',
    'A',
    'B',
    'C',
    'D',
  ]; // Liste des compartiments
  String selectedCompartment = 'Tous'; // Compartiment sélectionné par défaut
  DateTime selectedDate =
      DateTime.now(); // Date sélectionnée (par défaut : aujourd'hui)

  @override
  void initState() {
    super.initState();
    _fetchCompartments();
  }

  Future<List<Map<String, dynamic>>> _fetchPrises() async {
    try {
      final databaseRef = FirebaseDatabase.instance.ref();
      final prisesSnapshot = await databaseRef.child('prises').get();

      if (prisesSnapshot.exists) {
        List<Map<String, dynamic>> prises = [];

        prisesSnapshot.children.forEach((doc) {
          final prise = doc.value as Map<dynamic, dynamic>;

          // Vérifier si la prise appartient au patient actuel et correspond à la date sélectionnée
          if (prise['patientId'] == widget.patientUid &&
              (selectedCompartment == 'Tous' ||
                  prise['compartiment'] == selectedCompartment) &&
              DateFormat('yyyy-MM-dd').format(DateTime.parse(prise['date'])) ==
                  DateFormat('yyyy-MM-dd').format(selectedDate)) {
            prises.add({
              'compartiment': prise['compartiment'],
              'date': prise['date'],
              'priseValide': prise['priseValide'],
              'retard': prise['retard'],
            });
          }
        });

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

        prisesSnapshot.children.forEach((doc) {
          final prise = doc.value as Map<dynamic, dynamic>;

          // Vérifier si la prise appartient au patient actuel
          if (prise['patientId'] == widget.patientUid) {
            uniqueCompartments.add(prise['compartiment']);
          }
        });

        setState(() {
          compartments = ['Tous', ...uniqueCompartments.toList()];
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

          // Vérifier si la prescription appartient au patient actuel
          if (prescription['patientId'] == widget.patientUid) {
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

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Filtrer par compartiment : ",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          DropdownButton<String>(
            value: selectedCompartment,
            items:
                compartments
                    .map(
                      (compartment) => DropdownMenuItem(
                        value: compartment,
                        child: Text(compartment),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              setState(() {
                selectedCompartment = value!;
              });
            },
          ),
        ],
      ),
    );
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

    if (prise['priseValide'] == true) {
      icon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (prise['retard'] > 0) {
      icon = Icons.warning_amber_rounded;
      iconColor = Colors.orange;
    } else {
      icon = Icons.cancel;
      iconColor = Colors.red;
    }

    // Heure réelle de prise
    final priseDate = DateTime.parse(prise['date']);
    // Retard en minutes (peut être null)
    final retard = (prise['retard'] ?? 0) as int;
    // Calcul de l'heure théorique
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
                  Text(
                    "Heure réelle : ${DateFormat('HH:mm').format(priseDate)}",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  Text(
                    "Heure prévue : ${DateFormat('HH:mm').format(horaireTheorique)}",
                    style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                  ),
                  if (prise['retard'] != null)
                    Text(
                      "Retard : ${prise['retard']} min",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionInfo(Map<String, dynamic> prescription) {
    // prescription correspond à prescription['compartiments']
    if (selectedCompartment == 'Tous' ||
        !prescription.containsKey(selectedCompartment)) {
      return SizedBox(); // Ne rien afficher si "Tous" est sélectionné ou si le compartiment n'existe pas
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
    final bool isVide = compartimentDetails['vide'] ?? false;

    return Card(
  elevation: 6,
  margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
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
              Icon(Icons.medication_rounded, color: Colors.blueAccent, size: 30),
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
              Icon(Icons.local_pharmacy, color: Colors.deepPurple, size: 20),
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
            _buildFilterChips(), // Boutons pour sélectionner le compartiment
            _buildDateSelector(), // Sélecteur de date
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

                // prescription correspond à prescription['compartiments']
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
                    child: Text(
                      "Aucune prise trouvée.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
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
