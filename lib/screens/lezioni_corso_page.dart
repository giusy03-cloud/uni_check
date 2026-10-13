import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



String generaCodice() {
  const lettere = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  final rand = Random();
  return List.generate(4, (_) => lettere[rand.nextInt(lettere.length)]).join();
}

class LezioniCorsoPage extends StatefulWidget {
  final String corsoId;
  final String nomeCorso;

  const LezioniCorsoPage({
    super.key,
    required this.corsoId,
    required this.nomeCorso,
  });

  @override
  State<LezioniCorsoPage> createState() => _LezioniCorsoPageState();
}

class _LezioniCorsoPageState extends State<LezioniCorsoPage> {
  Timer? timer;

  @override
  void initState() {
    super.initState();

    // Aggiorna la pagina ogni secondo per il countdown
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text("Lezioni - ${widget.nomeCorso}"),
        backgroundColor: Colors.indigoAccent,
        centerTitle: true,
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("lezioni")
            .where("corsoId", isEqualTo: widget.corsoId)
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
                "Nessuna lezione creata.",
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
              final tipo = lezione["tipo"];
              final oraInizio = lezione["oraInizio"];
              final oraFine = lezione["oraFine"];

              final codice = lezione["codice"];

              final scadenza = lezione["codiceScadenza"] != null
                  ? (lezione["codiceScadenza"] as Timestamp).toDate()
                  : null;

              final now = DateTime.now();

              // ⭐ Lezione passata (solo se data < oggi)
              final oggi = DateTime(now.year, now.month, now.day);
              final lezionePassata = data.isBefore(oggi);

              // ⭐ Codice scaduto
              final codiceScaduto = scadenza != null && scadenza.isBefore(now);

              // ⭐ Nascondi lezioni passate o con codice scaduto
              if (lezionePassata || codiceScaduto) {
                return const SizedBox.shrink();
              }

              // Countdown
              String countdown = "";
              if (codice != null && scadenza != null) {
                final diff = scadenza.difference(now);
                if (diff.inSeconds > 0) {
                  countdown = "${diff.inSeconds}s";
                }
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

                    // ⭐ ICONA + TITOLO
                    Row(
                      children: [
                        Icon(
                          tipo == "teoria" ? Icons.menu_book : Icons.science,
                          color: Colors.indigoAccent,
                          size: 32,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "$tipo - ${data.day}/${data.month}/${data.year}",
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
                          "Orario: $oraInizio - $oraFine",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ⭐ NESSUN CODICE → GENERA
                    if (codice == null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.qr_code, color: Colors.white),
                          label: const Text("Genera codice", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigoAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            final nuovoCodice = generaCodice();

                            await FirebaseFirestore.instance
                                .collection("lezioni")
                                .doc(lezioneId)
                                .update({
                              "codice": nuovoCodice,
                              "codiceScadenza": Timestamp.fromDate(
                                DateTime.now().add(const Duration(minutes: 2)),
                              ),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Codice generato: $nuovoCodice")),
                            );
                          },
                        ),
                      ),
                    ],

                    // ⭐ CODICE ATTIVO
                    if (codice != null && !codiceScaduto) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.greenAccent),
                            const SizedBox(width: 10),
                            Text(
                              "Codice attivo: $codice ${countdown.isNotEmpty ? "($countdown)" : ""}",
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),




                    ],
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
