import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import '../../web/screens/aprovacao_pagamentos_screen.dart';

/// Tela mobile de Aprovação de Pagamentos — envelopa o componente funcional com AppBar e layout mobile nativo.
class MobileAprovacaoPagamentosScreen extends StatelessWidget {
  const MobileAprovacaoPagamentosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Aprovação de Pagamentos',
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
        child: const WebAprovacaoPagamentosScreen(),
      ),
    );
  }
}
