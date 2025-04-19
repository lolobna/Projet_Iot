import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseDatabase.instance.ref();

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

    // Définir le chemin correct selon le rôle
    final rolePath = role == "medecin" ? "users/medecins" : "users/patients";

    await _db.child("$rolePath/$uid").set({
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

    // Essayer d'abord dans 'medecins'
    final medecinSnapshot = await _db.child("users/medecins/$uid/role").get();
    if (medecinSnapshot.exists) return medecinSnapshot.value.toString();

    // Sinon, chercher dans 'patients'
    final patientSnapshot = await _db.child("users/patients/$uid/role").get();
    if (patientSnapshot.exists) return patientSnapshot.value.toString();

    throw Exception("Rôle utilisateur non trouvé");
  }
}
