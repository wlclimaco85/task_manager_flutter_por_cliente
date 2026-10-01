import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import '../../windows/screens/deposito_screen.dart';

/// Tela mobile de Multi-depósito — envelopa o componente funcional com AppBar e layout mobile nativo.
class MobileDepositoScreen extends StatelessWidget {
  const MobileDepositoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Multi-depósito',
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
        child: const DepositoScreen(),
      ),
    );
  }
}
