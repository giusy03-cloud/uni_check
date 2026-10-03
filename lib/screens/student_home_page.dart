import 'package:uni_check_neww/screens/student_courses_page.dart';
import 'package:uni_check_neww/screens/student_my_courses_page.dart';

import '../auth.dart';
import 'login_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import 'notifiche_studente_page.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
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
    final auth = Auth();
    final currentUser = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Studente"),
        backgroundColor: Colors.indigoAccent,
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
                        ? const Icon(Icons.person,
                        color: Colors.white, size: 40)
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

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () => Navigator.pop(context),
            ),

            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text("Presenze"),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text("Assenze"),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.book),
              title: const Text("Corsi"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentCoursesPage()),
                );
              },

            ),

            ListTile(
              leading: const Icon(Icons.star),
              title: const Text("I miei corsi"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentMyCoursesPage()),
                );
              },
            ),
            currentUser == null
                ? const ListTile(
              leading: Icon(Icons.notifications, color: Colors.white),
              title: Text("Notifiche", style: TextStyle(color: Colors.white)),
            )
                : StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("notifiche")
                  .where("uidDestinatario", isEqualTo: currentUser.uid)
                  .where("letto", isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                int nonLette = snapshot.hasData ? snapshot.data!.docs.length : 0;

                return ListTile(
                  leading: Stack(
                    children: [
                      const Icon(Icons.notifications, color: Colors.white),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutBack,

                          // ⭐ cambia dimensione quando cambia il numero → anima
                          width: 22 + (nonLette.toString().length * 2),
                          height: 22,

                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),

                          // ⭐ il numero è sempre bianco → non sembra più una D
                          child: Center(
                            child: Text(
                              nonLette.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                  title: const Text("Notifiche", style: TextStyle(color: Colors.black)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificheStudentePage()),
                    );
                  },
                );
              },
            ),


            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
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

      body: Center(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigoAccent,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          icon: const Icon(Icons.camera_alt, size: 30),
          label: const Text(
            "Registra Presenza",
            style: TextStyle(fontSize: 20),
          ),
          onPressed: () {
            // Apri scanner QR
          },
        ),
      ),
    );
  }
}
