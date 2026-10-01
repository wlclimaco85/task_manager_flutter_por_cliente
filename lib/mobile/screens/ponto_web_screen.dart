import 'package:flutter/material.dart';
import '../../web/screens/ponto_web_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileWebPontoScreen extends StatelessWidget {

  const MobileWebPontoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Controle de Ponto',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.WebPontoScreen(),
      ),
    );
  }
}
