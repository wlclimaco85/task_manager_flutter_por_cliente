import 'package:flutter/material.dart';
import '../../web/screens/tela_editor_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileTelaEditorScreen extends StatelessWidget {

  const MobileTelaEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Editor de Telas',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.TelaEditorScreen(),
      ),
    );
  }
}
