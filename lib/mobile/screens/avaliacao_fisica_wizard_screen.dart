import 'package:flutter/material.dart';
import '../../web/screens/avaliacao_fisica_wizard_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileAvaliacaoFisicaWizardScreen extends StatelessWidget {

  const MobileAvaliacaoFisicaWizardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Avaliação Física',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.AvaliacaoFisicaWizardScreen(),
      ),
    );
  }
}
