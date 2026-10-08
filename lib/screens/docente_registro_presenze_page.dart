import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';


class DocenteRegistroPresenzePage extends StatelessWidget {
  final String corsoId;

  const DocenteRegistroPresenzePage({super.key, required this.corsoId});

  // ⭐ Scarica Excel e salva su Firebase Storage
  Future<void> _scaricaExcel(
      BuildContext context,
      List<Map<String, dynamic>> studenti,
      List<Map<String, dynamic>> lezioni,
      Map<String, dynamic> presenze,
      ) async {

    final excel = Excel.createExcel();
    final sheet = excel['Presenze'];

    // ⭐ Intestazione
    List<String> header = ["Nome", "Cognome", "Email"];
    for (var lez in lezioni) {
      header.add("${lez["data"]} - ${lez["tipo"]}");
    }
    header.add("Percentuale");
    sheet.appendRow(header);

    // ⭐ Righe studenti
    for (var stud in studenti) {
      final uid = stud["uid"];
      final nome = stud["nome"];
      final cognome = stud["cognome"];
      final email = stud["email"];

      int presenti = 0;
      List<dynamic> row = [nome, cognome, email];

      for (var lez in lezioni) {
        final lezId = lez["lezioneId"];
        final val = presenze[uid]?[lezId] ?? 0;

        if (val == 1) presenti++;
        row.add(val);
      }

      final percentuale = (presenti / lezioni.length * 100).toStringAsFixed(1);
      row.add(percentuale);

      sheet.appendRow(row);

      final isOk = double.parse(percentuale) >= 70;

      for (int col = 0; col < row.length; col++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: sheet.rows.length - 1))
            .cellStyle = CellStyle(
          backgroundColorHex: isOk ? "#AAFFAA" : "#FFAAAA",
        );
      }
    }


// ⭐ Converti Excel in bytes
    final bytes = excel.encode();

// ⭐ Nome file
    final nomeFile = "registro_${corsoId}_${DateTime.now().year}.xlsx";

// ⭐ Percorso sicuro
    final safeCorsoId = corsoId.replaceAll(" ", "_").replaceAll("/", "_");

    print("Percorso Storage: registri_presenze/$safeCorsoId/$nomeFile");

// ⭐ Percorso Firebase Storage
    final storageRef = FirebaseStorage.instance
        .ref()
        .child("registri_presenze/$safeCorsoId/$nomeFile");

// ⭐ Carica file
    await storageRef.putData(Uint8List.fromList(bytes!));

// ⭐ Ottieni URL
    final url = await storageRef.getDownloadURL();

// ⭐ Salva metadati in Firestore
    await FirebaseFirestore.instance.collection("download_registri").add({
      "corsoId": corsoId,
      "nomeFile": nomeFile,
      "fileUrl": url,
      "annoAccademico": "${DateTime.now().year}/${DateTime.now().year + 1}",
      "docenteUid": FirebaseAuth.instance.currentUser!.uid,
      "timestamp": FieldValue.serverTimestamp(),
    });


    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Registro salvato nella sezione Download"),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ⭐ Popup reset
  void _showResetPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text("Resetta registro presenze", style: TextStyle(color: Colors.white)),
          content: const Text(
            "Questa operazione cancellerà:\n"
                "- tutti gli studenti\n"
                "- tutte le lezioni\n"
                "- tutte le presenze\n\n"
                "⚠️ Azione irreversibile.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: const Text("Annulla", style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Conferma", style: TextStyle(color: Colors.redAccent)),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("registro_presenze")
                    .doc(corsoId)
                    .set({
                  "studenti": [],
                  "lezioni": [],
                  "presenze": {}
                }, SetOptions(merge: true));
                // ⭐ Rimuovi tutti gli studenti dal corso
                await FirebaseFirestore.instance
                    .collection("corsi")
                    .doc(corsoId)
                    .update({
                  "studenti": [],
                });





                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Registro presenze resettato"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

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

          // ⭐ Se ci sono studenti ma NON ci sono lezioni → mostra solo la lista studenti
          // ⭐ Se ci sono studenti ma NON ci sono lezioni → mostra tabella con solo studenti
          if (studenti.isNotEmpty && lezioni.isEmpty) {
            return Column(
              children: [
                const SizedBox(height: 10),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: const Text("Scarica registro (Excel)", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    _scaricaExcel(context, studenti, [], {});
                  },
                ),

                const SizedBox(height: 10),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text("Resetta registro presenze", style: TextStyle(color: Colors.white)),
                  onPressed: () => _showResetPopup(context),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.indigoAccent),

                      columns: const [
                        DataColumn(
                          label: Text(
                            "Studente",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Percentuale",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],

                      rows: studenti.map((studente) {
                        final nome = studente["nome"];
                        final cognome = studente["cognome"];

                        return DataRow(
                          color: WidgetStateProperty.all(
                            Colors.blueGrey.withOpacity(0.15),
                          ),
                          cells: [
                            DataCell(
                              Text(
                                "$nome $cognome",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const DataCell(
                              Text(
                                "0%",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            );
          }

// ⭐ Se NON ci sono studenti → registro vuoto
          if (studenti.isEmpty) {
            return const Center(
              child: Text(
                "Nessuno studente iscritto.",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }


          return Column(
            children: [
              const SizedBox(height: 10),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                child: const Text("Scarica registro (Excel)", style: TextStyle(color: Colors.white)),
                onPressed: () {
                  _scaricaExcel(context, studenti, lezioni, presenze);
                },
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text("Resetta registro presenze", style: TextStyle(color: Colors.white)),
                onPressed: () => _showResetPopup(context),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.indigoAccent),

                    columns: [
                      const DataColumn(
                        label: Text(
                          "Studente",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),

                      ...lezioni.map(
                            (lez) => DataColumn(
                          label: Text(
                            "${lez["data"]}\n${lez["tipo"]}",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),

                      const DataColumn(
                        label: Text(
                          "Percentuale",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],

                    rows: studenti.map((studente) {
                      final uid = studente["uid"];
                      final nome = studente["nome"];
                      final cognome = studente["cognome"];

                      int presenti = 0;

                      for (var lez in lezioni) {
                        final lezId = lez["lezioneId"];
                        final val = presenze[uid]?[lezId] ?? 0;
                        if (val == 1) presenti++;
                      }

                      final percentuale = (presenti / lezioni.length * 100);
                      final isOk = percentuale >= 70;

                      return DataRow(
                        color: WidgetStateProperty.all(
                          isOk
                              ? Colors.green.withOpacity(0.15)
                              : Colors.red.withOpacity(0.15),
                        ),
                        cells: [
                          DataCell(
                            Text(
                              "$nome $cognome",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),

                          ...lezioni.map((lez) {
                            final lezioneId = lez["lezioneId"];
                            final valore = presenze[uid]?[lezioneId] ?? 0;

                            return DataCell(
                              Text(
                                valore.toString(),
                                style: TextStyle(
                                  color: valore == 1
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),

                          DataCell(
                            Text(
                              "${percentuale.toStringAsFixed(1)}%",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
