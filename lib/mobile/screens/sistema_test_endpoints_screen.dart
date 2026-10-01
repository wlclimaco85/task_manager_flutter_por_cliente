import 'package:flutter/material.dart';
import '../../web/screens/sistema_test_endpoints_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileWebSistemaTestEndpointsScreen extends StatelessWidget {

  const MobileWebSistemaTestEndpointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Teste de Endpoints',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.WebSistemaTestEndpointsScreen(),
      ),
    );
  }
}
