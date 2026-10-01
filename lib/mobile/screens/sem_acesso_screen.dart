import 'package:flutter/material.dart';
import 'package:task_manager_flutter/constants/custom_colors.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';

class SemAcessoScreen extends StatelessWidget {
  const SemAcessoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nome = AuthUtility.userInfo?.login?.nome ??
        AuthUtility.userInfo?.data?.firstName ??
        'Usuário';

    return Scaffold(
      backgroundColor: GridColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: GridColors.primary),
              const SizedBox(height: 32),
              Text(
                'Olá, $nome',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Você ainda não possui permissão para acessar nenhuma tela do sistema.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              const Text(
                'Entre em contato com o responsável pelo seu cadastro para que ele conceda as permissões necessárias.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.white60),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Sair',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  onPressed: () {
                    AuthUtility.clearUserInfo();
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
