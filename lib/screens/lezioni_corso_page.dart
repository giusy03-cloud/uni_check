import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'docente_mostra_qr_page.dart';

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

    // Aggiorna la pagina ogni secondo
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

              final qrAttivo = lezione["qrAttivo"] ?? false;
              final qrScadenza = lezione["qrScadenza"] != null
                  ? (lezione["qrScadenza"] as Timestamp).toDate()
                  : null;

              final now = DateTime.now();
              final qrScaduto = qrScadenza != null && qrScadenza.isBefore(now);

              // Calcolo countdown
              String countdown = "";
              if (qrAttivo && !qrScaduto && qrScadenza != null) {
                final diff = qrScadenza.difference(now);
                countdown = "${diff.inSeconds}s";
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
                        "$tipo - ${data.day}/${data.month}/${data.year}",
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Orario: $oraInizio - $oraFine",
                        style: const TextStyle(color: Colors.white70),
                      ),

                      const SizedBox(height: 12),

                      // QR NON ATTIVO
                      if (!qrAttivo) ...[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent.shade700,
                          ),
                          child: const Text("Genera QR", style: TextStyle(color: Colors.white)),
                          onPressed: () async {
                            final token = DateTime.now().millisecondsSinceEpoch.toString();

                            await FirebaseFirestore.instance
                                .collection("lezioni")
                                .doc(lezioneId)
                                .update({
                              "qrToken": token,
                              "qrScadenza": Timestamp.fromDate(
                                DateTime.now().add(const Duration(minutes: 2)),
                              ),
                              "qrAttivo": true,
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("QR generato!")),
                            );
                          },
                        ),
                      ],

                      // QR SCADUTO
                      if (qrAttivo && qrScaduto) ...[
                        Text(
                          "QR scaduto",
                          style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                        ),
                      ],

                      // QR ATTIVO
                      if (qrAttivo && !qrScaduto && qrScadenza != null) ...[
                        Text(
                          "QR attivo ($countdown)",
                          style: TextStyle(
                            color: Colors.greenAccent.shade200,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Scade alle: ${qrScadenza.hour}:${qrScadenza.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(color: Colors.white70),
                        ),

                        const SizedBox(height: 12),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigoAccent,
                          ),
                          child: const Text("Mostra QR", style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DocenteMostraQRPage(lezioneId: lezioneId),
                              ),
                            );
                          },
                        ),
                      ],
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
