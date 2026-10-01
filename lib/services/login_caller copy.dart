import 'package:flutter/material.dart';
import '../utils/grid_texts.dart';

// Certifique-se de que esta classe inclui o parâmetro `onLoginSuccess`.
class LoginPopup extends StatelessWidget {
  final VoidCallback? onLoginSuccess;

  const LoginPopup({super.key, this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Login'),
      content: const Text('Por favor, faça login para continuar.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(GridTexts.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            // Simulação de login bem-sucedido
            if (onLoginSuccess != null) {
              onLoginSuccess!();
            }
            Navigator.of(context).pop();
          },
          child: const Text('Login'),
        ),
      ],
    );
  }
}
