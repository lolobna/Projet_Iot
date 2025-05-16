import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class PrescriptionPage extends StatefulWidget {
  final String patientUid;

  const PrescriptionPage({Key? key, required this.patientUid}) : super(key: key);

  @override
  _PrescriptionPageState createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<PrescriptionPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  List<TextEditingController> nomControllers = [];
  List<List<String>> horairesList = [];
  List<TextEditingController> descControllers = [];
  final int maxMedicaments = 4;

  String patientName = "";
  String patientSurname = "";
  String patientCIN = "";
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchPatientInfo();
    addMedicament();
  }

  Future<void> fetchPatientInfo() async {
    try {
      final snapshot = await _db.collection('patient').doc(widget.patientUid).get();
      if (snapshot.exists) {
        final data = snapshot.data()!;
        setState(() {
          patientName = data["nom"] ?? "Inconnu";
          patientSurname = data["prenom"] ?? "Inconnu";
          patientCIN = data["CIN"] ?? "Inconnu";
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de chargement des données patient")),
      );
    }
  }

  void addMedicament() {
    if (nomControllers.length < maxMedicaments) {
      setState(() {
        nomControllers.add(TextEditingController());
        horairesList.add([""]);
        descControllers.add(TextEditingController());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Maximum $maxMedicaments médicaments autorisés")),
      );
    }
  }

  void removeMedicament(int index) {
    setState(() {
      nomControllers.removeAt(index);
      horairesList.removeAt(index);
      descControllers.removeAt(index);
    });
  }

  Future<void> submitPrescription() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final medecinUid = FirebaseAuth.instance.currentUser?.uid;
      if (medecinUid == null) throw Exception("Médecin non authentifié");

      final Map<String, dynamic> medicaments = {};
      for (int i = 0; i < nomControllers.length; i++) {
        String medKey = String.fromCharCode(65 + i);
        medicaments[medKey] = {
          "medicament_name": nomControllers[i].text.trim(),
          "horaires": horairesList[i].where((h) => h.isNotEmpty).toList(),
          "note": descControllers[i].text.trim(),
          "vide": true,
        };
      }

      final prescription = {
        "medecinId": medecinUid,
        "patientId": widget.patientUid,
        "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        "compartiments": medicaments,
      };

      await FirebaseDatabase.instance.ref().child("prescriptions").push().set(prescription);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Prescription enregistrée avec succès"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      _formKey.currentState!.reset();
      setState(() {
        nomControllers.clear();
        descControllers.clear();
        horairesList.clear();
        addMedicament();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildPatientInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$patientName $patientSurname",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        "CIN: $patientCIN",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Nouvelle prescription",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(DateTime.now()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicamentForm(int index) {
    final letter = String.fromCharCode(65 + index);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Médicament $letter",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                if (nomControllers.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red.shade400),
                    onPressed: () => removeMedicament(index),
                    splashRadius: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nomControllers[index],
              decoration: InputDecoration(
                labelText: 'Nom du médicament',
                prefixIcon: Icon(Icons.medical_services),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un nom de médicament';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            ...List.generate(horairesList[index].length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Horaire ${i + 1}",
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          builder: (context, child) {
                            return MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                alwaysUse24HourFormat: true,
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            horairesList[index][i] =
                                "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.access_time),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                        ),
                        child: Text(
                          horairesList[index][i].isEmpty
                              ? 'Sélectionner une heure'
                              : horairesList[index][i],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (horairesList[index].length < 3)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    horairesList[index].add("");
                  });
                },
                icon: Icon(Icons.add, size: 18),
                label: Text("Ajouter un horaire"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descControllers[index],
              decoration: InputDecoration(
                labelText: 'Instructions spéciales',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in nomControllers) controller.dispose();
    for (var controller in descControllers) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nouvelle prescription"),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.lightBlue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildPatientInfoCard(),
              const SizedBox(height: 24),
              ...List.generate(nomControllers.length, (index) {
                return _buildMedicamentForm(index);
              }),
              const SizedBox(height: 8),
              if (nomControllers.length < maxMedicaments)
                OutlinedButton.icon(
                  onPressed: addMedicament,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Ajouter un médicament"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    side: BorderSide(color: Colors.blue.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : submitPrescription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "ENREGISTRER LA PRESCRIPTION",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}