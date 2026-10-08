import 'dart:ui';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uni_check_neww/screens/create_course_page.dart';
import 'package:uni_check_neww/screens/teacher_courses_page.dart';
import '../auth.dart';
import 'docente_download_page.dart';
import 'login_screen.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  String? base64Image;
  String email = "";

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
        elevation: 0,
        centerTitle: true,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),

      endDrawer: Drawer(
        backgroundColor: const Color(0xFF1A1A2E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.indigoAccent),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: base64Image != null
                        ? MemoryImage(base64Decode(base64Image!))
                        : null,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: base64Image == null
                        ? const Icon(Icons.person, color: Colors.white, size: 40)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),

            // 🔵 CORSI
            ListTile(
              leading: const Icon(Icons.book, color: Colors.white),
              title: const Text("I miei corsi", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherCoursesPage()),
                );
              },

            ),

            // 🔵 STUDENTI ISCRITTI
            ListTile(
              leading: const Icon(Icons.group, color: Colors.white),
              title: const Text("Studenti iscritti",
                  style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),

            // 🔵 STUDENTI PRESENTI
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.greenAccent),
              title: const Text("Studenti presenti",
                  style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),

            // 🔵 STUDENTI ASSENTI
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.redAccent),
              title: const Text("Studenti assenti",
                  style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            const Divider(color: Colors.white54),

            ListTile(
              leading: const Icon(Icons.download, color: Colors.white),
              title: const Text("Download", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DocenteDownloadPage(
                      docenteUid: FirebaseAuth.instance.currentUser!.uid,
                    ),
                  ),
                );
              },
            ),


            const Divider(color: Colors.white54),

            // 🔵 LOGOUT
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text("Logout", style: TextStyle(color: Colors.white)),
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


      body: Stack(
        children: [
          // 🔵 Effetto vetro lucido leggero sullo sfondo
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _modernButton(
                    icon: Icons.book,
                    text: "Crea Corso",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateCoursePage()),
                      );
                    },

                  ),

                  const SizedBox(height: 25),

                  _modernButton(
                    icon: Icons.schedule,
                    text: "Programma Lezione",
                    onPressed: () {},
                  ),

                  const SizedBox(height: 25),

                  _modernButton(
                    icon: Icons.qr_code,
                    text: "Genera QR",
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔵 Pulsanti moderni stile indaco + vetro
  Widget _modernButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigoAccent.withOpacity(0.9),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 6,
          shadowColor: Colors.indigoAccent.withOpacity(0.4),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white, // 👈 testo bianco
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
