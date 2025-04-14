import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'notification_service.dart';

Future<void> schedulePrescriptionReminders() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final ref = FirebaseDatabase.instance.ref("prescriptions/$uid");
  final snapshot = await ref.get();

  int notificationId = 0;

  if (snapshot.exists) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    data.forEach((compartiment, value) {
      final info = Map<String, dynamic>.from(value);

      final timeStr = info['time']; // "HH:mm"
      final dateStr = info['date']; // "yyyy-MM-dd"
      final dateTime = DateTime.parse('$dateStr $timeStr');

      final notifTime = dateTime.subtract(Duration(minutes: 10));

      NotificationService.scheduleNotification(
        id: notificationId++,
        title: 'Prise Médicament',
        body: 'Prenez le médicament du compartiment $compartiment à $timeStr',
        scheduledDate: notifTime,
      );
    });
  }
}
