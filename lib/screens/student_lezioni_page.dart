import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'student_presenza_page.dart';

class StudentLezioniPage extends StatelessWidget {
  final String corsoId;
  final String nomeCorso;

  const StudentLezioniPage({
    super.key,
    required this.corsoId,
    required this.nomeCorso,
  });

  @override
  Widget build(BuildContext context) {
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

              // ⭐ Recupero scadenza codice
              final scadenza = lezione["codiceScadenza"] != null
                  ? (lezione["codiceScadenza"] as Timestamp).toDate()
                  : null;

              final codice = lezione["codice"];
              final now = DateTime.now();
              final oggi = DateTime(now.year, now.month, now.day);

              // ⭐ Lezione passata (data < oggi)
              final lezionePassata = data.isBefore(oggi);

              // ⭐ Codice scaduto (solo se esiste un codice)
              final codiceScaduto = codice != null &&
                  scadenza != null &&
                  scadenza.isBefore(now);

              // ⭐ Nascondi lezioni passate o con codice scaduto o senza codice
              if (lezionePassata || codiceScaduto || codice == null) {
                return const SizedBox.shrink();
              }

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
                      Text(
                        "${lezione["tipo"]} - ${data.day}/${data.month}/${data.year}",
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Orario: ${lezione["oraInizio"]} - ${lezione["oraFine"]}",
                        style: const TextStyle(color: Colors.white70),
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigoAccent,
                        ),
                        child: const Text(
                          "Registra presenza",
                          style: TextStyle(color: Colors.white),
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
                    ],
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
