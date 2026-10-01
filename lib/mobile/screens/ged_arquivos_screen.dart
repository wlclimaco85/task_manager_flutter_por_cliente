import 'package:flutter/material.dart';
import '../../web/screens/ged_arquivos_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileGedArquivosScreen extends StatelessWidget {

  const MobileGedArquivosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'GED - Arquivos',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.GedArquivosScreen(),
      ),
    );
  }
}
