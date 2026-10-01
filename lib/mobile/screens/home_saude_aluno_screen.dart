import 'package:flutter/material.dart';
import '../../web/screens/home_saude_aluno_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileWebHomeSaudeAlunoScreen extends StatelessWidget {

  const MobileWebHomeSaudeAlunoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Saúde do Aluno',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.WebHomeSaudeAlunoScreen(),
      ),
    );
  }
}
