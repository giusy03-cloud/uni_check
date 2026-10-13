import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentPresenzaPage extends StatefulWidget {
  final String lezioneId;
  final String nomeLezione;

  const StudentPresenzaPage({
    super.key,
    required this.lezioneId,
    required this.nomeLezione,
  });

  @override
  State<StudentPresenzaPage> createState() => _StudentPresenzaPageState();
}

class _StudentPresenzaPageState extends State<StudentPresenzaPage> {
  final codiceController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final uidStudente = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text("Presenza - ${widget.nomeLezione}"),
        backgroundColor: Colors.indigoAccent,
        centerTitle: true,
      ),

      body: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection("presenze")
            .where("lezioneId", isEqualTo: widget.lezioneId)
            .where("studenteId", isEqualTo: uidStudente)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final presenzaGiaRegistrata = snapshot.data!.docs.isNotEmpty;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // ⭐ ICONA + TITOLO
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_user,
                        color: Colors.indigoAccent, size: 40),
                    const SizedBox(width: 10),
                    Text(
                      "Presenza - ${widget.nomeLezione}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // ⭐ PRESENZA GIÀ REGISTRATA
                if (presenzaGiaRegistrata) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
                        SizedBox(width: 10),
                        Text(
                          "Presenza già registrata",
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ⭐ SE NON REGISTRATA → INPUT + BOTTONE
                if (!presenzaGiaRegistrata) ...[
                  const Text(
                    "Inserisci il codice di 4 lettere",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: codiceController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Codice",
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.indigoAccent),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        "Invia",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: isLoading ? null : registraPresenza,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),


    );
  }

  Future<void> registraPresenza() async {
    setState(() => isLoading = true);

    final codiceInserito = codiceController.text.trim().toUpperCase();

    if (codiceInserito.isEmpty) {
      errore("Inserisci il codice");
      setState(() => isLoading = false);
      return;
    }

    final uidStudente = FirebaseAuth.instance.currentUser!.uid;

    // ⭐ Controllo doppia presenza
    final presenzaDoc = await FirebaseFirestore.instance
        .collection("presenze")
        .where("lezioneId", isEqualTo: widget.lezioneId)
        .where("studenteId", isEqualTo: uidStudente)
        .get();

    if (presenzaDoc.docs.isNotEmpty) {
      errore("Hai già registrato la presenza");
      setState(() => isLoading = false);
      return;
    }

    // ⭐ Recupero documento lezione
    final doc = await FirebaseFirestore.instance
        .collection("lezioni")
        .doc(widget.lezioneId)
        .get();

    if (!doc.exists) {
      errore("Lezione non trovata");
      setState(() => isLoading = false);
      return;
    }

    final lezione = doc.data()!;
    final codice = lezione["codice"];

    // ⭐ Gestione scadenza
    final scadenzaTS = lezione["codiceScadenza"];
    DateTime? scadenza;

    if (scadenzaTS != null) {
      scadenza = (scadenzaTS as Timestamp).toDate();
    }

    final now = DateTime.now();
    final codiceScaduto = scadenza == null || scadenza.isBefore(now);

    // ⭐ Controlli codice
    if (codice == null) {
      errore("Codice non generato dal docente");
    } else if (codiceScaduto) {
      errore("Codice scaduto");
      await FirebaseFirestore.instance
          .collection("registro_presenze")
          .doc(lezione["corsoId"])
          .update({
        "presenze.${uidStudente}.${widget.lezioneId}": 0,
      });
    } else if (codiceInserito != codice) {
      errore("Codice errato");
    } else {
      // ⭐ CREA PRESENZA
      // ⭐ Recupera dati studente
      final studDoc = await FirebaseFirestore.instance
          .collection("utenti")
          .doc(uidStudente)
          .get();

      final studData = studDoc.data()!;

// ⭐ Salva presenza nella collezione presenze (storico)
      await FirebaseFirestore.instance.collection("presenze").add({
        "lezioneId": widget.lezioneId,
        "studenteId": uidStudente,
        "corsoId": lezione["corsoId"],
        "timestamp": FieldValue.serverTimestamp(),

        // ⭐ Aggiunta richiesta dal prof
        "nome": studData["nome"],
        "cognome": studData["cognome"],
        "email": studData["email"],
      });

      await FirebaseFirestore.instance
          .collection("registro_presenze")
          .doc(lezione["corsoId"])
          .update({
        "presenze.${uidStudente}.${widget.lezioneId}": 1,
      });

      await FirebaseFirestore.instance
          .collection("registro_presenze")
          .doc(lezione["corsoId"])
          .update({
        "presenze_temp.${widget.lezioneId}.${uidStudente}": {
          "uid": uidStudente,
          "nome": studData["nome"],
          "cognome": studData["cognome"],
          "email": studData["email"],
          "presente": 1,
          "timestamp": FieldValue.serverTimestamp(),
        }
      });



      ok("Presenza registrata!");

      await Future.delayed(const Duration(milliseconds: 600));
      Navigator.pop(context);
    }

    setState(() => isLoading = false);
  }

  void errore(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void ok(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }
}
