import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth.dart';

class StudentCoursesPage extends StatelessWidget {
  const StudentCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Auth();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text("Corsi disponibili"),
        backgroundColor: Colors.indigoAccent,
        centerTitle: true,
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("corsi").snapshots(),
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
                "Nessun corso disponibile.",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: corsi.length,
            itemBuilder: (context, index) {
              final corso = corsi[index];
              final data = corso.data() as Map<String, dynamic>;

              final studenti = data["studenti"] as List<dynamic>? ?? [];
              final isIscritto = studenti.contains(user!.uid);

              final docenteEmail = data["docenteEmail"] ?? "Docente";

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    title: Text(
                      data["nome"],
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    subtitle: Text(
                      "CFU: ${data["cfu"]}\n"
                          "Anno: ${data["annoCorso"]}\n"
                          "Docente: $docenteEmail",
                      style: const TextStyle(color: Colors.white70),
                    ),

                    trailing: SizedBox(
                      width: 120,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          isIscritto ? Colors.redAccent : Colors.indigoAccent,
                        ),
                        child: Text(
                          isIscritto ? "Disiscriviti" : "Iscriviti",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        onPressed: () async {
                          // ⭐ DISISCRIZIONE
                          if (isIscritto) {
                            await FirebaseFirestore.instance
                                .collection("corsi")
                                .doc(corso.id)
                                .update({
                              "studenti": FieldValue.arrayRemove([user.uid])
                            });



                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Disiscrizione completata"),
                              ),
                            );
                          }

                          // ⭐ ISCRIZIONE
                          else {
                            await FirebaseFirestore.instance
                                .collection("corsi")
                                .doc(corso.id)
                                .update({
                              "studenti": FieldValue.arrayUnion([user.uid])
                            });

                            final userDoc = await FirebaseFirestore.instance
                                .collection("utenti")
                                .doc(user.uid)
                                .get();

                            final nomeStudente = userDoc.data()?["nome"] ?? "";
                            final cognomeStudente = userDoc.data()?["cognome"] ?? "";

                            await FirebaseFirestore.instance
                                .collection("registro_presenze")
                                .doc(corso.id)
                                .set({
                              "studenti": FieldValue.arrayUnion([
                                {
                                  "uid": user.uid,
                                  "nome": nomeStudente,
                                  "cognome": cognomeStudente,
                                }
                              ])
                            }, SetOptions(merge: true));

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Iscrizione completata!"),
                              ),
                            );
                          }
                        },
                      ),
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
