import 'package:flutter/material.dart';
import '../../web/screens/mensalidade_dashboard_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileWebMensalidadeDashboardScreen extends StatelessWidget {

  const MobileWebMensalidadeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Mensalidades',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.WebMensalidadeDashboardScreen(),
      ),
    );
  }
}
