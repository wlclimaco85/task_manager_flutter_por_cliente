import 'package:flutter/material.dart';
import '../../web/screens/contingencia_rejeicao_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileContingenciaRejeicaoScreen extends StatelessWidget {

  const MobileContingenciaRejeicaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Contingência e Rejeição',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.ContingenciaRejeicaoScreen(),
      ),
    );
  }
}
