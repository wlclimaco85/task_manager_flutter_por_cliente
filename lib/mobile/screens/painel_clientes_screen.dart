import 'package:flutter/material.dart';
import '../../web/screens/painel_clientes_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobilePainelClientesScreen extends StatelessWidget {

  const MobilePainelClientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Painel de Clientes',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.PainelClientesScreen(),
      ),
    );
  }
}
