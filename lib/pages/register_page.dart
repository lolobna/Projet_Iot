import 'package:flutter/material.dart';
import '../services/user_service.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final cinController = TextEditingController();

  String role = 'patient';

  void register() async {
    try {
      await UserService.signUp(
        email: emailController.text,
        password: passwordController.text,
        nom: nomController.text,
        prenom: prenomController.text,
        role: role,
        cin: role == 'patient' ? cinController.text : null,
      );

      // Afficher une popup de succès qui disparaît automatiquement
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Inscription réussie'),
          content: Text('Votre compte a été créé avec succès !'),
        ),
      );

      // Attendre 2 secondes avant de fermer la popup et revenir à la page précédente
      await Future.delayed(Duration(seconds: 2));
      Navigator.pop(context); // Fermer la popup
      Navigator.pop(context); // Retour à la page précédente
    } catch (e) {
      // Afficher une popup d'erreur qui disparaît automatiquement
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erreur d\'inscription'),
          content: Text('Une erreur est survenue : $e'),
        ),
      );

      // Attendre 2 secondes avant de fermer la popup
      await Future.delayed(Duration(seconds: 2));
      Navigator.pop(context); // Fermer la popup
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inscription'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Créer un compte',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: nomController,
                      decoration: InputDecoration(
                        labelText: 'Nom',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: prenomController,
                      decoration: InputDecoration(
                        labelText: 'Prénom',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: role,
                      items: ['patient', 'medecin']
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => role = value!),
                      decoration: InputDecoration(
                        labelText: 'Rôle',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    if (role == 'patient') ...[
                      SizedBox(height: 16),
                      TextField(
                        controller: cinController,
                        decoration: InputDecoration(
                          labelText: 'CIN',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: register,
                      child: Text('Inscrire'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
