import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  runApp(const UniCheckApp());
}

class UniCheckApp extends StatelessWidget {
  const UniCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UniCheck',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ).copyWith(
          primary: Colors.blueAccent,
          onPrimary: Colors.black,
          secondary: Colors.blueGrey,
          onSecondary: Colors.black,
          surface: const Color(0xFF1E1E1E),
          background: const Color(0xFF121212),
          onSurface: Colors.white,
        ),

        // ⭐ Pulsante primario (ElevatedButton)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.blueAccent),
            foregroundColor: MaterialStateProperty.all(Colors.black),
            padding: MaterialStateProperty.all(
              const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            ),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),

            // ⭐ FONT PRIMARIO
            textStyle: MaterialStateProperty.all(
              const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,   // molto bold
                fontFamily: 'Roboto',          // puoi cambiarlo
              ),
            ),
          ),
        ),

        // ⭐ Pulsante secondario (FilledButton)
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.blueGrey),
            foregroundColor: MaterialStateProperty.all(Colors.black),
            iconColor: MaterialStateProperty.all(Colors.black),
            padding: MaterialStateProperty.all(
              const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            ),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),

            // ⭐ FONT SECONDARIO
            textStyle: MaterialStateProperty.all(
              const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,   // corsivo
                fontFamily: 'Montserrat',      // font diverso
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),




      home: const SplashScreen(),
    );
  }
}
