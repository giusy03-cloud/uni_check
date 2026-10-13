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
    final auth = Auth();
    final currentUser = auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text("Home Studente"),
        backgroundColor: Colors.indigoAccent,
        centerTitle: true,
      ),

      body: Column(
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
          Text(
            "Benvenuto/a",
            style: const TextStyle(color: Colors.white, fontSize: 26),
          ),

          const SizedBox(height: 10),

          // ⭐ NOME + COGNOME
          Text(
            "$nome $cognome",
            style: const TextStyle(color: Colors.white70, fontSize: 20),
          ),

          const SizedBox(height: 40),

          // ⭐ ICONE IN BASSO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [

                // 📚 CORSI
                _homeIcon(
                  icon: Icons.book,
                  label: "Corsi",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentCoursesPage()),
                    );
                  },
                ),

                // ⭐ MIEI CORSI
                _homeIcon(
                  icon: Icons.star,
                  label: "Miei corsi",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentMyCoursesPage()),
                    );
                  },
                ),

                // 🔔 NOTIFICHE
                Column(
                  children: [
                    StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection("notifiche")
                          .where("uidDestinatario", isEqualTo: currentUser!.uid)
                          .where("letto", isEqualTo: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        int nonLette = 0;
                        if (snapshot.hasData) {
                          nonLette = snapshot.data!.docs.length;
                        }

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificheStudentePage()),
                            );
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.indigoAccent,
                                child: const Icon(Icons.notifications, color: Colors.white, size: 30),
                              ),

                              // ⭐ BADGE ROSSO
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
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
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 8),
                    const Text("Notifiche", style: TextStyle(color: Colors.white)),
                  ],
                ),



                // 🚪 LOGOUT
                _homeIcon(
                  icon: Icons.logout,
                  label: "Logout",
                  onTap: () async {
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
    );
  }

  // ⭐ WIDGET PER LE ICONE
  Widget _homeIcon({required IconData icon, required String label, required VoidCallback onTap}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.indigoAccent,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
