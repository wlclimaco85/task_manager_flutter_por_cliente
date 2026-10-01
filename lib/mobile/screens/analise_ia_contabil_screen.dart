import 'package:flutter/material.dart';
import '../../web/screens/analise_ia_contabil_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileAnaliseIaContabilScreen extends StatelessWidget {

  const MobileAnaliseIaContabilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Análise IA Contábil',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.AnaliseIaContabilScreen(),
      ),
    );
  }
}
