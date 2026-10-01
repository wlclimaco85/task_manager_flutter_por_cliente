import 'package:flutter/material.dart';
import '../../web/screens/diario_nutricional_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileDiarioNutricionalScreen extends StatelessWidget {
  final int? alunoId;

  const MobileDiarioNutricionalScreen({super.key, this.alunoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Diário Nutricional',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.DiarioNutricionalScreen(alunoId: alunoId ?? 0),
      ),
    );
  }
}
