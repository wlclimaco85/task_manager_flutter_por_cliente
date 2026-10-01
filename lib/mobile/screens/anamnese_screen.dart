import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import '../../web/screens/anamnese_screen.dart';
import '../../models/auth_utility.dart';

/// Tela mobile de Anamnese Digital — envelopa o componente funcional com AppBar e layout mobile nativo.
class MobileAnamneseScreen extends StatelessWidget {
  const MobileAnamneseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Anamnese Digital',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: GridColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: GridColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GridColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: AnamneseScreen(alunoId: AuthUtility.userInfo?.data?.id ?? 0, nomeAluno: AuthUtility.userInfo?.login?.nome ?? 'Aluno'),
      ),
    );
  }
}
