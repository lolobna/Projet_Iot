import 'package:flutter/material.dart';
import 'register_page.dart';
import '../services/user_service.dart';
import 'Medecin_pages/medecin_home_page.dart';
import 'Patient_pages/patient_home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void login() async {
    try {
      await UserService.login(emailController.text, passwordController.text);
      String role = await UserService.getUserRole();

      // Afficher une popup de succès
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Connexion réussie'),
              content: Text(
                'Bienvenue dans votre boîte de pilules intelligente !',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Fermer la popup
                    if (role == 'medecin') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => MedecinHomePage()),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => PatientHomePage()),
                      );
                    }
                  },
                  child: Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      // Afficher une popup d'erreur
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Erreur de connexion'),
              content: Text('Une erreur est survenue : $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), // Fermer la popup
                  child: Text('OK'),
                ),
              ],
            ),
      );
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connexion'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo ou image pour représenter la boîte de pilules intelligente
                Image.asset(
                  'lib/assets/images/pill_box_logo.jpeg', // Assurez-vous que l'image existe dans votre projet
                  height: 120,
                ),
                SizedBox(height: 16),
                // Description de l'application
                Text(
                  'Bienvenue dans votre boîte de pilules intelligente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                Card(
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
                          'Connexion',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.email),
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
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Se connecter',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextButton(
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RegisterPage(),
                                ),
                              ),
                          child: Text(
                            "Créer un compte",
                            style: TextStyle(color: Colors.blueAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
