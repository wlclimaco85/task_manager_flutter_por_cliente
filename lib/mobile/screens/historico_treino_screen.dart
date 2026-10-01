import 'package:flutter/material.dart';
import '../../web/screens/historico_treino_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileHistoricoTreinoScreen extends StatelessWidget {
  final int? alunoId;

  const MobileHistoricoTreinoScreen({super.key, this.alunoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Histórico de Treinos',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.HistoricoTreinoScreen(alunoId: alunoId ?? 0),
      ),
    );
  }
}
