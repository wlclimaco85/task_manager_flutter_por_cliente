import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import '../../web/screens/conciliacao_screen.dart';

/// Tela mobile de Conciliação Bancária — envelopa o componente funcional com AppBar e layout mobile nativo.
class MobileConciliacaoScreen extends StatelessWidget {
  const MobileConciliacaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Conciliação Bancária',
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
        child: const WebConciliacaoScreen(),
      ),
    );
  }
}
