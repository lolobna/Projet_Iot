import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

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

    // 🔥 Écriture dans Firestore
    final roleCollection = role == "medecin" ? "medecin" : "patient";

    await _db.collection(roleCollection).doc(uid).set({
      "email": email,
      "nom": nom,
      "prenom": prenom,
      "role": role,
      if (role == "patient") "CIN": cin,
    });

    // ✅ Écriture dans Realtime Database pour le profil patient
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
}
