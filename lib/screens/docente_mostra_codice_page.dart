import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocenteMostraCodicePage extends StatelessWidget {
  final String lezioneId;

  const DocenteMostraCodicePage({super.key, required this.lezioneId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text("Codice Lezione"),
        backgroundColor: Colors.indigoAccent,
        centerTitle: true,
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("lezioni")
            .doc(lezioneId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final lezione = snapshot.data!.data();
          if (lezione == null) {
            return const Center(
              child: Text("Lezione non trovata", style: TextStyle(color: Colors.white)),
            );
          }

          final codice = lezione["codice"];

          final scadenza = lezione["codiceScadenza"] != null
              ? (lezione["codiceScadenza"] as Timestamp).toDate()
              : null;

          final now = DateTime.now();
          final codiceScaduto = scadenza == null || scadenza.isBefore(now);

          if (codice == null) {
            return const Center(
              child: Text(
                "Codice non generato",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  codice,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  codiceScaduto ? "Codice scaduto" : "Codice attivo",
                  style: TextStyle(
                    color: codiceScaduto ? Colors.redAccent : Colors.greenAccent,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
