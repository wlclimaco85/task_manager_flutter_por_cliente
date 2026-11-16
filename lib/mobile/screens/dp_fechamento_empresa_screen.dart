import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import '../../web/screens/dp_fechamento_empresa_screen.dart';

/// Mobile: envelopa a tela de fechamento da empresa (layout vertical em cartoes) com AppBar.
class MobileDpFechamentoEmpresaScreen extends StatelessWidget {
  const MobileDpFechamentoEmpresaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fechamento do Ponto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: GridColors.textPrimary)),
        backgroundColor: Colors.white,
        foregroundColor: GridColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GridColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: const SafeArea(child: DpFechamentoEmpresaScreen()),
    );
  }
}
