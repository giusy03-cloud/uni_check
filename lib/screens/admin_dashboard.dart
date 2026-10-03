import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.indigoAccent,
        elevation: 0,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            //SEZIONE DOCENTI IN ATTESA
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 20, bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.hourglass_bottom, color: Colors.indigoAccent),
                  SizedBox(width: 10),
                  Text(
                    "Docenti in attesa",
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  ),
                ],
              ),
            ),

            _buildSection(
              query: FirebaseFirestore.instance
                  .collection("utenti")
                  .where("ruolo", isEqualTo: "pending_docente")
                  .snapshots(),
              emptyMessage: "Nessun docente in attesa.",
              cardColor: Colors.white.withOpacity(0.1),
              icon: Icons.person,
              iconColor: Colors.white,
              approveAction: (id) {
                FirebaseFirestore.instance.collection("utenti").doc(id).update({
                  "ruolo": "docente",
                  "approved": true,
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Docente approvato!"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              rejectAction: (id) {
                FirebaseFirestore.instance.collection("utenti").doc(id).update({
                  "ruolo": "rifiutato",
                  "approved": false,
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Docente rifiutato."),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),

            // SEZIONE DOCENTI RIFIUTATI
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 30, bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.redAccent),
                  SizedBox(width: 10),
                  Text(
                    "Docenti rifiutati",
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  ),
                ],
              ),
            ),

            _buildSection(
              query: FirebaseFirestore.instance
                  .collection("utenti")
                  .where("ruolo", isEqualTo: "rifiutato")
                  .snapshots(),
              emptyMessage: "Nessun docente rifiutato.",
              cardColor: Colors.red.withOpacity(0.15),
              icon: Icons.block,
              iconColor: Colors.redAccent,
              approveAction: null, // nessuna azione
              rejectAction: null,  // nessuna azione
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET SEZIONE LISTA
  Widget _buildSection({
    required Stream<QuerySnapshot> query,
    required String emptyMessage,
    required Color cardColor,
    required IconData icon,
    required Color iconColor,
    Function(String id)? approveAction,
    Function(String id)? rejectAction,
  }) {
    return StreamBuilder(
      stream: query,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              emptyMessage,
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final email = data["email"] ?? "Email mancante";

            return Card(
              color: cardColor,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(icon, color: iconColor),
                title: Text(
                  email,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),

                trailing: approveAction != null
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check,
                          color: Colors.greenAccent),
                      onPressed: () => approveAction(docs[index].id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.redAccent),
                      onPressed: () => rejectAction!(docs[index].id),
                    ),
                  ],
                )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}
