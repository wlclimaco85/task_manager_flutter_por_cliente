import 'package:flutter/material.dart';
import '../../web/screens/dashboard_obrigacoes_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileDashboardObrigacoesScreen extends StatelessWidget {

  const MobileDashboardObrigacoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Dashboard de Obrigações',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.DashboardObrigacoesScreen(),
      ),
    );
  }
}
