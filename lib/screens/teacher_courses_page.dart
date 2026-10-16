import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uni_check_neww/screens/studenti_a_rischio_page.dart';
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
    final snap =
    await FirebaseFirestore.instance.collection("utenti").doc(uid).get();
    return snap.data() ?? {};
  }

  // ⭐ Recupera lista dei docenti condivisi (UID → dati)
  Future<List<Map<String, dynamic>>> _getDocentiCondivisi(
      List<dynamic> listaUid) async {
    List<Map<String, dynamic>> lista = [];

    for (var uid in listaUid) {
      final snap =
      await FirebaseFirestore.instance.collection("utenti").doc(uid).get();
      if (snap.exists) lista.add(snap.data()!);
    }

    return lista;
  }

  // ⭐ Popup aggiungi docente con barra di ricerca
  void _showAggiungiDocentePopup(
      BuildContext context,
      String corsoId,
      String docenteProprietarioUid,
      List<dynamic> listaUid,
      String nomeCorso,
      ) {
    String searchText = "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: Text(
                "Aggiungi docente a $nomeCorso",
                style: const TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ⭐ BARRA DI RICERCA
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Cerca per nome, cognome o email",
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon:
                        const Icon(Icons.search, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => searchText = value.toLowerCase().trim());
                      },
                    ),

                    const SizedBox(height: 20),

                    // ⭐ LISTA DOCENTI
                    Expanded(
                      child: StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection("utenti")
                            .where("ruolo", isEqualTo: "docente")
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            );
                          }

                          final docenti = snapshot.data!.docs;

                          // ⭐ Filtra: niente proprietario, niente già aggiunti
                          var filtrati = docenti.where((d) {
                            final uid = d.id;
                            return uid != docenteProprietarioUid &&
                                !listaUid.contains(uid);
                          }).toList();

                          // ⭐ Filtra per ricerca
                          if (searchText.isNotEmpty) {
                            filtrati = filtrati.where((d) {
                              final data = d.data();
                              final nome =
                              (data["nome"] ?? "").toLowerCase();
                              final cognome =
                              (data["cognome"] ?? "").toLowerCase();
                              final email =
                              (data["email"] ?? "").toLowerCase();

                              return nome.contains(searchText) ||
                                  cognome.contains(searchText) ||
                                  email.contains(searchText);
                            }).toList();
                          }

                          if (filtrati.isEmpty) {
                            return const Text(
                              "Nessun docente trovato.",
                              style: TextStyle(color: Colors.white70),
                            );
                          }

                          return ListView.builder(
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
                                  style:
                                  const TextStyle(color: Colors.white70),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_circle,
                                      color: Colors.tealAccent),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection("corsi")
                                        .doc(corsoId)
                                        .update({
                                      "docentiCondivisi":
                                      FieldValue.arrayUnion([uid])
                                    });

                                    Navigator.pop(context);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            "Docente aggiunto: ${d["nome"]} ${d["cognome"]}"),
                                        backgroundColor:
                                        Colors.tealAccent.shade700,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Chiudi",
                      style: TextStyle(color: Colors.white)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ⭐ Mini dashboard del corso
  void _showDashboardCorso(
      BuildContext context,
      String corsoId,
      String nomeCorso,
      List<dynamic> listaUid,
      bool isCondiviso,
      String uidDocente,
      int lezioniEffettuate,
      int lezioniTotali,
      ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Text(
            nomeCorso,
            style: const TextStyle(color: Colors.white, fontSize: 22),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _miniBtn(
                  icon: Icons.group,
                  text: "Iscritti",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentiIscrittiPage(
                          corsoId: corsoId,
                          nomeCorso: nomeCorso,
                        ),
                      ),
                    );
                  },
                ),
                _miniBtn(
                  icon: Icons.add_circle,
                  text: "Crea lezione",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreaLezionePage(
                          corsoId: corsoId,
                          nomeCorso: nomeCorso,
                        ),
                      ),
                    );
                  },
                ),
                _miniBtn(
                  icon: Icons.event,
                  text: "Lezioni",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LezioniCorsoPage(
                          corsoId: corsoId,
                          nomeCorso: nomeCorso,
                        ),
                      ),
                    );
                  },
                ),
                _miniBtn(
                  icon: Icons.fact_check,
                  text: "Registro",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DocenteRegistroPresenzePage(
                          corsoId: corsoId,
                        ),
                      ),
                    );
                  },
                ),
                _miniBtn(
                  icon: Icons.person_add,
                  text: "Aggiungi docente",
                  onTap: () {
                    _showAggiungiDocentePopup(
                      context,
                      corsoId,
                      uidDocente,
                      listaUid,
                      nomeCorso,
                    );
                  },
                ),
                _miniBtn(
                  icon: Icons.school,
                  text: "Docenti aggiunti",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DocentiAggiuntiPage(
                          corsoId: corsoId,
                          nomeCorso: nomeCorso,
                          listaUid: listaUid,
                        ),
                      ),
                    );
                  },
                ),
                if (lezioniEffettuate >= (lezioniTotali / 2))
                  _miniBtn(
                    icon: Icons.warning_amber_rounded,
                    text: "Studenti a rischio",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentiARischioPage(
                            corsoId: corsoId,
                            nomeCorso: nomeCorso,
                          ),
                        ),
                      );
                    },
                  ),

              ],
            ),
          ),
          actions: [
            TextButton(
              child:
              const Text("Chiudi", style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Auth();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Errore autenticazione")),
      );
    }

    final uid = user.uid;

    final streamProprietario = FirebaseFirestore.instance
        .collection("corsi")
        .where("docenteUid", isEqualTo: uid)
        .snapshots();

    final streamCondivisi = FirebaseFirestore.instance
        .collection("corsi")
        .where("docentiCondivisi", arrayContains: uid)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        title: const Text("I miei corsi"),

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
                        final List<dynamic> listaUid =
                            corso["docentiCondivisi"] ?? [];

                        return StreamBuilder(
                          stream: FirebaseFirestore.instance
                              .collection("lezioni")
                              .where("corsoId", isEqualTo: doc.id)
                              .snapshots(),
                          builder: (context, snapLezioni) {
                            if (!snapLezioni.hasData) {
                              return const SizedBox();
                            }

                            final lezioniEffettuate = snapLezioni.data!.docs.where((doc) {
                              final l = doc.data() as Map<String, dynamic>;
                              return l["codice"] != null; // ⭐ Lezione avviata
                            }).length;

                            final lezioniTotali =
                            corso["numeroLezioniTotali"];
                            final lezioniRimanenti =
                                lezioniTotali - lezioniEffettuate;

                            // ⭐ STATO CORSO
                            String statoCorso;
                            Color coloreStato;

                            if (lezioniEffettuate == 0) {
                              statoCorso = "Non iniziato";
                              coloreStato = Colors.redAccent;
                            } else if (lezioniEffettuate < lezioniTotali) {
                              statoCorso = "In corso";
                              coloreStato = Colors.yellowAccent;
                            } else {
                              statoCorso = "Completato";
                              coloreStato = Colors.greenAccent;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ⭐ HEADER: titolo + cestino
                                  Row(
                                    children: [
                                      const Icon(Icons.book,
                                          color: Colors.indigoAccent,
                                          size: 32),
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
                                      if (!isCondiviso)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_forever,
                                            color: Colors.redAccent,
                                            size: 30,
                                          ),
                                          onPressed: () {
                                            // TODO: conferma eliminazione corso
                                          },
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 15),

                                  // ⭐ INFO CORSO
                                  Text(
                                    "Anno accademico: ${corso["annoAccademico"]}\n"
                                        "CFU: ${corso["cfu"]}\n"
                                        "Lezioni totali: $lezioniTotali\n"
                                        "Lezioni effettuate: $lezioniEffettuate\n"
                                        "Lezioni rimanenti: $lezioniRimanenti",
                                    style: const TextStyle(
                                        color: Colors.white70),
                                  ),

                                  const SizedBox(height: 10),

                                  // ⭐ STATO CORSO
                                  Row(
                                    children: [
                                      Icon(Icons.circle,
                                          color: coloreStato, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        statoCorso,
                                        style: TextStyle(
                                          color: coloreStato,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // ⭐ PULSANTE APRI
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: ElevatedButton.icon(
                                      icon: Icon(Icons.open_in_new,
                                          color: Theme.of(context).colorScheme.onPrimary),
                                      label: Text(
                                        "Apri",
                                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigoAccent,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () {
                                        _showDashboardCorso(
                                          context,
                                          doc.id,
                                          corso["nome"],
                                          listaUid,
                                          isCondiviso,
                                          uid,
                                          lezioniEffettuate,
                                          lezioniTotali,
                                        );
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  if (isCondiviso)
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.remove_circle,
                                          color: Colors.white),
                                      label: const Text(
                                        "Rimuovimi dal corso",
                                        style:
                                        TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orangeAccent,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection("corsi")
                                            .doc(doc.id)
                                            .update({
                                          "docentiCondivisi":
                                          FieldValue.arrayRemove([uid])
                                        });

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                "Sei stato rimosso dal corso"),
                                            backgroundColor:
                                            Colors.orangeAccent,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget _miniBtn({
  required IconData icon,
  required String text,
  required VoidCallback onTap,
}) {
  return SizedBox(
    width: 140,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigoAccent,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    ),
  );
}
