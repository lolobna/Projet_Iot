import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/PrescriptionService.dart';
import '../services/notification_service.dart';


class PatientHomePage extends StatefulWidget {
  @override
  _PatientHomePageState createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  @override
  @override
void initState() {
  super.initState();
  schedulePrescriptionReminders();
  listenForMedicationUpdates(); // ✅ ajouter ceci
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Accueil Patient')),
      body: Center(child: Text('Bienvenue Patient')),
    );
  }
}



