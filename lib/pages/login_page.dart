import 'package:flutter/material.dart';
import 'register_page.dart';
import '../services/user_service.dart';
import 'medecin_home_page.dart';
import 'patient_home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void login() async {
    try {
      await UserService.login(
        emailController.text,
        passwordController.text,
      );
      String role = await UserService.getUserRole();
      if (role == 'medecin') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => MedecinHomePage()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => PatientHomePage()));
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Connexion')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Mot de passe'), obscureText: true),
            ElevatedButton(onPressed: login, child: Text('Se connecter')),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RegisterPage()),
              ),
              child: Text("Créer un compte"),
            )
          ],
        ),
      ),
    );
  }
}