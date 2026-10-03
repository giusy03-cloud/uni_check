import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocenteMostraQRPage extends StatelessWidget {
  final String lezioneId;

  const DocenteMostraQRPage({super.key, required this.lezioneId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text("QR Lezione"),
        backgroundColor: Colors.indigoAccent,
        centerTitle: true,
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("lezioni")
            .doc(lezioneId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final lezione = snapshot.data!.data();
          if (lezione == null) {
            return const Center(
              child: Text("Lezione non trovata", style: TextStyle(color: Colors.white)),
            );
          }

          final token = lezione["qrToken"];
          final scadenza = lezione["qrScadenza"] != null
              ? (lezione["qrScadenza"] as Timestamp).toDate()
              : null;

          if (token == null || scadenza == null) {
            return const Center(
              child: Text(
                "QR non generato",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ⭐ QR vero
                QrImageView(
                  data: token,
                  size: 250,
                  backgroundColor: Colors.white,
                ),

                const SizedBox(height: 20),

                Text(
                  "Token: $token",
                  style: const TextStyle(color: Colors.white),
                ),

                const SizedBox(height: 10),

                Text(
                  "Scade alle: ${scadenza.hour}:${scadenza.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
