import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocenteRegistroPresenzePage extends StatelessWidget {
  final String corsoId;

  const DocenteRegistroPresenzePage({super.key, required this.corsoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text("Registro presenze"),
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

          final data = snapshot.data!.data();
          if (data == null) {
            return const Center(
              child: Text("Nessun registro trovato",
                  style: TextStyle(color: Colors.white)),
            );
          }

          final studenti = List<Map<String, dynamic>>.from(data["studenti"]);
          final lezioni = List<Map<String, dynamic>>.from(data["lezioni"]);
          final presenze = Map<String, dynamic>.from(data["presenze"]);

          if (studenti.isEmpty || lezioni.isEmpty) {
            return const Center(
              child: Text(
                "Registro vuoto",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.indigoAccent),
              dataRowColor: WidgetStateProperty.all(
                Colors.white.withOpacity(0.05),
              ),
              columns: [
                const DataColumn(
                  label: Text(
                    "Studente",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),

                // ⭐ Colonne lezioni
                ...lezioni.map(
                      (lez) => DataColumn(
                    label: Text(
                      "${lez["data"]}\n${lez["tipo"]}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],

              rows: studenti.map((studente) {
                final uid = studente["uid"];
                final nome = studente["nome"];
                final cognome = studente["cognome"];

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        "$nome $cognome",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),

                    // ⭐ Celle presenze
                    ...lezioni.map((lez) {
                      final lezioneId = lez["lezioneId"];

                      final valore = presenze[uid]?[lezioneId];

                      return DataCell(
                        Text(
                          valore == null ? "0" : valore.toString(),
                          style: TextStyle(
                            color: valore == 1
                                ? Colors.greenAccent
                                : valore == 0
                                ? Colors.redAccent
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
