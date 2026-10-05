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
        .update({
      "lezioni": FieldValue.arrayUnion([
        {
          "lezioneId": lezioneRef.id,
          "data": "${dataLezione!.day}/${dataLezione!.month}/${dataLezione!.year}",
          "tipo": tipoLezione,
        }
      ])
    });

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
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Tipo lezione",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField(
                dropdownColor: const Color(0xFF1A1A2E),
                value: tipoLezione,
                items: const [
                  DropdownMenuItem(
                    value: "teoria",
                    child: Text("Teoria", style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: "laboratorio",
                    child: Text("Laboratorio", style: TextStyle(color: Colors.white)),
                  ),
                ],
                onChanged: (value) {
                  setState(() => tipoLezione = value!);
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                ),
                onPressed: _selezionaData,
                child: Text(
                  dataLezione == null
                      ? "Seleziona data"
                      : "Data: ${dataLezione!.day}/${dataLezione!.month}/${dataLezione!.year}",
                  style: const TextStyle(color: Colors.white),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                ),
                onPressed: _selezionaOraInizio,
                child: Text(
                  oraInizio == null
                      ? "Seleziona ora inizio"
                      : "Ora inizio: ${oraInizio!.hour}:${oraInizio!.minute}",
                  style: const TextStyle(color: Colors.white),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                ),
                onPressed: _selezionaOraFine,
                child: Text(
                  oraFine == null
                      ? "Seleziona ora fine"
                      : "Ora fine: ${oraFine!.hour}:${oraFine!.minute}",
                  style: const TextStyle(color: Colors.white),
                ),
              ),

              const Spacer(),

              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.shade700,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 40),
                  ),
                  onPressed: _salvaLezione,
                  child: const Text(
                    "Crea lezione",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
