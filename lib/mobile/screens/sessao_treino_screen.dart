import 'package:flutter/material.dart';
import '../../web/screens/sessao_treino_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileSessaoTreinoScreen extends StatelessWidget {
  final int? treinoId;
  final int? alunoId;

  const MobileSessaoTreinoScreen({super.key, this.treinoId, this.alunoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Sessão de Treino',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.SessaoTreinoScreen(
          treinoId: treinoId ?? 0,
          alunoId: alunoId ?? 0,
        ),
      ),
    );
  }
}
