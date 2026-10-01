import 'package:flutter/material.dart';
import '../../web/screens/dashboard_mensalidade_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileWebDashboardMensalidadeScreen extends StatelessWidget {

  const MobileWebDashboardMensalidadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Dashboard de Mensalidades',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.WebDashboardMensalidadeScreen(),
      ),
    );
  }
}
