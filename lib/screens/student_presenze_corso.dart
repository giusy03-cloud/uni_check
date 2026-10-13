import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentPresenzeCorsoPage extends StatelessWidget {
  final String corsoId;
  final String nomeCorso;

  const StudentPresenzeCorsoPage({
    super.key,
    required this.corsoId,
    required this.nomeCorso,
  });

  @override
  Widget build(BuildContext context) {
    final uidStudente = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text("Presenze - $nomeCorso"),
        backgroundColor: Colors.indigoAccent,
        centerTitle: true,
      ),

      body: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection("registro_presenze")
            .doc(corsoId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final registro = snapshot.data!.data();
          if (registro == null ||
              registro["presenze"] == null ||
              registro["presenze"][uidStudente] == null) {
            return const Center(
              child: Text(
                "Nessuna presenza registrata.",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          final presenzeStudente =
          Map<String, dynamic>.from(registro["presenze"][uidStudente]);

          return StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("lezioni")
                .where("corsoId", isEqualTo: corsoId)
                .orderBy("data")
                .snapshots(),
            builder: (context, snapshotLezioni) {
              if (!snapshotLezioni.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              final lezioni = snapshotLezioni.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: lezioni.length,
                itemBuilder: (context, index) {
                  final lezioneDoc = lezioni[index];
                  final lezione = lezioneDoc.data() as Map<String, dynamic>;
                  final lezioneId = lezioneDoc.id;

                  final data = (lezione["data"] as Timestamp).toDate();
                  final presenza = presenzeStudente[lezioneId];

                  // ⭐ Recupero codice e scadenza
                  final codice = lezione["codice"];
                  final scadenza = lezione["codiceScadenza"] != null
                      ? (lezione["codiceScadenza"] as Timestamp).toDate()
                      : null;

                  final now = DateTime.now();
                  final codiceAttivo =
                      codice != null && scadenza != null && scadenza.isAfter(now);

                  // ⭐ Icona presenza moderna
                  Icon iconaPresenza;

                  if (presenza == 1) {
                    iconaPresenza = const Icon(Icons.check_circle,
                        color: Colors.greenAccent, size: 36);
                  } else if (codiceAttivo) {
                    iconaPresenza = const Icon(Icons.hourglass_top,
                        color: Colors.yellowAccent, size: 36);
                  } else {
                    iconaPresenza = const Icon(Icons.cancel,
                        color: Colors.redAccent, size: 36);
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
                            iconaPresenza,
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

                        const SizedBox(height: 10),

                        // ⭐ STATO PRESENZA TESTUALE
                        Text(
                          presenza == 1
                              ? "Presente"
                              : codiceAttivo
                              ? "Codice attivo — puoi ancora registrare"
                              : "Assente",
                          style: TextStyle(
                            color: presenza == 1
                                ? Colors.greenAccent
                                : codiceAttivo
                                ? Colors.yellowAccent
                                : Colors.redAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );


            },
          );
        },
      ),
    );
  }
}
