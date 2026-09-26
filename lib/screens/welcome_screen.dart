import 'package:flutter/material.dart';
import 'package:uni_check_neww/screens/register_screen.dart';

import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Row(
          children: [
            Icon(Icons.school, color: Colors.white),
            const SizedBox(width: 10),
            const Text(
              'UniCheck',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.login, color: Colors.white),
              label: const Text(
                'Accedi',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
               
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Non hai un account? '),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text(
                    'Registrati',
                    style: TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
