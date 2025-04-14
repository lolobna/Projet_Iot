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
      Navigator.pop(context);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inscription')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: nomController, decoration: InputDecoration(labelText: 'Nom')),
            TextField(controller: prenomController, decoration: InputDecoration(labelText: 'Prénom')),
            DropdownButton<String>(
              value: role,
              items: ['patient', 'medecin']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (value) => setState(() => role = value!),
            ),
            if (role == 'patient')
              TextField(controller: cinController, decoration: InputDecoration(labelText: 'CIN')),
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Mot de passe'), obscureText: true),
            ElevatedButton(onPressed: register, child: Text('inscrire')),
          ],
        ),
      ),
    );
  }
}
