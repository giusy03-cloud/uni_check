import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uni_check_neww/screens/student_lezioni_page.dart';
import '../auth.dart';

class StudentMyCoursesPage extends StatelessWidget {
  const StudentMyCoursesPage({super.key});

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

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("corsi")
            .where("studenti", arrayContains: user!.uid)
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
                "Non sei iscritto/a a nessun corso.",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: corsi.length,
            itemBuilder: (context, index) {
              final corsoDoc = corsi[index];
              final corso = corsoDoc.data() as Map<String, dynamic>;

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
                          "CFU: ${corso["cfu"]}\n"
                              "Anno: ${corso["annoCorso"]}\n"
                              "Docente: ${corso["docenteEmail"] ?? "Docente"}",
                          style: const TextStyle(color: Colors.white70),
                        ),

                        const SizedBox(height: 12),

                        // ⭐ Bottone LEZIONI DEL CORSO
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigoAccent,
                          ),
                          child: const Text("Lezioni del corso", style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentLezioniPage(
                                  corsoId: corsoDoc.id,
                                  nomeCorso: corso["nome"],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 8),

                        // ⭐ Bottone DISISCRIZIONE
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          child: const Text(
                            "Disiscriviti",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () async {
                            // ⭐ 1. Rimuovi lo studente dal corso
                            await FirebaseFirestore.instance
                                .collection("corsi")
                                .doc(corsoDoc.id)
                                .update({
                              "studenti": FieldValue.arrayRemove([user.uid])
                            });

                            // ⭐ 2. Rimuovi lo studente dalla tabella presenze
                            await FirebaseFirestore.instance
                                .collection("registro_presenze")
                                .doc(corsoDoc.id)
                                .update({
                              "studenti": FieldValue.arrayRemove([
                                {
                                  "uid": user.uid,
                                  "nome": corso["nomeStudente"] ?? "",
                                  "cognome": corso["cognomeStudente"] ?? "",
                                }
                              ])
                            });

                            // ⭐ 3. Rimuovi tutte le sue presenze (celle)
                            await FirebaseFirestore.instance
                                .collection("registro_presenze")
                                .doc(corsoDoc.id)
                                .update({
                              "presenze.${user.uid}": FieldValue.delete(),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Disiscrizione completata"),
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
    );
  }
}
