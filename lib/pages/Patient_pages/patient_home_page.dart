import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../login_page.dart';
import 'patient_profile_page.dart';
import 'patient_history_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

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
    tz.initializeTimeZones();
    loadUserInfo();
    loadPrescription();
    fetchPrises();
  }

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
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
                child: Text(
                  "Se déconnecter",
                  style: TextStyle(color: Colors.red),
                ),
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
    final snapshot =
        await FirebaseDatabase.instance.ref("users/$uid/nom").get();
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
          final date =
              DateTime.tryParse(prescription['date'] ?? '') ?? DateTime(2000);
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
        _scheduleNextPriseNotification();
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

  Future<void> _scheduleNextPriseNotification() async {
    final upcoming = getUpcomingToday();
    if (upcoming.isEmpty) return;

    final next = upcoming.first;
    final now = TimeOfDay.now();
    final parts = next['horaire'].split(':');
    if (parts.length != 2) return;

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final nowDate = DateTime.now();
    final notifTime = tz.TZDateTime.local(
      nowDate.year,
      nowDate.month,
      nowDate.day,
      hour,
      minute,
    );

    if (notifTime.isBefore(tz.TZDateTime.now(tz.local)))
      return; // Ne pas notifier pour le passé

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Rappel de prise',
      'Il est temps de prendre votre médicament : ${next['nom']} (compartiment ${next['compartiment']})',
      notifTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prise_channel',
          'Prises Médicaments',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Map<String, Map<String, int>> getChartData() {
    Map<String, Map<String, int>> stats = {};
    for (var p in _prises) {
      if (!p.containsKey('date')) continue;
      final fullDateStr = p['date'].toString();
      String dateKey;
      if (fullDateStr.contains('à')) {
        dateKey = fullDateStr.split(' à ').first.trim();
      } else if (fullDateStr.length >= 10) {
        dateKey = fullDateStr.substring(0, 10);
      } else {
        dateKey = fullDateStr;
      }
      final status = (p['status'] ?? '').toString().toLowerCase();
      stats.putIfAbsent(
        dateKey,
        () => {'valides': 0, 'enRetard': 0, 'ratees': 0},
      );
      if (status == 'valide' || status == 'respectée' || status == 'respecte') {
        stats[dateKey]!['valides'] = stats[dateKey]!['valides']! + 1;
      } else if (status == 'en retard') {
        stats[dateKey]!['enRetard'] = stats[dateKey]!['enRetard']! + 1;
      } else if (status == 'raté' ||
          status == 'ratée' ||
          status == 'manquée' ||
          status == 'manque') {
        stats[dateKey]!['ratees'] = stats[dateKey]!['ratees']! + 1;
      }
    }
    return stats;
  }

  Map<String, int> getStatusStats(List<Map<String, dynamic>> prises) {
    int valides = 0;
    int enRetard = 0;
    int ratees = 0;

    for (var p in prises) {
      final status = (p['status'] ?? '').toString().toLowerCase();
      if (status == 'valide' || status == 'respectée' || status == 'respecte') {
        valides++;
      } else if (status == 'en retard') {
        enRetard++;
      } else if (status == 'raté' ||
          status == 'ratée' ||
          status == 'manquée' ||
          status == 'manque') {
        ratees++;
      }
    }
    return {'valides': valides, 'enRetard': enRetard, 'ratees': ratees};
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
              final valides = data[d]?['valides']?.toDouble() ?? 0;
              final enRetard = data[d]?['enRetard']?.toDouble() ?? 0;
              final ratees = data[d]?['ratees']?.toDouble() ?? 0;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(toY: valides, color: Colors.green, width: 8),
                  BarChartRodData(
                    toY: enRetard,
                    color: Colors.orange,
                    width: 8,
                  ),
                  BarChartRodData(toY: ratees, color: Colors.red, width: 8),
                ],
                barsSpace: 2,
              );
            }),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, _) {
                    final i = val.toInt();
                    if (i < keys.length) {
                      final dateStr = keys[i];
                      try {
                        final date = DateTime.parse(dateStr);
                        final formatted = DateFormat(
                          'd MMM',
                          'fr_FR',
                        ).format(date);
                        return Text(formatted, style: TextStyle(fontSize: 12));
                      } catch (e) {
                        return Text(dateStr, style: TextStyle(fontSize: 12));
                      }
                    }
                    return Text('');
                  },
                  reservedSize: 32,
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(enabled: true),
            gridData: FlGridData(show: true),
            groupsSpace: 16,
          ),
        );
  }

  List<Map<String, dynamic>> getUpcomingToday() {
    if (_prescription == null) return [];
    final now = TimeOfDay.now();
    final compartiments = Map<String, dynamic>.from(
      _prescription!['compartiments'],
    );
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
          if (time.hour > now.hour ||
              (time.hour == now.hour && time.minute >= now.minute)) {
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
    print("Upcoming prises: $upcoming"); // <-- Ajoute ceci pour debug
    if (upcoming.isEmpty) return SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text(
                "Prochaines prises aujourd’hui",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 10),
          ...upcoming.map(
            (p) => Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.blue.shade50,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade200,
                  child: Icon(Icons.medication, color: Colors.white),
                ),
                title: Text(
                  "${p['nom']}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Compartiment ${p['compartiment']}",
                  style: TextStyle(color: Colors.blueGrey),
                ),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "${p['horaire']}",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBoxLayout() {
    if (_prescription == null) return SizedBox();
    final comps = Map<String, dynamic>.from(
      _prescription!['compartiments'] ?? {},
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vaccines, color: Colors.pink),
              SizedBox(width: 6),
              Text(
                "Visualisation de la boîte",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children:
                allCompartments.map((comp) {
                  final compData = Map<String, dynamic>.from(comps[comp] ?? {});
                  bool isNull = compData.isEmpty;
                  bool isVide = false;
                  String medName = "Aucun médicament";
                  if (!isNull) {
                    medName = compData['medicament_name'] ?? "Aucun médicament";
                    isVide = compData['vide'] == true;
                  }

                  Color bgColor =
                      isNull
                          ? Colors.red.shade100
                          : (isVide
                              ? Colors.orange.shade100
                              : Colors.green.shade100);
                  Icon icon =
                      isNull
                          ? Icon(Icons.warning, color: Colors.red, size: 32)
                          : (isVide
                              ? Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 32,
                              )
                              : Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 32,
                              ));

                  String statusText =
                      isNull ? "Vide" : (isVide ? "Vide" : "Rempli");

                  return AnimatedContainer(
                    duration: Duration(milliseconds: 400),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        icon,
                        SizedBox(height: 8),
                        Text(
                          "Compartiment $comp",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text("💊 $medName", style: TextStyle(fontSize: 13)),
                        Text(statusText, style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildPrescriptionInfo() {
    if (_prescription == null) return SizedBox();
    final date = _prescription!['date'] ?? '';
    final comps = Map<String, dynamic>.from(
      _prescription!['compartiments'] ?? {},
    );

    // Filtrer les compartiments existants
    final existingCompartments =
        allCompartments.where((c) => comps[c] != null).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_turned_in, color: Colors.teal),
              SizedBox(width: 6),
              Text(
                "Prescription du $date",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Affichage deux par ligne
          for (int i = 0; i < existingCompartments.length; i += 2)
            Row(
              children: [
                // Premier compartiment de la ligne
                Expanded(
                  child: _buildCompCard(
                    existingCompartments[i],
                    comps[existingCompartments[i]],
                  ),
                ),
                SizedBox(width: 10),
                // Deuxième compartiment de la ligne (s'il existe)
                if (i + 1 < existingCompartments.length)
                  Expanded(
                    child: _buildCompCard(
                      existingCompartments[i + 1],
                      comps[existingCompartments[i + 1]],
                    ),
                  )
                else
                  Expanded(
                    child: SizedBox(),
                  ), // Pour garder l'alignement si impair
              ],
            ),
        ],
      ),
    );
  }

  // Widget pour une carte de compartiment
  Widget _buildCompCard(String c, Map comp) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "🧪 Compartiment $c",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text("Nom : ${comp['medicament_name'] ?? '---'}"),
            Text(
              "Horaires : ${(comp['horaires'] as List?)?.join(', ') ?? '-'}",
            ),
            Text("Note : ${comp['note'] ?? '---'}"),
          ],
        ),
      ),
    );
  }

  Widget buildDashboard() {
    final stats = getStatusStats(_prises);
    int total = _prises.length;
    int valides = stats['valides'] ?? 0;
    int enRetard = stats['enRetard'] ?? 0;
    int ratees = stats['ratees'] ?? 0;
    double taux = total > 0 ? (valides / total) * 100 : 0;
    String last =
        _prises.isNotEmpty ? _prises.last['date'] ?? "Inconnue" : "Aucune";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard, color: Colors.deepPurple),
              SizedBox(width: 6),
              Text(
                "Tableau de bord",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                "Respectées",
                valides,
                Icons.check_circle,
                Colors.green.shade100,
                Colors.green,
              ),
              _buildStatCard(
                "En retard",
                enRetard,
                Icons.warning_amber_rounded,
                Colors.orange.shade100,
                Colors.orange,
              ),
              _buildStatCard(
                "Ratées",
                ratees,
                Icons.cancel,
                Colors.red.shade100,
                Colors.red,
              ),
            ],
          ),
          SizedBox(height: 12),
          Card(
            elevation: 3,
            color: Colors.blue.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 14.0,
                horizontal: 16,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.access_time, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dernière prise",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          last,
                          style: TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    dynamic value,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
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
        title: Text('bienvenu '),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            tooltip: "Historique",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PatientHistoryPage()),
              );
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PatientProfilePage()),
          );
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.blue[800]!],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Lottie.asset(
                    "lib/assets/animations/medication.json",
                    height: 100,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Bienvenu 👋",
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  ),
                  Text(
                    "Nous prenons soin de votre santé💙",
                    style: TextStyle(color: Colors.white70),
                  ),
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
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bar_chart, color: Colors.blue, size: 28),
                            SizedBox(width: 8),
                            Text(
                              "Statistiques de vos prises",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              color: Colors.green,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Respectées",
                              style: TextStyle(color: Colors.green[800]),
                            ),
                            SizedBox(width: 18),
                            Container(
                              width: 16,
                              height: 16,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "En retard",
                              style: TextStyle(color: Colors.orange[800]),
                            ),
                            SizedBox(width: 18),
                            Container(width: 16, height: 16, color: Colors.red),
                            SizedBox(width: 6),
                            Text(
                              "Ratées",
                              style: TextStyle(color: Colors.red[800]),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        SizedBox(height: 180, child: buildBarChart()),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (_prescription == null && !_loading)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Lottie.asset(
                      "lib/assets/animations/waiting.json",
                      height: 150,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "No prescription available yet.",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("Your doctor will soon add your medications."),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
