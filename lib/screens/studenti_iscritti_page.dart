import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth.dart';

class StudentiIscrittiPage extends StatelessWidget {
  final String corsoId;
  final String nomeCorso;

  const StudentiIscrittiPage({
    super.key,
    required this.corsoId,
    required this.nomeCorso,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text("Iscritti - $nomeCorso"),
        backgroundColor: Colors.indigoAccent,
        centerTitle: true,
      ),

      // ⭐ STREAMBUILDER → aggiornamento in tempo reale
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("corsi")
            .doc(corsoId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final corsoData = snapshot.data!.data() as Map<String, dynamic>;
          final studenti = corsoData["studenti"] as List<dynamic>? ?? [];

          if (studenti.isEmpty) {
            return const Center(
              child: Text(
                "Nessuno studente iscritto.",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: studenti.length,
            itemBuilder: (context, index) {
              final uidStudente = studenti[index];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("utenti")
                    .doc(uidStudente)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;

                  final base64Image = userData["imageBase64"];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          backgroundImage: base64Image != null
                              ? MemoryImage(base64Decode(base64Image))
                              : null,
                          child: base64Image == null
                              ? const Icon(Icons.person,
                              color: Colors.white, size: 28)
                              : null,
                        ),

                        title: Text(
                          userData["email"],
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18),
                        ),

                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            // ⭐ FINESTRA DI CONFERMA
                            final conferma = await showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: const Color(0xFF1A1A2E),
                                  title: const Text(
                                    "Conferma eliminazione",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: const Text(
                                    "Sei sicuro di voler eliminare questo studente dal corso?",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text("Annulla",
                                          style: TextStyle(color: Colors.white)),
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                    ),
                                    TextButton(
                                      child: const Text("Elimina",
                                          style: TextStyle(color: Colors.redAccent)),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (conferma == true) {
                              await FirebaseFirestore.instance
                                  .collection("corsi")
                                  .doc(corsoId)
                                  .update({
                                "studenti": FieldValue.arrayRemove([uidStudente])
                              });
                              // ⭐ CREA NOTIFICA PER LO STUDENTE
                              final auth = Auth();
                              final docenteUid = auth.currentUser!.uid;

                              final docenteData = await FirebaseFirestore.instance
                                  .collection("utenti")
                                  .doc(docenteUid)
                                  .get();

                              final docenteEmail = docenteData.data()?["email"] ?? "Docente";

                              await FirebaseFirestore.instance.collection("notifiche").add({
                                "uidDestinatario": uidStudente,
                                "titolo": "Sei stato eliminato dal corso",
                                "messaggio":
                                "Il docente $docenteEmail ti ha eliminato dal corso $nomeCorso",
                                "corsoId": corsoId,
                                "timestamp": FieldValue.serverTimestamp(),
                                "letto": false,
                              });




                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Studente eliminato dal corso"),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
