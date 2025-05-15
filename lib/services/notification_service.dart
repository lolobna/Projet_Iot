// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tl;

import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_database/firebase_database.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

static Future<void> init() async {
  final android = AndroidInitializationSettings('@mipmap/ic_launcher');
  final settings = InitializationSettings(android: android);
  await _notifications.initialize(settings);
 tl.initializeTimeZones();
}

  static Future<void> scheduleNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
}) async {
  await _notifications.zonedSchedule(
    id,
    title,
    body,
    tz.TZDateTime.from(scheduledDate, tz.local),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'channelId',
        'channelName',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    matchDateTimeComponents: DateTimeComponents.time,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime, // ✅ Ajout obligatoire
  );
}

  // Nouvelle méthode pour envoyer la notification après la prise
  static Future<void> sendAfterTakingNotification({
    required int id,
    required String compartiment,
    required String dateHeure,
  }) async {
    final title = 'Prise Médicament';
    final body = 'Le médicament du compartiment $compartiment a été pris à $dateHeure';

    DateTime dateTime = DateTime.parse(dateHeure);
    await scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: dateTime, // Vous pouvez également ajuster le timing si nécessaire
    );
  }
}

// Fonction pour écouter les changements dans Firebase et envoyer la notification après la prise
Future<void> listenForMedicationUpdates() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final ref = FirebaseDatabase.instance.ref("historique/$uid");

  ref.onChildAdded.listen((event) {
    final data = event.snapshot.value as Map;
    if (data['compartiment'] == null || data['datetime'] == null) return;

    final compartiment = data['compartiment'];
    final dateHeure = data['datetime'];


    // Une fois la prise enregistrée, envoyez la notification
    NotificationService.sendAfterTakingNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      compartiment: compartiment,
      dateHeure: dateHeure,
    );
  });
}
