import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/pages/Medecin_pages/add_patient_page.dart';
import 'package:flutter_application_1/pages/Medecin_pages/SelectPatientPage.dart';

import 'package:flutter_application_1/pages/Medecin_pages/medecin_home_page.dart';

class AddPatientPage extends StatefulWidget {
  @override
  _AddPatientPageState createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final cinController = TextEditingController();
  final _db = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> foundPatients = [];
  List<String> cinSuggestions = [];

  Future<void> searchPatients(String cinInput) async {
    final medecinUid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await _db.child("users/patients").get();
    final addedPatientsSnapshot =
        await _db.child("users/medecins/$medecinUid/patients").get();

    List<Map<String, dynamic>> patients = [];
    List<String> suggestions = [];
    final addedPatients = addedPatientsSnapshot.value as Map? ?? {};

    for (var child in snapshot.children) {
      final data = child.value as Map?;
      if (data != null &&
          data['CIN'] != null &&
          data['CIN'].toString().startsWith(cinInput)) {
        patients.add({
          'uid': child.key!,
          'cin': data['CIN'],
          'nom': data['nom'],
          'prenom': data['prenom'],
          'isAdded': addedPatients.containsKey(child.key!), // Vérifie si ajouté
        });
        suggestions.add(data['CIN'].toString());
      }
    }

    setState(() {
      foundPatients = patients;
      cinSuggestions = suggestions;
    });
  }

  Future<void> addPatientToDoctor(String patientUid) async {
    final medecinUid = FirebaseAuth.instance.currentUser!.uid;
    await _db.child("users/medecins/$medecinUid/patients/$patientUid").set(true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Patient ajouté avec succès !')),
    );

    // Rafraîchir la liste des patients
    searchPatients(cinController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ajouter un patient"),
        backgroundColor:  Colors.blueAccent,
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
     
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Rechercher un patient",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return cinSuggestions.where((cin) =>
                    cin.toLowerCase().startsWith(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selectedCin) {
                cinController.text = selectedCin;
                searchPatients(selectedCin);
              },
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: "Rechercher par CIN",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: searchPatients,
                );
              },
            ),
            SizedBox(height: 20),
            Expanded(
              child: foundPatients.isEmpty
                  ? Center(
                      child: Text(
                        "Aucun patient trouvé",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: foundPatients.length,
                      itemBuilder: (_, index) {
                        final patient = foundPatients[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:  Colors.blueAccent,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text("${patient['nom']} ${patient['prenom']}"),
                            subtitle: Text("CIN: ${patient['cin']}"),
                            trailing: patient['isAdded']
                                ? Icon(Icons.check, color: Colors.green) // Déjà ajouté
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
