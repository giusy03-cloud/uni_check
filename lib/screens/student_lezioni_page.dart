import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'student_presenza_page.dart';

class StudentLezioniPage extends StatelessWidget {
  final String corsoId;
  final String nomeCorso;

  const StudentLezioniPage({
    super.key,
    required this.corsoId,
    required this.nomeCorso,
  });

  // ⭐ Controlla se lo studente ha già registrato la presenza
  Future<bool> presenzaGiaRegistrata(String lezioneId, String uidStudente) async {
    final snap = await FirebaseFirestore.instance
        .collection("presenze")
        .where("lezioneId", isEqualTo: lezioneId)
        .where("studenteId", isEqualTo: uidStudente)
        .get();

    return snap.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final uidStudente = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text("Lezioni - $nomeCorso"),
        backgroundColor: Colors.indigoAccent,
        centerTitle: true,
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("lezioni")
            .where("corsoId", isEqualTo: corsoId)
            .orderBy("data")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final lezioni = snapshot.data!.docs;

          if (lezioni.isEmpty) {
            return const Center(
              child: Text(
                "Non ci sono lezioni programmate.",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lezioni.length,
            itemBuilder: (context, index) {
              final lezioneDoc = lezioni[index];
              final lezione = lezioneDoc.data() as Map<String, dynamic>;
              final lezioneId = lezioneDoc.id;

              final data = (lezione["data"] as Timestamp).toDate();

              final scadenza = lezione["codiceScadenza"] != null
                  ? (lezione["codiceScadenza"] as Timestamp).toDate()
                  : null;

              final codice = lezione["codice"];
              final now = DateTime.now();
              final dataSoloGiorno = DateTime(data.year, data.month, data.day);
              final oggi = DateTime(now.year, now.month, now.day);

              final codiceScaduto = codice != null &&
                  scadenza != null &&
                  scadenza.isBefore(now);

              if (codice == null || codiceScaduto) {
                return const SizedBox.shrink();
              }

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

                    // ⭐ ICONA + TITOLO LEZIONE
                    Row(
                      children: [
                        const Icon(Icons.event, color: Colors.indigoAccent, size: 32),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "${lezione["tipo"]} - ${data.day}/${data.month}/${data.year}",
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

                    // ⭐ ORARIO
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.white70, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          "Orario: ${lezione["oraInizio"]} - ${lezione["oraFine"]}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ⭐ BOTTONE REGISTRA PRESENZA
                    FutureBuilder(
                      future: presenzaGiaRegistrata(lezioneId, uidStudente),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const SizedBox();
                        }

                        final giaPresente = snap.data!;

                        if (giaPresente) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.greenAccent),
                                SizedBox(width: 10),
                                Text(
                                  "Presenza già registrata",
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.login, color: Colors.white),
                            label: const Text(
                              "Registra presenza",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigoAccent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentPresenzaPage(
                                    lezioneId: lezioneId,
                                    nomeLezione: lezione["tipo"],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
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
}
