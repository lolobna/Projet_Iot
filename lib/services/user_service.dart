import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final DatabaseReference _realtimeDB = FirebaseDatabase.instance.ref();

  static Future<void> signUp({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String role,
    String? cin,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = userCredential.user!.uid;

    // Collection Firestore selon rôle
    final roleCollection = role == "medecin" ? "medecin" : "patient";

    await _db.collection(roleCollection).doc(uid).set({
      "email": email,
      "nom": nom,
      "prenom": prenom,
      "role": role,
      if (role == "patient") "CIN": cin,
    });

    // Écriture dans Realtime Database
    await FirebaseDatabase.instance.ref("users/$uid").set({
      "email": email,
      "nom": nom,
      "prenom": prenom,
      "role": role,
      if (role == "patient") "CIN": cin,
    });
  }

  static Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<String> getUserRole() async {
    final uid = _auth.currentUser!.uid;

    final medecinDoc = await _db.collection("medecin").doc(uid).get();
    if (medecinDoc.exists) return medecinDoc["role"].toString();

    final patientDoc = await _db.collection("patient").doc(uid).get();
    if (patientDoc.exists) return patientDoc["role"].toString();

    throw Exception("Rôle utilisateur non trouvé");
  }

  // Nouvelle méthode pour mettre à jour l'UID du patient connecté dans Realtime DB
  static Future<void> updateCurrentPatientId() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Stockage de l'UID dans Realtime Database, clé "currentPatientId"
    await _realtimeDB.child('currentPatientId').set(user.uid);
  }
}
