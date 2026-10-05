import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth.dart';
import 'studenti_iscritti_page.dart';
import 'crea_lezione_page.dart';
import 'lezioni_corso_page.dart';
import 'docente_registro_presenze_page.dart';

class TeacherCoursesPage extends StatelessWidget {
  const TeacherCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Auth();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Errore autenticazione")),
      );
    }

    final uid = user.uid;

    // ⭐ Query 1: corsi creati da me
    final streamProprietario = FirebaseFirestore.instance
        .collection("corsi")
        .where("docenteUid", isEqualTo: uid)
        .snapshots();

    // ⭐ Query 2: corsi dove sono docente condiviso
    final streamCondivisi = FirebaseFirestore.instance
        .collection("corsi")
        .where("docentiCondivisi", arrayContains: uid)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text("I miei corsi"),
        backgroundColor: Colors.indigoAccent,
        centerTitle: true,
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: streamProprietario,
              builder: (context, snapshot1) {
                return StreamBuilder(
                  stream: streamCondivisi,
                  builder: (context, snapshot2) {
                    if (!snapshot1.hasData || !snapshot2.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    final proprietario = snapshot1.data!.docs;
                    final condivisi = snapshot2.data!.docs;

                    // ⭐ Unisci corsi
                    final corsi = [...proprietario, ...condivisi];

                    if (corsi.isEmpty) {
                      return const Center(
                        child: Text(
                          "Non hai corsi.",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: corsi.length,
                      itemBuilder: (context, index) {
                        final doc = corsi[index];
                        final corso = doc.data();

                        final bool isCondiviso = corso["docenteUid"] != uid;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      corso["nome"],
                                      style: const TextStyle(color: Colors.white, fontSize: 20),
                                    ),
                                    if (isCondiviso)
                                      Container(
                                        margin: const EdgeInsets.only(left: 10),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orangeAccent,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          "Condiviso",
                                          style: TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  "Anno accademico: ${corso["annoAccademico"]}\n"
                                      "CFU: ${corso["cfu"]}\n"
                                      "Lezioni totali: ${corso["numeroLezioniTotali"]}",
                                  style: const TextStyle(color: Colors.white70),
                                ),

                                const SizedBox(height: 12),

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
                                          corsoId: doc.id,
                                          nomeCorso: corso["nome"],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 8),

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
                                          corsoId: doc.id,
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
                                  child: const Text("Lezioni del corso", style: TextStyle(color: Colors.white)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => LezioniCorsoPage(
                                          corsoId: doc.id,
                                          nomeCorso: corso["nome"],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 8),

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orangeAccent,
                                  ),
                                  child: const Text("Registro presenze", style: TextStyle(color: Colors.white)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DocenteRegistroPresenzePage(
                                          corsoId: doc.id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
