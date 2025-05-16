import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_application_1/pages/Medecin_pages/add_patient_page.dart';
import 'package:flutter_application_1/pages/Medecin_pages/SelectPatientPage.dart';


class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getPrisesStream() {
    final DatabaseReference _database = FirebaseDatabase.instance.ref();
    return _database.child('prises').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return data.entries.map((entry) {
        final value = entry.value as Map<dynamic, dynamic>;
        return {
          'patientId': value['patientId'],
          'priseValide': value['priseValide'] ?? false,
          'date': value['date'],
        };
      }).toList();
    });
  }

  Future<Map<String, String>> getPatientNames() async {
    final snapshot = await _firestore.collection('patient').get();
    if (snapshot.docs.isEmpty) {
      print('Aucune donnée trouvée dans la collection patient.');
      return {};
    }

    return {
      for (var doc in snapshot.docs) doc.id: '${doc['prenom']} ${doc['nom']}',
    };
  }
}

class MedecinHomePage extends StatefulWidget {
  @override
  _MedecinHomePageState createState() => _MedecinHomePageState();
}

class _MedecinHomePageState extends State<MedecinHomePage> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, String> patientNames = {};
  String _selectedFilter = 'Tous';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null).then((_) {
      setState(() {});
    });
    _fetchPatientNames();
  }

  void _fetchPatientNames() async {
    final names = await _firebaseService.getPatientNames();
    setState(() {
      patientNames = names;
    });
  }

  Map<String, Map<String, dynamic>> _calculatePatientStats(
    List<Map<String, dynamic>> prises,
  ) {
    Map<String, Map<String, dynamic>> stats = {};

    for (var prise in prises) {
      final patientId = prise['patientId'] ?? 'Inconnu';
      final isValid = prise['priseValide'] == true;

      stats.putIfAbsent(patientId, () => {'total': 0, 'valid': 0});
      stats[patientId]!['total'] = stats[patientId]!['total']! + 1;
      if (isValid) {
        stats[patientId]!['valid'] = stats[patientId]!['valid']! + 1;
      }
    }

    stats.forEach((patientId, data) {
      final total = data['total'];
      final valid = data['valid'];
      final percentage = total > 0 ? (valid / total) * 100 : 0;

      String evaluation;
      if (percentage > 95) {
        evaluation = 'Excellent';
      } else if (percentage > 75) {
        evaluation = 'Très bien';
      } else if (percentage > 50) {
        evaluation = 'Bien';
      } else {
        evaluation = 'À améliorer';
      }

      data['percentage'] = percentage;
      data['evaluation'] = evaluation;
    });

    return stats;
  }

  Map<String, Map<String, int>> _calculateDailyStats(
    List<Map<String, dynamic>> prises,
  ) {
    Map<String, Map<String, int>> dailyStats = {};
    Map<String, Map<String, Map<String, dynamic>>> dailyPatientStats = {};

    for (var prise in prises) {
      final patientId = prise['patientId'] ?? 'Inconnu';
      final isValid = prise['priseValide'] == true;

      final dateString = prise['date'] as String;
      DateTime date;
      try {
        date = DateTime.parse(dateString);
      } catch (e) {
        continue;
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      dailyPatientStats.putIfAbsent(formattedDate, () => {});
      dailyPatientStats[formattedDate]!.putIfAbsent(
        patientId,
        () => {'total': 0, 'valid': 0},
      );

      dailyPatientStats[formattedDate]![patientId]!['total'] =
          dailyPatientStats[formattedDate]![patientId]!['total']! + 1;
      if (isValid) {
        dailyPatientStats[formattedDate]![patientId]!['valid'] =
            dailyPatientStats[formattedDate]![patientId]!['valid']! + 1;
      }
    }

    dailyPatientStats.forEach((date, patientStats) {
      dailyStats.putIfAbsent(
        date,
        () => {'Excellent': 0, 'Très bien': 0, 'Bien': 0, 'À améliorer': 0},
      );

      patientStats.forEach((patientId, stats) {
        final total = stats['total'];
        final valid = stats['valid'];
        final percentage = total > 0 ? (valid / total) * 100 : 0;

        String evaluation;
        if (percentage > 95) {
          evaluation = 'Excellent';
        } else if (percentage > 75) {
          evaluation = 'Très bien';
        } else if (percentage > 50) {
          evaluation = 'Bien';
        } else {
          evaluation = 'À améliorer';
        }

        dailyStats[date]![evaluation] = dailyStats[date]![evaluation]! + 1;
      });
    });

    return dailyStats;
  }

  Color _getEvaluationColor(String eval) {
    switch (eval) {
      case 'Excellent':
        return const Color(0xFF4CAF50);
      case 'Très bien':
        return const Color(0xFF2196F3);
      case 'Bien':
        return const Color(0xFFFF9800);
      case 'À améliorer':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF6C63FF);
    }
  }

  IconData _getEvaluationIcon(String eval) {
    switch (eval) {
      case 'Excellent':
        return Icons.emoji_emotions;
      case 'Très bien':
        return Icons.sentiment_very_satisfied;
      case 'Bien':
        return Icons.sentiment_satisfied;
      default:
        return Icons.sentiment_dissatisfied;
    }
  }

  Widget _buildLegendItem(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? label : 'Tous';
          });
        },
        selectedColor: _getEvaluationColor(label),
        labelStyle: GoogleFonts.poppins(
          color: isSelected ? Colors.white : Colors.black87,
          fontSize: 12,
        ),
        backgroundColor: Colors.grey[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildPatientCard(String patientId, Map<String, dynamic> data) {
    final patientName = patientNames[patientId] ?? 'Patient inconnu';
    final color = _getEvaluationColor(data['evaluation']);
    final icon = _getEvaluationIcon(data['evaluation']);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(Icons.person, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    patientName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  data['evaluation'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: data['percentage'] / 100,
              backgroundColor: color.withOpacity(0.2),
              color: color,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${data['valid']}/${data['total']} prises validées',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  '${data['percentage'].toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tableau de Bord Médical',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firebaseService.getPrisesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement des données...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement des données',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Veuillez réessayer plus tard',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }
          final prises = snapshot.data ?? [];
          final stats = _calculatePatientStats(prises);
          final dailyStats = _calculateDailyStats(prises);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with stats
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF6C63FF),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem(
                            Icons.people,
                            'Patients',
                            stats.length.toString(),
                            Colors.white,
                          ),
                          _buildStatItem(
                            Icons.medication,
                            'Prises Total',
                            prises.length.toString(),
                            Colors.white,
                          ),
                          _buildStatItem(
                            Icons.check_circle,
                            'Validées',
                            prises
                                .where((p) => p['priseValide'] == true)
                                .length
                                .toString(),
                            Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Patients section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Suivi des Patients',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (stats.isNotEmpty)
                        Text(
                          '${stats.length} patients',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),

                // Filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Tous', _selectedFilter == 'Tous'),
                        _buildFilterChip('Excellent', _selectedFilter == 'Excellent'),
                        _buildFilterChip('Très bien', _selectedFilter == 'Très bien'),
                        _buildFilterChip('Bien', _selectedFilter == 'Bien'),
                        _buildFilterChip('À améliorer', _selectedFilter == 'À améliorer'),
                      ],
                    ),
                  ),
                ),

                // Patients horizontal list
                SizedBox(
                  height: 220,
                  child: stats.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Aucun patient trouvé',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          children: stats.entries
                              .where((entry) => 
                                  _selectedFilter == 'Tous' || 
                                  entry.value['evaluation'] == _selectedFilter)
                              .map((entry) => _buildPatientCard(entry.key, entry.value))
                              .toList(),
                        ),
                ),

                // Graph section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'Évolution Journalière',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // Graph container
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 250,
                        child: dailyStats.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bar_chart,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Aucune donnée à afficher',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceBetween,
                                  maxY: dailyStats.values
                                      .map(
                                        (stats) => stats.values.reduce(
                                          (a, b) => a > b ? a : b,
                                        ),
                                      )
                                      .reduce((a, b) => a > b ? a : b)
                                      .toDouble() *
                                      1.2,
                                  minY: 0,
                                  barGroups: dailyStats.entries.map((entry) {
                                    final date = entry.key;
                                    final stats = entry.value;

                                    return BarChartGroupData(
                                      x: dailyStats.keys.toList().indexOf(
                                        date,
                                      ),
                                      barsSpace: 4,
                                      barRods: [
                                        BarChartRodData(
                                          toY: stats['Excellent']!.toDouble(),
                                          color: Colors.green[700],
                                          width: 14,
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(6),
                                          ),
                                          backDrawRodData:
                                              BackgroundBarChartRodData(
                                            show: false,
                                          ),
                                        ),
                                        BarChartRodData(
                                          toY: stats['Très bien']!.toDouble(),
                                          color: Colors.blue[600],
                                          width: 14,
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(6),
                                          ),
                                        ),
                                        BarChartRodData(
                                          toY: stats['Bien']!.toDouble(),
                                          color: Colors.orange[600],
                                          width: 14,
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(6),
                                          ),
                                        ),
                                        BarChartRodData(
                                          toY: stats['À améliorer']!.toDouble(),
                                          color: Colors.red[600],
                                          width: 14,
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(6),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index >= 0 &&
                                              index < dailyStats.keys.length) {
                                            final dateString = dailyStats.keys
                                                .elementAt(index);

                                            try {
                                              final date = DateTime.parse(
                                                dateString,
                                              );
                                              final formattedDate = DateFormat(
                                                'd MMM',
                                                'fr_FR',
                                              ).format(date);
                                              return Text(
                                                formattedDate,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.black,
                                                ),
                                              );
                                            } catch (e) {
                                              print(
                                                'Erreur lors de l\'analyse de la date : $dateString - $e',
                                              );
                                              return const Text(
                                                'Invalide',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.red,
                                                ),
                                              );
                                            }
                                          } else {
                                            return const SizedBox.shrink();
                                          }
                                        },
                                        reservedSize: 28,
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 32,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            value.toInt().toString(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[700],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: false,
                                      ),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: false,
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: 1,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: Colors.grey.withOpacity(0.1),
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      tooltipBgColor: Colors.white,
                                      tooltipPadding: const EdgeInsets.all(8),
                                      tooltipMargin: 8,
                                      getTooltipItem: (
                                        group,
                                        groupIndex,
                                        rod,
                                        rodIndex,
                                      ) {
                                        final evaluation = [
                                          'il est Excellent',
                                          'il est Très bien',
                                          'il est Bien',
                                          'il ne prend pas ses medicaments',
                                        ][rodIndex];
                                        return BarTooltipItem(
                                          '$evaluation\n${rod.toY.toInt()} patients',
                                          GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[800],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                      ),

                      // Legend
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildLegendItem(
                              const Color(0xFF4CAF50),
                              'Excellent',
                            ),
                            _buildLegendItem(
                              const Color(0xFF2196F3),
                              'Très bien',
                            ),
                            _buildLegendItem(const Color(0xFFFF9800), 'Bien'),
                            _buildLegendItem(
                              const Color(0xFFF44336),
                              'À améliorer',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}