import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth.dart';

class CreaLezionePage extends StatefulWidget {
  final String corsoId;
  final String nomeCorso;

  const CreaLezionePage({
    super.key,
    required this.corsoId,
    required this.nomeCorso,
  });

  @override
  State<CreaLezionePage> createState() => _CreaLezionePageState();
}

class _CreaLezionePageState extends State<CreaLezionePage> {
  String tipoLezione = "teoria";
  DateTime? dataLezione;
  TimeOfDay? oraInizio;
  TimeOfDay? oraFine;

  final _formKey = GlobalKey<FormState>();

  Future<void> _selezionaData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => dataLezione = picked);
    }
  }

  Future<void> _selezionaOraInizio() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => oraInizio = picked);
    }
  }

  Future<void> _selezionaOraFine() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => oraFine = picked);
    }
  }

  Future<void> _salvaLezione() async {
    if (dataLezione == null || oraInizio == null || oraFine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compila tutti i campi")),
      );
      return;
    }

    final auth = Auth();
    final docenteUid = auth.currentUser!.uid;

    // ⭐ CREA LEZIONE (senza QR)
    final lezioneRef = await FirebaseFirestore.instance.collection("lezioni").add({
      "corsoId": widget.corsoId,
      "docenteId": docenteUid,
      "tipo": tipoLezione,
      "data": Timestamp.fromDate(dataLezione!),
      "oraInizio": "${oraInizio!.hour}:${oraInizio!.minute}",
      "oraFine": "${oraFine!.hour}:${oraFine!.minute}",
      "creataIl": FieldValue.serverTimestamp(),
    });

    // ⭐ AGGIUNGI LEZIONE COME COLONNA NEL REGISTRO PRESENZE
    await FirebaseFirestore.instance
        .collection("registro_presenze")
        .doc(widget.corsoId)
        .set({
      "lezioni": FieldValue.arrayUnion([
        {
          "lezioneId": lezioneRef.id,
          "data": "${dataLezione!.day}/${dataLezione!.month}/${dataLezione!.year}",
          "tipo": tipoLezione,
        }
      ])
    }, SetOptions(merge: true));


    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Lezione creata con successo")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text("Crea lezione - ${widget.nomeCorso}"),
        backgroundColor: Colors.indigoAccent,
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ⭐ TITOLO
              Text(
                "Crea una nuova lezione",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              // ⭐ TIPO LEZIONE
              const Text(
                "Tipo lezione",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: tipoLezione,
                    dropdownColor: Colors.black.withOpacity(0.4),
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: "teoria", child: Text("Teoria")),
                      DropdownMenuItem(value: "laboratorio", child: Text("Laboratorio")),
                    ],
                    onChanged: (value) => setState(() => tipoLezione = value!),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ⭐ DATA LEZIONE
              _modernButton(
                icon: Icons.calendar_month,
                text: dataLezione == null
                    ? "Seleziona data"
                    : "Data: ${dataLezione!.day}/${dataLezione!.month}/${dataLezione!.year}",
                onTap: _selezionaData,
              ),

              const SizedBox(height: 20),

              // ⭐ ORA INIZIO
              _modernButton(
                icon: Icons.access_time,
                text: oraInizio == null
                    ? "Seleziona ora inizio"
                    : "Ora inizio: ${oraInizio!.hour}:${oraInizio!.minute}",
                onTap: _selezionaOraInizio,
              ),

              const SizedBox(height: 20),

              // ⭐ ORA FINE
              _modernButton(
                icon: Icons.access_time_filled,
                text: oraFine == null
                    ? "Seleziona ora fine"
                    : "Ora fine: ${oraFine!.hour}:${oraFine!.minute}",
                onTap: _selezionaOraFine,
              ),

              const SizedBox(height: 40),

              // ⭐ CREA LEZIONE
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    "Crea lezione",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _salvaLezione,
                ),
              ),
            ],
          ),
        ),
      ),


    );
  }
}

Widget _modernButton({
  required IconData icon,
  required String text,
  required VoidCallback onTap,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
    ),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigoAccent.withOpacity(0.9),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: onTap,
      child: Row(
        children: [
          Icon(icon, size: 26, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
