import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 231, 247, 233),
      appBar: AppBar(
        title: const Text('Recuperar Senha'),
        backgroundColor: const Color.fromARGB(255, 128, 202, 132),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'E-mail',
                labelStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: const Color.fromARGB(255, 128, 202, 132),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Lógica de recuperação de senha
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 128, 202, 132),
              ),
              child: const Text('Recuperar'),
            ),
          ],
        ),
      ),
    );
  }
}
