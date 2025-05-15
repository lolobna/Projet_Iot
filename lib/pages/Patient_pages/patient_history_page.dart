import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class PatientHistoryPage extends StatefulWidget {
  const PatientHistoryPage({super.key});

  @override
  State<PatientHistoryPage> createState() => _PatientHistoryPageState();
}

class _PatientHistoryPageState extends State<PatientHistoryPage> {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, List<Map<String, dynamic>>> groupedPrises = {};
  String selectedCompartment = 'Tous';
  String selectedDate = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchPrises();
  }

  Future<void> fetchPrises() async {
    final ref = FirebaseDatabase.instance.ref("prises");
    final snapshot = await ref.get();

    Map<String, List<Map<String, dynamic>>> grouped = {};

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      for (var item in data.values) {
        final prise = Map<String, dynamic>.from(item);

        if (prise["patientId"] != userId || !prise.containsKey('date')) continue;

        final dateTimeStr = prise["date"];
        final parts = dateTimeStr.split(" à ");
        if (parts.length != 2) continue;

        final date = parts[0];
        final heure = parts[1];

        grouped.putIfAbsent(date, () => []).add({
          "compartiment": prise["compartiment"] ?? "?",
          "valide": prise["priseValide"],
          "retard": prise["retard"] ?? "?",
          "heure": heure,
        });
      }

      grouped.updateAll((key, list) {
        list.sort((a, b) => a['heure'].compareTo(b['heure']));
        return list;
      });

      final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
      selectedDate = dates.isNotEmpty ? dates.first : '';
    }

    setState(() {
      groupedPrises = grouped;
      _loading = false;
    });
  }

  List<String> getCompartments() {
    final all = groupedPrises.values
        .expand((e) => e)
        .where((p) => p.containsKey("compartiment"))
        .map((p) => p["compartiment"].toString())
        .toSet()
        .toList();
    all.sort();
    return all;
  }

  Color getColor(Map<String, dynamic> p) {
    if (p["valide"] == true) return Colors.green.shade50;
    if (p["valide"] == false) return Colors.red.shade50;
    return Colors.orange.shade50;
  }

  Icon getIcon(Map<String, dynamic> p) {
    if (p["valide"] == true) return Icon(Icons.check_circle, color: Colors.green);
    if (p["valide"] == false) return Icon(Icons.cancel, color: Colors.red);
    return Icon(Icons.warning, color: Colors.orange);
  }

  Widget buildCard(Map<String, dynamic> p) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: getColor(p),
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: ListTile(
        leading: getIcon(p),
        title: Text("Compartiment : ${p['compartiment']}"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Heure : ${p['heure']}"),
            Text("Retard : ${p['retard']} min"),
          ],
        ),
      ),
    );
  }

  void goToPreviousDate() {
    final dates = groupedPrises.keys.toList()..sort((a, b) => b.compareTo(a));
    final currentIndex = dates.indexOf(selectedDate);
    if (currentIndex < dates.length - 1) {
      setState(() {
        selectedDate = dates[currentIndex + 1];
      });
    }
  }

  void goToNextDate() {
    final dates = groupedPrises.keys.toList()..sort((a, b) => b.compareTo(a));
    final currentIndex = dates.indexOf(selectedDate);
    if (currentIndex > 0) {
      setState(() {
        selectedDate = dates[currentIndex - 1];
      });
    } else {
      // Avancer d'un jour dans le futur
      final parsed = DateFormat("d MMM yyyy", 'en_US').parse(selectedDate);
      final next = parsed.add(Duration(days: 1));
      setState(() {
        selectedDate = DateFormat("d MMM yyyy", 'en_US').format(next);
      });
    }
  }

  Widget buildChips() {
    final list = getCompartments();
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: Text("Tous"),
          selected: selectedCompartment == "Tous",
          onSelected: (_) => setState(() => selectedCompartment = "Tous"),
          selectedColor: Colors.purple.shade100,
        ),
        ...list.map((c) => ChoiceChip(
              label: Text(c),
              selected: selectedCompartment == c,
              onSelected: (_) => setState(() => selectedCompartment = c),
              selectedColor: Colors.purple.shade100,
            )),
      ],
    );
  }

  Widget buildContent() {
    final DateTime today = DateTime.now();
    final DateTime currentDate = DateFormat("d MMM yyyy", 'en_US').parse(selectedDate);

    final isFuture = currentDate.isAfter(today);
    final prises = groupedPrises[selectedDate] ?? [];

    final filtered = selectedCompartment == 'Tous'
        ? prises
        : prises.where((p) => p["compartiment"] == selectedCompartment).toList();

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Text(
            isFuture
                ? "Aucune prise prévue pour cette date. Vous n’avez pas encore pris vos médicaments."
                : "Aucune prise enregistrée ce jour-là.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      children: filtered.map(buildCard).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Historique des Prises"),
        backgroundColor: Colors.blue,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(height: 12),
                buildChips(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(onPressed: goToPreviousDate, icon: Icon(Icons.arrow_back)),
                      Text(selectedDate, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: goToNextDate, icon: Icon(Icons.arrow_forward)),
                    ],
                  ),
                ),
                Expanded(child: buildContent()),
              ],
            ),
    );
  }
}
