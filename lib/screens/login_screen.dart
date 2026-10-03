import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uni_check_neww/screens/student_home_page.dart';
import 'package:uni_check_neww/screens/teacher_home_page.dart';
import 'package:uni_check_neww/screens/admin_dashboard.dart';
import 'package:uni_check_neww/screens/register_screen.dart';
import '../auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool showPassword = false;
  bool isLoading = false;

  final auth = Auth();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "LOGIN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // EMAIL
                    TextField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.email, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.indigoAccent),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // PASSWORD
                    TextField(
                      controller: passwordController,
                      obscureText: !showPassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() => showPassword = !showPassword);
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.indigoAccent),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // SIGN IN BUTTON
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                      setState(() => isLoading = true);

                      try {
                        final user = await auth.signInWithEmailAndPassword(
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                        );

                        if (user == null) {
                          setState(() => isLoading = false);
                          return;
                        }

                        final doc = await FirebaseFirestore.instance
                            .collection("utenti")
                            .doc(user.uid)
                            .get();

                        if (!doc.exists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Utente non trovato."),
                              backgroundColor: Colors.red,
                            ),
                          );
                          setState(() => isLoading = false);
                          return;
                        }

                        final ruolo = doc["ruolo"];
                        final approved = doc["approved"];

                        // STUDENTE
                        if (ruolo == "studente") {
                          setState(() => isLoading = false);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const StudentHomePage()),
                          );
                          return;
                        }

                        // DOCENTE RIFIUTATO
                        if (ruolo == "rifiutato") {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("La tua richiesta docente è stata rifiutata."),
                              backgroundColor: Colors.red,
                            ),
                          );
                          emailController.clear();
                          passwordController.clear();
                          setState(() => isLoading = false);
                          return;
                        }

                        // DOCENTE NON APPROVATO
                        if (ruolo == "pending_docente") {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Il tuo account docente è in attesa di approvazione."),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          emailController.clear();
                          passwordController.clear();
                          setState(() => isLoading = false);
                          return;
                        }

                        // DOCENTE APPROVATO
                        if (ruolo == "docente" && approved == true) {
                          setState(() => isLoading = false);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const TeacherHomePage()),
                          );
                          return;
                        }

                        // ADMIN
                        if (ruolo == "admin") {
                          setState(() => isLoading = false);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminDashboard()),
                          );
                          return;
                        }

                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Account non trovato. Registrati."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() => isLoading = false);

                        Future.delayed(const Duration(milliseconds: 200), () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        });
                      }
                    },
                    child: isLoading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle_outline,
                            color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          "Sign In",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  )


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
