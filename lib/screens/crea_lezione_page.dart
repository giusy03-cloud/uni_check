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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compila tutti i campi")),
      );
      return;
    }

    final auth = Auth();
    final docenteUid = auth.currentUser!.uid;

    await FirebaseFirestore.instance.collection("lezioni").add({
      "corsoId": widget.corsoId,
      "docenteId": docenteUid,
      "tipo": tipoLezione,
      "data": Timestamp.fromDate(dataLezione!),
      "oraInizio": "${oraInizio!.hour}:${oraInizio!.minute}",
      "oraFine": "${oraFine!.hour}:${oraFine!.minute}",
      "creataIl": FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Lezione creata con successo")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text("Crea lezione - ${widget.nomeCorso}"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                "Crea una nuova lezione",
                style: theme.textTheme.titleLarge,
              ),

              const SizedBox(height: 30),

              Text("Tipo lezione", style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: tipoLezione,
                    dropdownColor: theme.colorScheme.surface,
                    iconEnabledColor: theme.colorScheme.onSurface,
                    style: theme.textTheme.bodyMedium,
                    items: const [
                      DropdownMenuItem(value: "teoria", child: Text("Teoria")),
                      DropdownMenuItem(value: "laboratorio", child: Text("Laboratorio")),
                    ],
                    onChanged: (value) => setState(() => tipoLezione = value!),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ⭐ SECONDARIO — FilledButton
              FilledButton(
                onPressed: _selezionaData,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dataLezione == null
                            ? "Seleziona data"
                            : "Data: ${dataLezione!.day}/${dataLezione!.month}/${dataLezione!.year}",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              FilledButton(
                onPressed: _selezionaOraInizio,
                child: Row(
                  children: [
                    const Icon(Icons.access_time),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        oraInizio == null
                            ? "Seleziona ora inizio"
                            : "Ora inizio: ${oraInizio!.hour}:${oraInizio!.minute}",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              FilledButton(
                onPressed: _selezionaOraFine,
                child: Row(
                  children: [
                    const Icon(Icons.access_time_filled),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        oraFine == null
                            ? "Seleziona ora fine"
                            : "Ora fine: ${oraFine!.hour}:${oraFine!.minute}",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ⭐ PRIMARIO — ElevatedButton
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: Text(
                    "Crea lezione",
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontSize: 18,
                      color: theme.colorScheme.onPrimary,
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
