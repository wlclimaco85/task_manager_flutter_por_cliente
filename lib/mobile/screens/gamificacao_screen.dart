import 'package:flutter/material.dart';
import '../../web/screens/gamificacao_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileGamificacaoScreen extends StatelessWidget {
  final int? alunoId;

  const MobileGamificacaoScreen({super.key, this.alunoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Gamificação',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.GamificacaoScreen(alunoId: alunoId ?? 0),
      ),
    );
  }
}
