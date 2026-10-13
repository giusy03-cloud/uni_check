import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class DocenteRegistroPresenzePage extends StatelessWidget {
  final String corsoId;

  const DocenteRegistroPresenzePage({super.key, required this.corsoId});

  // -------------------------------------------------------------
  // ⭐ CONDIVISIONE FILE NATIVA
  // -------------------------------------------------------------
  Future<void> condividiFileNativo(String filePath) async {
    const platform = MethodChannel('share_channel');

    try {
      await platform.invokeMethod('shareFile', {
        'filePath': filePath,
        'text': 'Registro presenze del corso',
        'mimeType':
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      });
    } catch (e) {
      print("Errore nella condivisione: $e");
    }
  }

  // -------------------------------------------------------------
  // ⭐ ESPORTA EXCEL
  // -------------------------------------------------------------
  Future<void> esportaRegistroExcel(
      BuildContext context,
      List<Map<String, dynamic>> studenti,
      List<Map<String, dynamic>> lezioni,
      Map<String, dynamic> presenze,
      ) async {

    final excel = Excel.createExcel();
    final sheet = excel['Registro'];

    // ⭐ INTESTAZIONE
    List<String> header = ["Nome", "Cognome", "Email"];
    for (var lez in lezioni) {
      header.add("${lez["data"]} - ${lez["tipo"]}");
    }
    header.add("Percentuale");
    sheet.appendRow(header);

    // ⭐ RIGHE STUDENTI
    for (var stud in studenti) {
      final uid = stud["uid"];
      final nome = stud["nome"];
      final cognome = stud["cognome"];
      final email = stud["email"];

      int presenti = 0;
      List<dynamic> row = [nome, cognome, email];

      // ⭐ Presenze
      for (var lez in lezioni) {
        final lezId = lez["lezioneId"];
        final val = presenze[uid]?[lezId] ?? 0;

        if (val == 1) presenti++;
        row.add(val);
      }

      // ⭐ Percentuale
      final percentualeNum = (presenti / lezioni.length * 100);
      final percentuale = "${percentualeNum.toStringAsFixed(0)}%";
      row.add(percentuale);

      // ⭐ Aggiungi riga
      sheet.appendRow(row);

      // ⭐ Colora la riga appena aggiunta
      final rowIndex = sheet.rows.length - 1;

      for (int col = 0; col < row.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
        );

        // ⭐ Celle delle presenze (dal 3° elemento fino alla penultima colonna)
        if (col >= 3 && col < row.length - 1) {
          final valore = row[col];
          cell.cellStyle = CellStyle(
            backgroundColorHex: valore == 1 ? "#AAFFAA" : "#FFAAAA", // verde / rosso
          );
        }

        // ⭐ Percentuale (ultima colonna)
        if (col == row.length - 1) {
          cell.cellStyle = CellStyle(
            backgroundColorHex: percentualeNum >= 70 ? "#AAFFAA" : "#FFAAAA",
          );
        }
      }
    }

    // ⭐ SALVA FILE
    final bytes = excel.encode();
    if (bytes == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final filePath =
        "${directory.path}/registro_${DateTime.now().millisecondsSinceEpoch}.xlsx";

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    // ⭐ CONDIVIDI
    await condividiFileNativo(filePath);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Registro esportato"),
        backgroundColor: Colors.greenAccent,
      ),
    );
  }


  // -------------------------------------------------------------
  // ⭐ RESET REGISTRO
  // -------------------------------------------------------------
  void _showResetPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text("Resetta registro presenze",
              style: TextStyle(color: Colors.white)),
          content: const Text(
            "Questa operazione cancellerà tutto.\nAzione irreversibile.",
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
                  "presenze": {},
                  "presenze_temp": {}
                });

                await FirebaseFirestore.instance
                    .collection("corsi")
                    .doc(corsoId)
                    .update({"studenti": []});

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Registro resettato"),
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

  // -------------------------------------------------------------
  // ⭐ CONFERMA PRESENZE LEZIONE
  // -------------------------------------------------------------
  Future<void> _confermaSingolaLezione(
      BuildContext context,
      String lezioneId,
      Map<String, Map<String, Map<String, dynamic>>> presenzeTemp,
      ) async {
    final registroRef =
    FirebaseFirestore.instance.collection("registro_presenze").doc(corsoId);

    final studentiTemp = presenzeTemp[lezioneId];
    if (studentiTemp == null) return;

    for (var entry in studentiTemp.entries) {
      final uidStudente = entry.key;
      final presente = entry.value["presente"] == 1;

      await registroRef.update({
        "presenze.$uidStudente.$lezioneId": presente ? 1 : 0,
      });
    }

    await registroRef.update({
      "presenze_temp.$lezioneId": FieldValue.delete(),
    });

    final doc = await registroRef.get();
    final lezioni = List<Map<String, dynamic>>.from(doc["lezioni"]);

    final nuoveLezioni = lezioni.map((lez) {
      if (lez["lezioneId"] == lezioneId) {
        return {...lez, "confermata": true};
      }
      return lez;
    }).toList();

    await registroRef.update({"lezioni": nuoveLezioni});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Presenze confermate"),
        backgroundColor: Colors.greenAccent,
      ),
    );
  }

  // -------------------------------------------------------------
  // ⭐ MOSTRA PRESENZE LEZIONE
  // -------------------------------------------------------------
  void _mostraPresenzeLezione(
      BuildContext context,
      String lezioneId,
      Map<String, Map<String, Map<String, dynamic>>> presenzeTemp,
      List<Map<String, dynamic>> studenti,
      Map<String, dynamic> presenzeUfficiali,
      ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text("Presenze della lezione",
              style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: studenti.length,
              itemBuilder: (context, index) {
                final stud = studenti[index];
                final uid = stud["uid"];
                final nome = stud["nome"];
                final cognome = stud["cognome"];

                final presenzaUff = presenzeUfficiali[uid]?[lezioneId];
                final presenzaTempStud =
                presenzeTemp[lezioneId]?[uid]?["presente"];

                final presenza = presenzaTempStud ?? presenzaUff ?? 0;

                Icon icona = presenza == 1
                    ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                    : const Icon(Icons.cancel, color: Colors.redAccent);

                return ListTile(
                  title: Text("$nome $cognome",
                      style: const TextStyle(color: Colors.white)),
                  trailing: icona,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Chiudi", style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------
  // ⭐ TABELLA MODERNA CON + / – / CONFERMA / VISUALIZZA
  // -------------------------------------------------------------
  Widget _buildModernTable(
      BuildContext context,
      List<Map<String, dynamic>> studenti,
      List<Map<String, dynamic>> lezioni,
      Map<String, dynamic> presenze,
      Map<String, Map<String, Map<String, dynamic>>> presenzeTemp,
      ) {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(Colors.indigoAccent),
      dataRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.05)),
      columns: [
        const DataColumn(
          label: Text("Studente",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),

        ...lezioni.map(
              (lez) => DataColumn(
            label: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${lez["data"]}",
                        style: const TextStyle(color: Colors.white)),
                    Text(lez["tipo"],
                        style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),

                const SizedBox(width: 6),

                // ⭐ CONFERMA LEZIONE
                IconButton(
                  icon: Icon(
                    Icons.check_circle,
                    color: lez["confermata"] == true
                        ? Colors.grey
                        : Colors.greenAccent,
                  ),
                  onPressed: lez["confermata"] == true
                      ? null
                      : () async {
                    await _confermaSingolaLezione(
                        context, lez["lezioneId"], presenzeTemp);
                  },
                ),

                // ⭐ VISUALIZZA PRESENZE
                IconButton(
                  icon: const Icon(Icons.remove_red_eye,
                      color: Colors.lightBlueAccent),
                  onPressed: () {
                    _mostraPresenzeLezione(
                      context,
                      lez["lezioneId"],
                      presenzeTemp,
                      studenti,
                      presenze,
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const DataColumn(
          label: Text("Percentuale",
              style: TextStyle(color: Colors.white)),
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

        return DataRow(
          color: WidgetStateProperty.all(
            percentuale >= 70
                ? Colors.green.withOpacity(0.15)
                : Colors.red.withOpacity(0.15),
          ),
          cells: [
            DataCell(Text("$nome $cognome",
                style: const TextStyle(color: Colors.white))),

            ...lezioni.map((lez) {
              final lezId = lez["lezioneId"];
              final valoreTemp = presenzeTemp[lezId]?[uid]?["presente"];
              final valore = valoreTemp ?? (presenze[uid]?[lezId] ?? 0);
              final confermata = lez["confermata"] == true;

              return DataCell(
                Row(
                  children: [
                    Text(
                      valore.toString(),
                      style: TextStyle(
                        color:
                        valore == 1 ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // ⭐ + AGGIUNGI PRESENZA
                    IconButton(
                      icon: const Icon(Icons.add_circle,
                          color: Colors.greenAccent),
                      onPressed: confermata
                          ? null
                          : () async {
                        await FirebaseFirestore.instance
                            .collection("registro_presenze")
                            .doc(corsoId)
                            .update({
                          "presenze_temp.$lezId.$uid.presente": 1,
                        });
                      },
                    ),

                    // ⭐ - RIMUOVI PRESENZA
                    IconButton(
                      icon: const Icon(Icons.remove_circle,
                          color: Colors.redAccent),
                      onPressed: confermata
                          ? null
                          : () async {
                        await FirebaseFirestore.instance
                            .collection("registro_presenze")
                            .doc(corsoId)
                            .update({
                          "presenze_temp.$lezId.$uid.presente": 0,
                        });
                      },
                    ),
                  ],
                ),
              );
            }).toList(),

            DataCell(Text("${percentuale.toStringAsFixed(1)}%",
                style: const TextStyle(color: Colors.white))),
          ],
        );
      }).toList(),
    );
  }

  // -------------------------------------------------------------
  // ⭐ BUILD
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text("Registro presenze"),
        backgroundColor: Colors.indigoAccent,
        centerTitle: true,
      ),

      body: Stack(
        children: [
          StreamBuilder(
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
                  child: Text("Nessun registro trovato",
                      style: TextStyle(color: Colors.white)),
                );
              }

              final studenti = List<Map<String, dynamic>>.from(data["studenti"]);
              final lezioni = List<Map<String, dynamic>>.from(data["lezioni"]);
              final presenze = Map<String, dynamic>.from(data["presenze"]);
              final presenzeTempRaw = data["presenze_temp"] ?? {};

              final Map<String, Map<String, Map<String, dynamic>>> presenzeTemp =
              {};

              presenzeTempRaw.forEach((lezioneId, studentiMap) {
                final studentiCorretti = <String, Map<String, dynamic>>{};
                (studentiMap as Map).forEach((uidStudente, datiStudente) {
                  studentiCorretti[uidStudente.toString()] =
                  Map<String, dynamic>.from(datiStudente as Map);
                });
                presenzeTemp[lezioneId.toString()] = studentiCorretti;
              });

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
                  const SizedBox(height: 20),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = constraints.maxWidth;

                        // ⭐ Larghezza minima della tabella (double!)
                        final minTableWidth = 300.0 + (lezioni.length * 180.0);

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: minTableWidth < screenWidth ? screenWidth : minTableWidth,
                            ),
                            child: _buildModernTable(
                              context,
                              studenti,
                              lezioni,
                              presenze,
                              presenzeTemp,
                            ),
                          ),
                        );
                      },
                    ),
                  ),


                ],
              );
            },
          ),

          // ⭐ FLOATING BUTTONS
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton.extended(
                  backgroundColor: Colors.indigoAccent,
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text("Scarica", style: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    final snap = await FirebaseFirestore.instance
                        .collection("registro_presenze")
                        .doc(corsoId)
                        .get();

                    final studenti =
                    List<Map<String, dynamic>>.from(snap["studenti"]);
                    final lezioni =
                    List<Map<String, dynamic>>.from(snap["lezioni"]);
                    final presenze =
                    Map<String, dynamic>.from(snap["presenze"]);

                    esportaRegistroExcel(context, studenti, lezioni, presenze);
                  },
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  backgroundColor: Colors.redAccent,
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                  label: const Text("Reset", style: TextStyle(color: Colors.white)),
                  onPressed: () => _showResetPopup(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
