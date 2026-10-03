import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth.dart';

class CreateCoursePage extends StatefulWidget {
  const CreateCoursePage({super.key});

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _cfuController = TextEditingController();
  final TextEditingController _annoCorsoController = TextEditingController();
  final TextEditingController _numeroLezioniController = TextEditingController();

  String annoAccademico = "2026/2027";

  bool teoria = false;
  bool laboratorio = false;

  bool isLoading = false;

  Future<void> createCourse() async {
    final auth = Auth();
    final user = auth.currentUser;

    if (user == null) return;

    final nome = _courseNameController.text.trim();
    final cfu = int.tryParse(_cfuController.text.trim());
    final annoCorso = int.tryParse(_annoCorsoController.text.trim());
    final numeroLezioniTotali = int.tryParse(_numeroLezioniController.text.trim());

    if (nome.isEmpty || cfu == null || annoCorso == null || numeroLezioniTotali == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compila tutti i campi obbligatori.")),
      );
      return;
    }

    setState(() => isLoading = true);

    await FirebaseFirestore.instance.collection("corsi").add({
      "nome": nome,
      "annoAccademico": annoAccademico,
      "annoCorso": annoCorso,
      "cfu": cfu,
      "numeroLezioniTotali": numeroLezioniTotali,

      // ⭐ CAMPI FONDAMENTALI
      "docenteUid": user.uid,
      "docenteEmail": user.email,

      "studenti": [],
      "createdAt": DateTime.now(),
    });

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Corso creato con successo!")),
    );

    Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),

      appBar: AppBar(
        title: const Text("Crea Corso"),
        backgroundColor: Colors.indigoAccent,
        elevation: 0,
        centerTitle: true,
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    _buildInput("Nome del corso", _courseNameController),
                    const SizedBox(height: 20),

                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: annoAccademico,
                        dropdownColor: Colors.black.withOpacity(0.4),
                        iconEnabledColor: Colors.white,
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: "2025/2026", child: Text("2025/2026")),
                          DropdownMenuItem(value: "2026/2027", child: Text("2026/2027")),
                          DropdownMenuItem(value: "2027/2028", child: Text("2027/2028")),
                        ],
                        onChanged: (value) => setState(() => annoAccademico = value!),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildInput("Anno di corso (es. 1)", _annoCorsoController),
                    const SizedBox(height: 20),

                    _buildInput("CFU", _cfuController),
                    const SizedBox(height: 20),

                    _buildInput("Numero lezioni totali nel trimestre", _numeroLezioniController),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: isLoading ? null : createCourse,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        "Crea Corso",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String hint, TextEditingController controller, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}
