import 'package:flutter/material.dart';
import '../../web/screens/canal_mensagens_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileCanalMensagensScreen extends StatelessWidget {

  const MobileCanalMensagensScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Canal de Mensagens',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.CanalMensagensScreen(),
      ),
    );
  }
}
