import 'package:flutter/material.dart';
import 'package:uni_check_neww/screens/student_home_page.dart';
import 'package:uni_check_neww/screens/teacher_home_page.dart';
import 'package:uni_check_neww/screens/register_screen.dart';
import '../auth.dart';
import '../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final auth = Auth();
  final userService = UserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Accedi")),
      body: Padding(
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

            ElevatedButton(
              onPressed: () async {
                try {
                  final user = await auth.signInWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );

                  // Se login ok → controlla ruolo
                  if (user != null) {
                    final ruolo = await userService.getUserRole(user.uid);

                    if (ruolo == "studente") {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const StudentHomePage()),
                      );
                    } else if (ruolo == "docente") {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const TeacherHomePage()),
                      );
                    } else {
                      // Utente registrato ma senza ruolo (caso raro)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Ruolo non trovato. Registrazione incompleta."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }

                } catch (e) {
                  // Qui intercettiamo l'errore: utente NON registrato
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Account non trovato. Registrati per continuare."),
                      backgroundColor: Colors.red,
                    ),
                  );

                  // Vai alla pagina di registrazione
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                }
              },
              child: const Text("Accedi"),
            ),
          ],
        ),
      ),
    );
  }
}
