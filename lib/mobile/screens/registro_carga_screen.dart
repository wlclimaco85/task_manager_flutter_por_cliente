import 'package:flutter/material.dart';
import '../../web/screens/registro_carga_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileRegistroCargaScreen extends StatelessWidget {
  final int? sessionId;

  const MobileRegistroCargaScreen({super.key, this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Registro de Carga',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.RegistroCargaScreen(sessionId: sessionId ?? 0),
      ),
    );
  }
}
