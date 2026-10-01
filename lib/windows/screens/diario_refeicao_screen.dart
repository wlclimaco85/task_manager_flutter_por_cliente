import 'package:flutter/material.dart';

import '../../models/auth_utility.dart';
import '../../widgets/diario_refeicao_card.dart';
import '../../utils/grid_colors.dart';

/// Tela de diário nutricional (versão Windows)
class WindowsDiarioRefeicaoScreen extends StatelessWidget {
  const WindowsDiarioRefeicaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alunoId = AuthUtility.userInfo?.data?.id ?? 0;
    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      appBar: AppBar(
        backgroundColor: GridColors.secondary,
        title: const Text('Diário Nutricional',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: DiarioRefeicaoCard(alunoId: alunoId),
      ),
    );
  }
}
