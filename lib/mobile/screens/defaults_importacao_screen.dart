import 'package:flutter/material.dart';
import '../../web/screens/defaults_importacao_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileDefaultsImportacaoScreen extends StatelessWidget {

  const MobileDefaultsImportacaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Padrões de Importação',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.DefaultsImportacaoScreen(),
      ),
    );
  }
}
