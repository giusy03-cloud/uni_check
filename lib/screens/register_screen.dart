import 'package:flutter/material.dart';
import 'package:uni_check_neww/screens/login_screen.dart';
import '../auth.dart';
import '../services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String selectedRole = "studente"; // default

  final auth = Auth();
  final userService = UserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrati")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),

            const SizedBox(height: 20),

            DropdownButton<String>(
              value: selectedRole,
              items: const [
                DropdownMenuItem(value: "studente", child: Text("Studente")),
                DropdownMenuItem(value: "docente", child: Text("Docente")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                try {
                  final user = await auth.createUserWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );

                  if (user != null) {
                    await userService.saveUserRole(
                      uid: user.uid,
                      ruolo: selectedRole,
                    );

                    // Mostra messaggio di successo
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Registrazione completata! Ora effettua l'accesso."),
                        backgroundColor: Colors.indigo,
                      ),
                    );

                    // NAVIGAZIONE SICURA DOPO LO SNACKBAR
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    });
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Errore: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Crea Account"),
            )
          ],
        ),
      ),
    );
  }
}
