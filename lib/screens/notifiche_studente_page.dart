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

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
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

                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    title: Text(
                      n["titolo"],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: isLetta ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      n["messaggio"],
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: isLetta ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),

                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
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

                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection("notifiche")
                          .doc(doc.id)
                          .update({"letto": true});

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
