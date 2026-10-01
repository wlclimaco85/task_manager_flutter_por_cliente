import 'package:flutter/material.dart';
import '../../web/screens/frequencia_aluno_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileFrequenciaAlunoScreen extends StatelessWidget {
  final int? alunoId;

  const MobileFrequenciaAlunoScreen({super.key, this.alunoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Frequência do Aluno',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.FrequenciaAlunoScreen(alunoId: alunoId ?? 0),
      ),
    );
  }
}
