import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocentiAggiuntiPage extends StatelessWidget {
  final String corsoId;
  final String nomeCorso;
  final List<dynamic> listaUid;

  const DocentiAggiuntiPage({
    super.key,
    required this.corsoId,
    required this.nomeCorso,
    required this.listaUid,
  });

  Future<List<Map<String, dynamic>>> _getDocenti(List<dynamic> uids) async {
    List<Map<String, dynamic>> lista = [];

    for (var uid in uids) {
      final snap = await FirebaseFirestore.instance
          .collection("utenti")
          .doc(uid)
          .get();

      if (snap.exists) {
        lista.add({
          "uid": uid,
          "nome": snap["nome"],
          "cognome": snap["cognome"],
          "email": snap["email"],
        });
      }
    }

    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text("Docenti aggiunti - $nomeCorso"),
        backgroundColor: Colors.purpleAccent,
        centerTitle: true,
      ),

      body: FutureBuilder(
        future: _getDocenti(listaUid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final docenti = snapshot.data!;

          if (docenti.isEmpty) {
            return const Center(
              child: Text(
                "Nessun docente aggiunto.",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docenti.length,
            itemBuilder: (context, index) {
              final d = docenti[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: ListTile(
                  title: Text(
                    "${d["nome"]} ${d["cognome"]}",
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  subtitle: Text(
                    d["email"],
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection("corsi")
                          .doc(corsoId)
                          .update({
                        "docentiCondivisi": FieldValue.arrayRemove([d["uid"]])
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Docente rimosso"),
                          backgroundColor: Colors.redAccent,
                        ),
                      );

                      Navigator.pop(context);
                    },
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
