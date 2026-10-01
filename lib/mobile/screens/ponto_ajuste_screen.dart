import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import '../../web/screens/ponto_ajuste_screen.dart';

/// Tela mobile de Ajuste de Ponto — envelopa o componente funcional com AppBar e layout mobile nativo.
class MobilePontoAjusteScreen extends StatelessWidget {
  const MobilePontoAjusteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajuste de Ponto',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: GridColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: GridColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GridColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: const SafeArea(
        child: const WebPontoAjusteScreen(),
      ),
    );
  }
}
