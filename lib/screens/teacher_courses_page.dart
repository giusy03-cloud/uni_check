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
                        final List<dynamic> listaUid = corso["docentiCondivisi"] ?? [];

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
                                  const Icon(Icons.book, color: Colors.indigoAccent, size: 32),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      corso["nome"],
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

                              // ⭐ BADGE CONDIVISIONE
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

                                      if (!isCondiviso && condivisiList.isNotEmpty) {
                                        final nomi = condivisiList
                                            .map((d) => "${d["nome"]} ${d["cognome"]}")
                                            .join(", ");
                                        badgeText = "Condiviso con:\n$nomi";
                                      } else if (isCondiviso) {
                                        badgeText =
                                        "Aggiunto da:\n$nomeProprietario $cognomeProprietario";
                                      }

                                      return badgeText.isEmpty
                                          ? const SizedBox()
                                          : Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.indigoAccent.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          badgeText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),

                              const SizedBox(height: 15),

                              // ⭐ INFO CORSO
                              Text(
                                "Anno accademico: ${corso["annoAccademico"]}\n"
                                    "CFU: ${corso["cfu"]}\n"
                                    "Lezioni totali: ${corso["numeroLezioniTotali"]}",
                                style: const TextStyle(color: Colors.white70),
                              ),

                              const SizedBox(height: 20),

                              // ⭐ PULSANTI MODERNI
                              _btn(
                                icon: Icons.group,
                                text: "Studenti iscritti",
                                onTap: () {
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

                              const SizedBox(height: 10),

                              _btn(
                                icon: Icons.add_circle,
                                text: "Crea lezione",
                                onTap: () {
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

                              const SizedBox(height: 10),

                              _btn(
                                icon: Icons.event,
                                text: "Lezioni del corso",
                                onTap: () {
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

                              const SizedBox(height: 10),

                              _btn(
                                icon: Icons.fact_check,
                                text: "Registro presenze",
                                onTap: () {
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

                              const SizedBox(height: 10),

                              _btn(
                                icon: Icons.school,
                                text: "Docenti aggiunti",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DocentiAggiuntiPage(
                                        corsoId: doc.id,
                                        nomeCorso: corso["nome"],
                                        listaUid: listaUid,
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 10),

                              _btn(
                                icon: Icons.person_add,
                                text: "Aggiungi docente",
                                onTap: () {
                                  _showAggiungiDocentePopup(
                                    context,
                                    doc.id,
                                    corso["docenteUid"],
                                    listaUid,
                                    corso["nome"],
                                  );
                                },
                              ),

                              const SizedBox(height: 10),

                              if (!isCondiviso)
                                _btnRed(
                                  icon: Icons.delete,
                                  text: "Elimina corso",
                                  onTap: () {
                                    // conferma eliminazione (rimane uguale)
                                  },
                                ),

                              if (isCondiviso)
                                _btn(
                                  icon: Icons.remove_circle,
                                  text: "Rimuovimi dal corso",
                                  onTap: () async {
                                    await FirebaseFirestore.instance
                                        .collection("corsi")
                                        .doc(doc.id)
                                        .update({
                                      "docentiCondivisi": FieldValue.arrayRemove([uid])
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Sei stato rimosso dal corso"),
                                        backgroundColor: Colors.orangeAccent,
                                      ),
                                    );
                                  },
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
          ),
        ],
      ),
    );
  }
}

Widget _btn({required IconData icon, required String text, required VoidCallback onTap}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(text, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigoAccent,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
    ),
  );
}

Widget _btnRed({required IconData icon, required String text, required VoidCallback onTap}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(text, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
    ),
  );
}
