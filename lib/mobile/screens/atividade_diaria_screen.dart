import 'package:flutter/material.dart';
import '../../web/screens/atividade_diaria_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileWebAtividadeDiariaScreen extends StatelessWidget {
  const MobileWebAtividadeDiariaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: UserBannerAppBar(
        screenTitle: 'Atividade Diária',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.WebAtividadeDiariaScreen(),
      ),
    );
  }
}
