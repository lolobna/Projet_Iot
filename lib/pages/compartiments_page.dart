import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CompartimentsPage extends StatefulWidget {
  const CompartimentsPage({super.key});

  @override
  State<CompartimentsPage> createState() => _CompartimentsPageState();
}

class _CompartimentsPageState extends State<CompartimentsPage> {
  final databaseRef = FirebaseDatabase.instance.ref();
  Map<String, dynamic> compartimentsData = {};

  @override
  void initState() {
    super.initState();
    listenToDatabase();
  }

  void listenToDatabase() {
    for (var c in ['A', 'B', 'C', 'D']) {
      databaseRef.child(c).onValue.listen((event) {
        final data = event.snapshot.value as Map?;
        if (data != null) {
          setState(() {
            compartimentsData[c] = data;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("État des Compartiments")),
      body: ListView(
        children: ['A', 'B', 'C', 'D'].map((comp) {
          final data = compartimentsData[comp] ?? {'etat': 'inconnu', 'poids': '---'};
          final isTaken = data['etat'] == 'pris';

          return ListTile(
            leading: Icon(
              Icons.circle,
              color: isTaken ? Colors.green : Colors.red,
            ),
            title: Text("Compartiment $comp"),
            subtitle: Text("Poids: ${data['poids']}g - État: ${data['etat']}"),
          );
        }).toList(),
      ),
    );
  }
}
