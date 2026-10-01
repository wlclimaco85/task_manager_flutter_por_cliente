import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import '../../windows/screens/renegociacao_screen.dart';

/// Tela mobile de Renegociação — envelopa o componente funcional com AppBar e layout mobile nativo.
class MobileRenegociacaoScreen extends StatelessWidget {
  const MobileRenegociacaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Renegociação',
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
        child: const RenegociacaoScreen(),
      ),
    );
  }
}
