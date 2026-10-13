import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth.dart';
import 'create_course_page.dart';
import 'teacher_courses_page.dart';
import 'login_screen.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  String? base64Image;
  String email = "";
  String nome = "";
  String cognome = "";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final auth = Auth();
    final user = auth.currentUser;

    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("utenti")
        .doc(user.uid)
        .get();

    if (doc.exists) {
      setState(() {
        base64Image = doc.data()?["imageBase64"];
        email = doc.data()?["email"] ?? "";
        nome = doc.data()?["nome"] ?? "";
        cognome = doc.data()?["cognome"] ?? "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),

      appBar: AppBar(
        title: const Text("Home Docente"),
        backgroundColor: Colors.indigoAccent,
        centerTitle: true,
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // ⭐ FOTO PROFILO
                CircleAvatar(
                  radius: 60,
                  backgroundImage: base64Image != null
                      ? MemoryImage(base64Decode(base64Image!))
                      : null,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: base64Image == null
                      ? const Icon(Icons.person, color: Colors.white, size: 60)
                      : null,
                ),

                const SizedBox(height: 20),

                // ⭐ BENVENUTO
                const Text(
                  "Benvenuto/a",
                  style: TextStyle(color: Colors.white, fontSize: 26),
                ),

                const SizedBox(height: 10),

                // ⭐ NOME + COGNOME
                Text(
                  "$nome $cognome",
                  style: const TextStyle(color: Colors.white70, fontSize: 20),
                ),

                const SizedBox(height: 40),

                // ⭐ ICONE GRANDI
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _homeIcon(
                        icon: Icons.book,
                        label: "Crea corso",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateCoursePage()),
                          );
                        },
                      ),

                      _homeIcon(
                        icon: Icons.star,
                        label: "I miei corsi",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TeacherCoursesPage()),
                          );
                        },
                      ),

                      _homeIcon(
                        icon: Icons.logout,
                        label: "Logout",
                        onTap: () async {
                          final auth = Auth();
                          await auth.signOut();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ⭐ WIDGET ICONA MODERNA
  Widget _homeIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: CircleAvatar(
            radius: 35,
            backgroundColor: Colors.indigoAccent,
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
