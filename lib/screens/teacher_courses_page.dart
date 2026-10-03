import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uni_check_neww/screens/studenti_iscritti_page.dart';
import '../auth.dart';
import 'crea_lezione_page.dart';
import 'lezioni_corso_page.dart';

class TeacherCoursesPage extends StatelessWidget {
  const TeacherCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Auth();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text("I miei corsi"),
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

          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("corsi")
                .where("docenteUid", isEqualTo: user!.uid)   // ⭐ CAMBIATO
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              final corsi = snapshot.data!.docs;

              if (corsi.isEmpty) {
                return const Center(
                  child: Text(
                    "Non hai ancora creato corsi.",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: corsi.length,
                itemBuilder: (context, index) {
                  final corso = corsi[index].data();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              corso["nome"],
                              style: const TextStyle(color: Colors.white, fontSize: 20),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "Anno accademico: ${corso["annoAccademico"]}\n"
                                  "CFU: ${corso["cfu"]}\n"
                                  "Lezioni totali: ${corso["numeroLezioniTotali"]}",
                              style: const TextStyle(color: Colors.white70),
                            ),

                            const SizedBox(height: 12),

                            // ⭐ Bottone studenti iscritti
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigoAccent,
                              ),
                              child: const Text("Studenti iscritti", style: TextStyle(color: Colors.white)),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentiIscrittiPage(
                                      corsoId: corsi[index].id,
                                      nomeCorso: corso["nome"],
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 8),

                            // ⭐ Bottone crea lezione
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent.shade700,
                              ),
                              child: const Text("Crea lezione", style: TextStyle(color: Colors.white)),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CreaLezionePage(
                                      corsoId: corsi[index].id,
                                      nomeCorso: corso["nome"],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                              ),
                              child: const Text(
                                "Lezioni del corso",
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LezioniCorsoPage(
                                      corsoId: corsi[index].id,
                                      nomeCorso: corso["nome"],
                                    ),
                                  ),
                                );
                              },
                            ),

                          ],
                        ),
                      ),


                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
