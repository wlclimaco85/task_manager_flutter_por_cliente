import 'package:flutter/material.dart';
import '../../web/screens/comunicado_componente_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileWebComunicadoGridComponentesScreen extends StatelessWidget {
  final bool Function(String)? hasPermission;

  const MobileWebComunicadoGridComponentesScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Comunicados',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.WebComunicadoGridComponentesScreen(hasPermission: hasPermission ?? ((_) => true)),
      ),
    );
  }
}
