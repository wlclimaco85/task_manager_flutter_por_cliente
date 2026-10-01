import 'package:flutter/material.dart';
import '../../web/screens/nfe_saida_create_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileNfeSaidaCreateScreen extends StatelessWidget {

  const MobileNfeSaidaCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Nova NF-e de Saída',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.NfeSaidaCreateScreen(),
      ),
    );
  }
}
