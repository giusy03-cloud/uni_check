import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth.dart';

class NotificheStudentePage extends StatelessWidget {
  const NotificheStudentePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Auth();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),

      appBar: AppBar(
        title: const Text("Notifiche"),
        backgroundColor: Colors.indigoAccent,
        centerTitle: true,
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("notifiche")
            .where("uidDestinatario", isEqualTo: user!.uid)
            .orderBy("timestamp", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final notifiche = snapshot.data!.docs;

          if (notifiche.isEmpty) {
            return const Center(
              child: Text(
                "Nessuna notifica.",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifiche.length,
            itemBuilder: (context, index) {
              final doc = notifiche[index];
              final n = doc.data() as Map<String, dynamic>;

              final bool isLetta = n["letto"] == true;

              return GestureDetector(
                onTap: () async {
                  if (!isLetta) {
                    await FirebaseFirestore.instance
                        .collection("notifiche")
                        .doc(doc.id)
                        .update({"letto": true});
                  }
                },

                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: isLetta
                        ? Colors.white.withOpacity(0.08)
                        : Colors.indigoAccent.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLetta
                          ? Colors.white.withOpacity(0.2)
                          : Colors.indigoAccent.withOpacity(0.6),
                    ),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ⭐ ICONA + TITOLO
                      Row(
                        children: [
                          Icon(
                            isLetta
                                ? Icons.notifications_none
                                : Icons.notifications_active,
                            color: Colors.white,
                            size: 30,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              n["titolo"],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: isLetta
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ⭐ MESSAGGIO
                      Text(
                        n["messaggio"],
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: isLetta
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ⭐ FOOTER: DATA + ELIMINA
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTimestamp(n["timestamp"]),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                          ),

                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection("notifiche")
                                  .doc(doc.id)
                                  .delete();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Notifica eliminata"),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
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

String _formatTimestamp(Timestamp? ts) {
  if (ts == null) return "";
  final date = ts.toDate();
  return "${date.day}/${date.month}/${date.year} "
      "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
}
