import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uni_check_neww/screens/login_screen.dart';
import '../auth.dart';
import 'dart:convert';



class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool showPassword = false;
  File? profileImage;

  String selectedRole = "studente"; // DEFAULT
  bool isLoading = false;

  final auth = Auth();

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (picked != null) {
      setState(() => profileImage = File(picked.path));
    }
  }

  String? convertImageToBase64() {
    if (profileImage == null) return null;
    final bytes = profileImage!.readAsBytesSync();
    return base64Encode(bytes);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "CREATE ACCOUNT",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 45,
                        backgroundImage:
                        profileImage != null ? FileImage(profileImage!) : null,
                        backgroundColor: Colors.indigo.withOpacity(0.3),
                        child: profileImage == null
                            ? const Icon(Icons.camera_alt,
                            color: Colors.white70, size: 35)
                            : null,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildTextField(emailController, "Email", Icons.email),
                    const SizedBox(height: 15),

                    TextField(
                      controller: passwordController,
                      obscureText: !showPassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() => showPassword = !showPassword);
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.indigoAccent),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    //RUOLO
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRole,
                        dropdownColor: Colors.black.withOpacity(0.4),
                        iconEnabledColor: Colors.white,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        items: const [
                          DropdownMenuItem(
                            value: "studente",
                            child: Text("Studente",
                                style: TextStyle(color: Colors.white)),
                          ),
                          DropdownMenuItem(
                            value: "docente",
                            child: Text("Docente",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => selectedRole = value!);
                        },
                      ),
                    ),

                    const SizedBox(height: 25),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                        setState(() => isLoading = true);

                        final email = emailController.text.trim();
                        final password = passwordController.text.trim();

                        if (email.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Compila tutti i campi."),
                              backgroundColor: Colors.red,
                            ),
                          );
                          setState(() => isLoading = false);
                          return;
                        }

                        try {
                          final user = await auth.createUserWithEmailAndPassword(
                            email: email,
                            password: password,
                          );

                          if (user == null) {
                            setState(() => isLoading = false);
                            return;
                          }

                          final base64Image = convertImageToBase64();

                          final data = {
                            "email": email,
                            "ruolo": selectedRole == "studente"
                                ? "studente"
                                : "pending_docente",
                            "approved": selectedRole == "studente" ? true : false,
                          };

                          if (base64Image != null) {
                            data["imageBase64"] = base64Image;
                          }

                          await FirebaseFirestore.instance
                              .collection("utenti")
                              .doc(user.uid)
                              .set(data);

                          setState(() => isLoading = false);

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Errore: $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          setState(() => isLoading = false);
                        }
                      },
                      child: isLoading
                          ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                          : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.add, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            "Create Profile",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    )

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.indigoAccent),
        ),
      ),
    );
  }
}
