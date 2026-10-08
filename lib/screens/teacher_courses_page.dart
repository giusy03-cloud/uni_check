import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth.dart';
import 'docenti_aggiunti_page.dart';
import 'studenti_iscritti_page.dart';
import 'crea_lezione_page.dart';
import 'lezioni_corso_page.dart';
import 'docente_registro_presenze_page.dart';

class TeacherCoursesPage extends StatelessWidget {
  const TeacherCoursesPage({super.key});

  // ⭐ Recupera nome e cognome del docente proprietario
  Future<Map<String, dynamic>> _getDocente(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection("utenti")
        .doc(uid)
        .get();

    return snap.data() ?? {};
  }

  // ⭐ Recupera lista dei docenti condivisi (UID → dati)
  Future<List<Map<String, dynamic>>> _getDocentiCondivisi(List<dynamic> listaUid) async {
    List<Map<String, dynamic>> lista = [];

    for (var uid in listaUid) {
      final snap = await FirebaseFirestore.instance
          .collection("utenti")
          .doc(uid)
          .get();

      if (snap.exists) {
        lista.add(snap.data()!);
      }
    }

    return lista;
  }

  void _showAggiungiDocentePopup(
      BuildContext context,
      String corsoId,
      String docenteProprietarioUid,
      List<dynamic> listaUid,
      String nomeCorso,
      ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Text(
            "Aggiungi docente a $nomeCorso",
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("utenti")
                  .where("ruolo", isEqualTo: "docente")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                final docenti = snapshot.data!.docs;

                // ⭐ Filtra: niente proprietario, niente già aggiunti
                final filtrati = docenti.where((d) {
                  final uid = d.id;
                  return uid != docenteProprietarioUid && !listaUid.contains(uid);
                }).toList();

                if (filtrati.isEmpty) {
                  return const Text(
                    "Nessun docente disponibile.",
                    style: TextStyle(color: Colors.white70),
                  );
                }

                return SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: filtrati.length,
                    itemBuilder: (context, index) {
                      final d = filtrati[index].data();
                      final uid = filtrati[index].id;

                      return ListTile(
                        title: Text(
                          "${d["nome"]} ${d["cognome"]}",
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          d["email"],
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.tealAccent),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection("corsi")
                                .doc(corsoId)
                                .update({
                              "docentiCondivisi": FieldValue.arrayUnion([uid])
                            });

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Docente aggiunto: ${d["nome"]} ${d["cognome"]}"),
                                backgroundColor: Colors.tealAccent.shade700,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
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


  @override
  Widget build(BuildContext context) {
    final auth = Auth();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Errore autenticazione")),
      );
    }

    final uid = user.uid;

    // ⭐ Query 1: corsi creati da me
    final streamProprietario = FirebaseFirestore.instance
        .collection("corsi")
        .where("docenteUid", isEqualTo: uid)
        .snapshots();

    // ⭐ Query 2: corsi dove sono docente condiviso
    final streamCondivisi = FirebaseFirestore.instance
        .collection("corsi")
        .where("docentiCondivisi", arrayContains: uid)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text("I miei corsi"),
        backgroundColor: Colors.indigoAccent,
        centerTitle: true,
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: streamProprietario,
              builder: (context, snapshot1) {
                return StreamBuilder(
                  stream: streamCondivisi,
                  builder: (context, snapshot2) {
                    if (!snapshot1.hasData || !snapshot2.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    final proprietario = snapshot1.data!.docs;
                    final condivisi = snapshot2.data!.docs;

                    // ⭐ Unisci corsi
                    final corsi = [...proprietario, ...condivisi];

                    if (corsi.isEmpty) {
                      return const Center(
                        child: Text(
                          "Non hai corsi.",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: corsi.length,
                      itemBuilder: (context, index) {
                        final doc = corsi[index];
                        final corso = doc.data();

                        final bool isCondiviso = corso["docenteUid"] != uid;

                        // ⭐ docentiCondivisi è una LISTA DI UID
                        final List<dynamic> listaUid = corso["docentiCondivisi"] ?? [];

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

                                // ⭐ TITOLO + INFO PROPRIETARIO / CONDIVISI
                                FutureBuilder(
                                  future: _getDocente(corso["docenteUid"]),
                                  builder: (context, snapProprietario) {
                                    final proprietario = snapProprietario.data ?? {};
                                    final nomeProprietario = proprietario["nome"] ?? "";
                                    final cognomeProprietario = proprietario["cognome"] ?? "";

                                    return FutureBuilder(
                                      future: _getDocentiCondivisi(listaUid),
                                      builder: (context, snapCondivisi) {
                                        final condivisiList = snapCondivisi.data ?? [];

                                        String badgeText = "";

                                        // ⭐ Se sei proprietario → mostra "Condiviso con: ..."
                                        if (corso["docenteUid"] == uid) {
                                          if (condivisiList.isNotEmpty) {
                                            final nomi = condivisiList
                                                .map((d) => "${d["nome"]} ${d["cognome"]}")
                                                .join(", ");

                                            badgeText = "Condiviso con:\n$nomi";
                                          }
                                        }

                                        // ⭐ Se sei condiviso → mostra "Aggiunto da: ..."
                                        else {
                                          badgeText =
                                          "Condiviso\nAggiunto da:\n$nomeProprietario $cognomeProprietario";
                                        }

                                        return Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                corso["nome"],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),

                                            if (badgeText.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.orangeAccent,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  badgeText,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),

                                const SizedBox(height: 10),

                                Text(
                                  "Anno accademico: ${corso["annoAccademico"]}\n"
                                      "CFU: ${corso["cfu"]}\n"
                                      "Lezioni totali: ${corso["numeroLezioniTotali"]}",
                                  style: const TextStyle(color: Colors.white70),
                                ),

                                const SizedBox(height: 12),

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigoAccent,
                                  ),
                                  child: const Text("Studenti iscritti", style: TextStyle(color: Colors.white)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StudentiIscrittiPage(
                                          corsoId: doc.id,
                                          nomeCorso: corso["nome"],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 8),

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.greenAccent.shade700,
                                  ),
                                  child: const Text("Crea lezione", style: TextStyle(color: Colors.white)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CreaLezionePage(
                                          corsoId: doc.id,
                                          nomeCorso: corso["nome"],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 8),

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                  ),
                                  child: const Text("Lezioni del corso", style: TextStyle(color: Colors.white)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => LezioniCorsoPage(
                                          corsoId: doc.id,
                                          nomeCorso: corso["nome"],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 8),

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orangeAccent,
                                  ),
                                  child: const Text("Registro presenze", style: TextStyle(color: Colors.white)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DocenteRegistroPresenzePage(
                                          corsoId: doc.id,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purpleAccent,
                                  ),
                                  child: const Text("Docenti aggiunti", style: TextStyle(color: Colors.white)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DocentiAggiuntiPage(
                                          corsoId: doc.id,
                                          nomeCorso: corso["nome"],
                                          listaUid: listaUid, // gli UID dei docenti condivisi
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.tealAccent.shade700,
                                  ),
                                  child: const Text("+ Aggiungi docente", style: TextStyle(color: Colors.white)),
                                  onPressed: () {
                                    _showAggiungiDocentePopup(
                                      context,
                                      doc.id,
                                      corso["docenteUid"],
                                      listaUid,
                                      corso["nome"],
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
