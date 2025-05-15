import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../login_page.dart';
import 'patient_profile_page.dart';
import 'patient_history_page.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  String _userName = '';
  Map<String, dynamic>? _prescription;
  List<Map<String, dynamic>> _prises = [];
  bool _loading = true;

  final List<String> allCompartments = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    loadPrescription();
    fetchPrises();
  }
  Future<void> logout() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.logout, color: Colors.red),
          SizedBox(width: 8),
          Text("Déconnexion"),
        ],
      ),
      content: Text("Souhaitez-vous vous déconnecter ?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text("Annuler"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text("Se déconnecter", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirm == true) {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (_) => false,
    );
  }
}


  Future<void> loadUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseDatabase.instance.ref("users/$uid/nom").get();
    setState(() {
      _userName = snapshot.exists ? snapshot.value.toString() : "User";
    });
  }

  Future<void> loadPrescription() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseDatabase.instance.ref("prescriptions");
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      Map<String, dynamic>? matched;
      DateTime latest = DateTime(2000);

      for (var entry in data.entries) {
        final prescription = Map<String, dynamic>.from(entry.value);
        if (prescription['patientId'] == uid) {
          final date = DateTime.tryParse(prescription['date'] ?? '') ?? DateTime(2000);
          if (date.isAfter(latest)) {
            matched = prescription;
            latest = date;
          }
        }
      }

      if (matched != null) {
        setState(() {
          _prescription = matched;
        });
      }
    }
  }

  Future<void> fetchPrises() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseDatabase.instance.ref("prises");
    final snapshot = await ref.get();

    List<Map<String, dynamic>> prises = [];

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      for (var p in data.values) {
        final prise = Map<String, dynamic>.from(p);
        if (prise['patientId'] == uid) {
          prises.add(prise);
        }
      }
    }

    setState(() {
      _prises = prises;
      _loading = false;
    });
  }
  Map<String, Map<String, int>> getChartData() {
    Map<String, Map<String, int>> stats = {};
    for (var p in _prises) {
      if (!p.containsKey('date')) continue;
      final dateStr = p['date'].toString().split(' à ').first;
      final valid = p['priseValide'] == true;
      stats.putIfAbsent(dateStr, () => {'Respectées': 0, 'Manquées': 0});
      if (valid) {
        stats[dateStr]!['Respectées'] = stats[dateStr]!['Respectées']! + 1;
      } else {
        stats[dateStr]!['Manquées'] = stats[dateStr]!['Manquées']! + 1;
      }
    }
    return stats;
  }

  Widget buildBarChart() {
  final data = getChartData();
  final keys = data.keys.toList();

  return keys.isEmpty
      ? Center(child: Text("Aucune donnée à afficher"))
      : BarChart(
          BarChartData(
            barGroups: List.generate(keys.length, (i) {
              final d = keys[i];
              final respect = data[d]?['Respectées']?.toDouble() ?? 0;
              final missed = data[d]?['Manquées']?.toDouble() ?? 0;
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: respect, color: Colors.green, width: 6),
                BarChartRodData(toY: missed, color: Colors.red, width: 6),
              ]);
            }),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, _) {
                    final i = val.toInt();
                    if (i < keys.length) {
                      final date = keys[i];
                      return Text(date.substring(0, 2)); // ex: "15"
                    }
                    return Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(enabled: true),
            gridData: FlGridData(show: true),
          ),
        );
}


  List<Map<String, dynamic>> getUpcomingToday() {
    if (_prescription == null) return [];
    final now = TimeOfDay.now();
    final compartiments = Map<String, dynamic>.from(_prescription!['compartiments']);
    List<Map<String, dynamic>> result = [];

    compartiments.forEach((comp, info) {
      final med = info['medicament_name'] ?? comp;
      final horaires = List<String>.from(info['horaires'] ?? []);

      for (var h in horaires) {
        final parts = h.split(':');
        if (parts.length == 2) {
          final hInt = int.parse(parts[0]);
          final mInt = int.parse(parts[1]);
          final time = TimeOfDay(hour: hInt, minute: mInt);
          if (time.hour > now.hour || (time.hour == now.hour && time.minute > now.minute)) {
            result.add({'compartiment': comp, 'nom': med, 'horaire': h});
          }
        }
      }
    });

    result.sort((a, b) => a['horaire'].compareTo(b['horaire']));
    return result;
  }

  Widget buildUpcomingPrises() {
    final upcoming = getUpcomingToday();
    if (upcoming.isEmpty) return SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("🕒 Prochaines prises aujourd’hui",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          ...upcoming.map((p) => Card(
                child: ListTile(
                  leading: Icon(Icons.schedule, color: Colors.blue),
                  title: Text("${p['nom']}"),
                  subtitle: Text("à ${p['horaire']} - Compartiment ${p['compartiment']}"),
                ),
              )),
        ],
      ),
    );
  }

  Widget buildBoxLayout() {
    if (_prescription == null) return SizedBox();
    final data = Map<String, dynamic>.from(_prescription!['compartiments'] ?? {});

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Icon(Icons.vaccines, color: Colors.pink),
            SizedBox(width: 6),
            Text("Visualisation de la boîte",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: allCompartments.map((comp) {
            final compData = Map<String, dynamic>.from(data[comp] ?? {});
            final medName = compData['medicament_name'] ?? "Aucun médicament";
            final etat = Map<String, dynamic>.from(compData['etat'] ?? {});
            final status = etat['status'] ?? "inconnu";

            Color bgColor;
            Icon icon;

            switch (status) {
              case 'taken':
                bgColor = Colors.lightBlue.shade100;
                icon = Icon(Icons.check_circle_outline, color: Colors.blue, size: 32);
                break;
              case 'not taken':
                bgColor = Colors.red.shade100;
                icon = Icon(Icons.cancel_outlined, color: Colors.red, size: 32);
                break;
              default:
                bgColor = Colors.grey.shade200;
                icon = Icon(Icons.help_outline, color: Colors.grey, size: 32);
            }

            return AnimatedContainer(
              duration: Duration(milliseconds: 400),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 2))
                ],
              ),
              padding: EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  SizedBox(height: 8),
                  Text("Compartiment $comp", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("💊 $medName", style: TextStyle(fontSize: 13)),
                  Text("État : $status", style: TextStyle(fontSize: 13)),
                ],
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }
  Widget buildPrescriptionInfo() {
  if (_prescription == null) return SizedBox();
  final date = _prescription!['date'] ?? '';
  final comps = Map<String, dynamic>.from(_prescription!['compartiments'] ?? {});

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.assignment_turned_in, color: Colors.teal),
            SizedBox(width: 6),
            Text("Prescription du $date", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 12),
        ...allCompartments.map((c) {
          final comp = comps[c];
          if (comp == null) {
            return Card(
              margin: EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text("🧪 Compartiment $c"),
                subtitle: Text("Aucune prescription"),
              ),
            );
          }
          return Card(
            margin: EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("🧪 Compartiment $c", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text("Nom : ${comp['medicament_name'] ?? '---'}"),
                  Text("Horaires : ${(comp['horaires'] as List?)?.join(', ') ?? '-'}"),
                  Text("Note : ${comp['note'] ?? '---'}"),
                ],
              ),
            ),
          );
        }),
      ],
    ),
  );
}

  Widget buildDashboard() {
  int total = _prises.length;
  int respected = _prises.where((p) => p['priseValide'] == true).length;
  int missed = _prises.where((p) =>
      p['priseValide'] == false || (p['status'] ?? '') == 'not taken').length;

  double rate = total > 0 ? (respected / total) * 100 : 0;
  String last = _prises.isNotEmpty ? _prises.last['date'] ?? "Inconnue" : "Aucune";

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.dashboard, color: Colors.deepPurple),
            SizedBox(width: 6),
            Text("Tableau de bord", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard("Respectées", respected, Icons.check_circle, Colors.green.shade100, Colors.green),
            _buildStatCard("Manquées", missed, Icons.cancel, Colors.red.shade100, Colors.red),
            _buildStatCard("Taux", "${rate.toStringAsFixed(1)}%", Icons.percent, Colors.blue.shade100, Colors.blue),
          ],
        ),
        SizedBox(height: 12),
        Card(
          color: Colors.grey.shade100,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(child: Text("Dernière prise : $last")),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildStatCard(String title, dynamic value, IconData icon, Color bgColor, Color iconColor) {
  return Expanded(
    child: Card(
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            SizedBox(height: 4),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            Text("$value", style: TextStyle(fontSize: 16)),
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
  title: Text('Welcome $_userName'),
  backgroundColor: Colors.blue,
  actions: [
    IconButton(
      icon: Icon(Icons.history),
      tooltip: "Historique",
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PatientHistoryPage()));
      },
    ),
    IconButton(
      icon: Icon(Icons.logout),
      tooltip: "Déconnexion",
      onPressed: logout,
    ),
  ],
),

      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.person),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PatientProfilePage()));
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue[400]!, Colors.blue[800]!]),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Lottie.asset("lib/assets/animations/medication.json", height: 100),
                  SizedBox(height: 10),
                  Text("Welcome 👋", style: TextStyle(color: Colors.white, fontSize: 22)),
                  Text("We care about your health 💙", style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            if (_prescription != null) ...[
              buildDashboard(),
              buildUpcomingPrises(),
              buildBoxLayout(),
              buildPrescriptionInfo(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("📊 Prises respectées / manquées",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 200, child: buildBarChart()),
                  ],
                ),
              ),
            ],
            if (_prescription == null && !_loading)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(children: [
                  Lottie.asset("lib/assets/animations/waiting.json", height: 150),
                  SizedBox(height: 10),
                  Text("No prescription available yet.", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Your doctor will soon add your medications."),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}
