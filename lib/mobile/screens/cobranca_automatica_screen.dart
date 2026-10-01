import 'package:flutter/material.dart';
import '../../web/screens/cobranca_automatica_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileCobrancaAutomaticaScreen extends StatelessWidget {

  const MobileCobrancaAutomaticaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Cobrança Automática',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.CobrancaAutomaticaScreen(),
      ),
    );
  }
}
