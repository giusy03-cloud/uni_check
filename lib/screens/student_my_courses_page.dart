import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uni_check_neww/screens/student_lezioni_page.dart';
import 'package:uni_check_neww/screens/student_presenze_corso.dart';
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
            .where("attivo", isEqualTo: true)
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ⭐ ICONA + TITOLO
                    Row(
                      children: [
                        const Icon(Icons.book, color: Colors.indigoAccent, size: 32),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            corso["nome"],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ⭐ BADGE CFU + ANNO
                    Row(
                      children: [
                        _badge("CFU: ${corso["cfu"]}"),
                        const SizedBox(width: 10),
                        _badge("Anno: ${corso["annoCorso"]}"),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ⭐ DOCENTE
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.white70, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          "Docente: ${corso["docenteEmail"] ?? "Docente"}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ⭐ BOTTONI
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        // ⭐ LEZIONI
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigoAccent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Lezioni", style: TextStyle(color: Colors.white)),
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
                        ),

                        const SizedBox(width: 10),

                        // ⭐ PRESENZE
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigoAccent,   // ⭐ ORA UGUALE
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Presenze", style: TextStyle(color: Colors.white)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentPresenzeCorsoPage(
                                    corsoId: corsoDoc.id,
                                    nomeCorso: corso["nome"],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),



                    const SizedBox(height: 10),

                    // ⭐ DISISCRIZIONE
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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

                          // ⭐ 2. Rimuovi lo studente dal registro presenze
                          final registroDoc = await FirebaseFirestore.instance
                              .collection("registro_presenze")
                              .doc(corsoDoc.id)
                              .get();

                          final listaStudenti = List<Map<String, dynamic>>.from(registroDoc["studenti"]);
                          listaStudenti.removeWhere((stud) => stud["uid"] == user.uid);

                          await FirebaseFirestore.instance
                              .collection("registro_presenze")
                              .doc(corsoDoc.id)
                              .update({
                            "studenti": listaStudenti,
                          });

                          // ⭐ 3. Rimuovi tutte le sue presenze
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
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ⭐ BADGE GRAFICO
  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.indigoAccent.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}
