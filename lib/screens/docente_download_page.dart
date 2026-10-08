import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class DocenteDownloadPage extends StatelessWidget {
  final String docenteUid;

  const DocenteDownloadPage({super.key, required this.docenteUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text("Download"),
        backgroundColor: Colors.indigoAccent,
        centerTitle: true,
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("download_registri")
            .where("docenteUid", isEqualTo: docenteUid)
            .orderBy("timestamp", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("Nessun file scaricato",
                  style: TextStyle(color: Colors.white)),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index].data();

              return ListTile(
                title: Text(
                  d["nomeFile"],
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  d["annoAccademico"],
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    await docs[index].reference.delete();
                  },
                ),
                onTap: () {
                  launchUrl(Uri.parse(d["fileUrl"]));
                },
              );
            },
          );
        },
      ),
    );
  }
}
