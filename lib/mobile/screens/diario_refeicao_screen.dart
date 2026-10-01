import 'package:flutter/material.dart';
import '../../web/screens/diario_refeicao_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileWebDiarioRefeicaoScreen extends StatelessWidget {
  const MobileWebDiarioRefeicaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: UserBannerAppBar(
        screenTitle: 'Diário Nutricional',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.WebDiarioRefeicaoScreen(),
      ),
    );
  }
}
