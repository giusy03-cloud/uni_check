import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentiARischioPage extends StatelessWidget {
  final String corsoId;
  final String nomeCorso;

  const StudentiARischioPage({
    super.key,
    required this.corsoId,
    required this.nomeCorso,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text("Studenti a rischio - $nomeCorso"),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("registro_presenze")
            .doc(corsoId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final data = snapshot.data!.data();
          if (data == null) {
            return const Center(
              child: Text("Nessun dato disponibile",
                  style: TextStyle(color: Colors.white)),
            );
          }

          final studenti = List<Map<String, dynamic>>.from(data["studenti"]);
          final lezioni = List<Map<String, dynamic>>.from(data["lezioni"]);
          final presenze = Map<String, dynamic>.from(data["presenze"]);

          final int totaleLezioni = lezioni.length;

          // ⭐ Calcolo studenti a rischio (<70%)
          final studentiARischio = studenti.where((stud) {
            final uid = stud["uid"];
            final presenzeStudente = presenze[uid] ?? {};

            int presenti = 0;
            for (var lez in lezioni) {
              final lezId = lez["lezioneId"];
              if (presenzeStudente[lezId] == 1) presenti++;
            }

            final percentuale = (presenti / totaleLezioni) * 100;
            return percentuale < 70;
          }).toList();

          if (studentiARischio.isEmpty) {
            return const Center(
              child: Text(
                "Nessuno studente a rischio 🎉",
                style: TextStyle(color: Colors.greenAccent, fontSize: 20),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: studentiARischio.length,
            itemBuilder: (context, index) {
              final stud = studentiARischio[index];
              final uid = stud["uid"];
              final presenzeStudente = presenze[uid] ?? {};

              int presenti = 0;
              for (var lez in lezioni) {
                final lezId = lez["lezioneId"];
                if (presenzeStudente[lezId] == 1) presenti++;
              }

              final percentuale = (presenti / totaleLezioni) * 100;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${stud["nome"]} ${stud["cognome"]}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Email: ${stud["email"]}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Percentuale: ${percentuale.toStringAsFixed(1)}%",
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
}
