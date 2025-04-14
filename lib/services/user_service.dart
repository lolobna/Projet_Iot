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

    await _db.child("users/$uid").set({
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
    final snapshot = await _db.child("users/$uid/role").get();
    return snapshot.value.toString();
  }
}
