import 'package:flutter/material.dart';
import '../../web/screens/frequencia_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileFrequenciaScreen extends StatelessWidget {
  const MobileFrequenciaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: UserBannerAppBar(
        screenTitle: 'Frequência Semanal',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.FrequenciaScreen(),
      ),
    );
  }
}
