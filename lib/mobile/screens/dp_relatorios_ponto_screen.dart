import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import '../../web/screens/dp_relatorios_ponto_screen.dart';

/// Mobile: envelopa a suite de relatorios de ponto (linhas em cartoes) com AppBar.
class MobileDpRelatoriosPontoScreen extends StatelessWidget {
  const MobileDpRelatoriosPontoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios de Ponto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: GridColors.textPrimary)),
        backgroundColor: Colors.white,
        foregroundColor: GridColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GridColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: const SafeArea(child: DpRelatoriosPontoScreen()),
    );
  }
}
