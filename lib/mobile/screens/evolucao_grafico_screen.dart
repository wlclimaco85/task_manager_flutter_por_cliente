import 'package:flutter/material.dart';
import '../../web/screens/evolucao_grafico_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileEvolucaoGraficoScreen extends StatelessWidget {
  final int? alunoId;

  const MobileEvolucaoGraficoScreen({super.key, this.alunoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Evolução do Aluno',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.EvolucaoGraficoScreen(alunoId: alunoId ?? 0),
      ),
    );
  }
}
