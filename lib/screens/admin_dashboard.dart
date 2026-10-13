import 'dart:convert';
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
        centerTitle: true,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ⭐ DOCENTI IN ATTESA
            _sectionTitle(
              icon: Icons.hourglass_bottom,
              text: "Docenti in attesa",
              color: Colors.indigoAccent,
            ),

            _buildSection(
              query: FirebaseFirestore.instance
                  .collection("utenti")
                  .where("ruolo", isEqualTo: "pending_docente")
                  .snapshots(),
              emptyMessage: "Nessun docente in attesa.",
              badgeText: "In attesa",
              badgeColor: Colors.orangeAccent,
              approveAction: (id) {
                FirebaseFirestore.instance.collection("utenti").doc(id).update({
                  "ruolo": "docente",
                  "approved": true,
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Docente approvato!"),
                    backgroundColor: Colors.greenAccent,
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
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
            ),

            // ⭐ DOCENTI RIFIUTATI
            _sectionTitle(
              icon: Icons.block,
              text: "Docenti rifiutati",
              color: Colors.redAccent,
            ),

            _buildSection(
              query: FirebaseFirestore.instance
                  .collection("utenti")
                  .where("ruolo", isEqualTo: "rifiutato")
                  .snapshots(),
              emptyMessage: "Nessun docente rifiutato.",
              badgeText: "Rifiutato",
              badgeColor: Colors.redAccent,
              approveAction: null,
              rejectAction: null,
            ),

            // ⭐ DOCENTI APPROVATI
            _sectionTitle(
              icon: Icons.verified,
              text: "Docenti approvati",
              color: Colors.greenAccent,
            ),

            _buildSection(
              query: FirebaseFirestore.instance
                  .collection("utenti")
                  .where("ruolo", isEqualTo: "docente")
                  .snapshots(),
              emptyMessage: "Nessun docente approvato.",
              badgeText: "Approvato",
              badgeColor: Colors.greenAccent,
              approveAction: null,
              rejectAction: null,
            ),
          ],
        ),
      ),
    );
  }

  // ⭐ TITOLO SEZIONE
  Widget _sectionTitle({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 25, bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ⭐ CARD MODERNA
  Widget _buildSection({
    required Stream<QuerySnapshot> query,
    required String emptyMessage,
    required String badgeText,
    required Color badgeColor,
    Function(String id)? approveAction,
    Function(String id)? rejectAction,
  }) {
    return StreamBuilder(
      stream: query,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              emptyMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            final nome = data["nome"] ?? "";
            final cognome = data["cognome"] ?? "";
            final email = data["email"] ?? "Email mancante";
            final base64Image = data["imageBase64"];

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),

              child: Row(
                children: [

                  // ⭐ FOTO PROFILO
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: base64Image != null
                        ? MemoryImage(base64Decode(base64Image))
                        : null,
                    backgroundColor: Colors.indigoAccent.withOpacity(0.3),
                    child: base64Image == null
                        ? const Icon(Icons.person, color: Colors.white, size: 32)
                        : null,
                  ),

                  const SizedBox(width: 15),

                  // ⭐ INFO DOCENTE
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$nome $cognome",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ⭐ BADGE STATO
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 12),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ⭐ BOTTONI APPROVA / RIFIUTA
                  if (approveAction != null)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: Colors.greenAccent, size: 32),
                          onPressed: () => approveAction(docs[index].id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel,
                              color: Colors.redAccent, size: 32),
                          onPressed: () => rejectAction!(docs[index].id),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
