import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/add_patient_page.dart';
import 'package:flutter_application_1/pages/add_prescription_page.dart';

class MedecinHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Accueil Médecin')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddPatientPage()),
                );
              },
              child: Text('Aller à Page AddPatientPage'),
            ),
            SizedBox(height: 20), // Pour espacer les boutons
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddPrescriptionPage()),
                );
              },
              child: Text('Aller à Page AddPrescriptionPage'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: MedecinHomePage(),
  ));
}
