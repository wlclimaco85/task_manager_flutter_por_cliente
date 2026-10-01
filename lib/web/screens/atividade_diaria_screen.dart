import 'package:flutter/material.dart';

import '../../models/auth_utility.dart';
import '../../widgets/atividade_diaria_card.dart';
import '../../utils/grid_colors.dart';

/// Tela de atividade diária — passos, distância e calorias.
/// Exibe o card de hoje e placeholder para histórico futuro.
class WebAtividadeDiariaScreen extends StatelessWidget {
  const WebAtividadeDiariaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alunoId = _resolverAlunoId();

    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      appBar: AppBar(
        backgroundColor: GridColors.secondary,
        title: const Text(
          'Atividade Diária',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card principal de atividade hoje
            AtividadeDiariaCard(alunoId: alunoId),
            const SizedBox(height: 16),

            // Placeholder para histórico (Fase 2)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bar_chart,
                            color: GridColors.secondary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Histórico dos últimos 7 dias',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: GridColors.secondary),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Gráfico de evolução disponível em breve.',
                      style: TextStyle(color: GridColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _resolverAlunoId() {
    // Tenta obter o ID de aluno do usuário logado.
    // Se o login for de aluno, o campo data.id representa o aluno.
    final id = AuthUtility.userInfo?.data?.id;
    if (id != null) return id;
    return 0;
  }
}
