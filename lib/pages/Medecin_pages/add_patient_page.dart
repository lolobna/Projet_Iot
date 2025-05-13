import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/pages/Medecin_pages/add_patient_page.dart';
import 'package:flutter_application_1/pages/Medecin_pages/SelectPatientPage.dart';
import 'package:flutter_application_1/pages/Medecin_pages/medecin_home_page.dart';

class AddPatientPage extends StatefulWidget {
  @override
  _AddPatientPageState createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final TextEditingController cinController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> foundPatients = [];
  List<String> cinSuggestions = [];

  /// Rechercher des patients par CIN
  Future<void> searchPatients(String cinInput) async {
    final medecinUid = FirebaseAuth.instance.currentUser!.uid;

    // Récupérer le document du médecin
    final medecinDoc = await _firestore.collection("medecin").doc(medecinUid).get();
    List<dynamic> addedPatients = [];

    if (medecinDoc.exists && medecinDoc.data() != null) {
      addedPatients = medecinDoc.data()!['My_patients'] ?? [];
    }

    final lesPatients = await _firestore.collection("patient").get();
    List<Map<String, dynamic>> patients = [];
    List<String> suggestions = [];

    for (var doc in lesPatients.docs) {
      final data = doc.data();
      final cin = data['cin']?.toString() ?? '';

      if (cin.startsWith(cinInput)) {
        patients.add({
          'uid': doc.id,
          'cin': cin,
          'nom': data['nom'],
          'prenom': data['prenom'],
         'isAdded': addedPatients.contains(doc.id),

        });
        suggestions.add(cin);
      }
    }

    setState(() {
      foundPatients = patients;
      cinSuggestions = suggestions.toSet().toList(); // éviter les doublons
    });
  }

  /// Ajouter un patient à la liste du médecin
  Future<void> addPatientToDoctor(String patientUid) async {
    final medecinUid = FirebaseAuth.instance.currentUser!.uid;
    final patientDoc = await _firestore.collection("patient").doc(patientUid).get();

    if (!patientDoc.exists) return;

    final patientData = patientDoc.data();
    final String patientToAdd = patientUid;


    final medecinRef = _firestore.collection("medecin").doc(medecinUid);
    final medecinDoc = await medecinRef.get();
    List<dynamic> myPatients = medecinDoc.data()?['My_patients'] ?? [];

    // Éviter d'ajouter deux fois le même patient
    final alreadyAdded = myPatients.contains(patientUid);

    if (!alreadyAdded) {
      myPatients.add(patientToAdd);
      await medecinRef.update({'My_patients': myPatients});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Patient ajouté avec succès !')),
      );
      searchPatients(cinController.text); // mettre à jour l'affichage
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ce patient est déjà ajouté.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ajouter un patient"),
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
                  Text('Médecin',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('medecin@example.com',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Accueil'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MedecinHomePage())),
            ),
            ListTile(
              leading: Icon(Icons.person_add),
              title: Text('Ajouter un patient'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddPatientPage())),
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('Voir les patients'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SelectPatientPage())),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Déconnexion'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Rechercher un patient",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue value) {
                if (value.text.isEmpty) return const Iterable<String>.empty();
                return cinSuggestions.where(
                    (cin) => cin.toLowerCase().startsWith(value.text.toLowerCase()));
              },
              onSelected: (String selectedCin) {
                cinController.text = selectedCin;
                searchPatients(selectedCin);
              },
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                cinController.addListener(() {
                  searchPatients(cinController.text);
                });
                return TextField(
                  controller: cinController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: "Rechercher par CIN",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            Expanded(
              child: foundPatients.isEmpty
                  ? Center(
                      child: Text("Aucun patient trouvé",
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    )
                  : ListView.builder(
                      itemCount: foundPatients.length,
                      itemBuilder: (_, index) {
                        final patient = foundPatients[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text("${patient['nom']} ${patient['prenom']}"),
                            subtitle: Text("CIN: ${patient['CIN']}"),
                            trailing: patient['isAdded']
                                ? Icon(Icons.check, color: Colors.green)
                                : IconButton(
                                    icon: Icon(Icons.person_add, color: Colors.teal),
                                    onPressed: () => addPatientToDoctor(patient['uid']),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
