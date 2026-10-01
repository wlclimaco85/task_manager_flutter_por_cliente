import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import '../../web/screens/dre_screen.dart';

/// Tela mobile de DRE Gerencial — envelopa o componente funcional com AppBar e layout mobile nativo.
class MobileDreScreen extends StatelessWidget {
  const MobileDreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DRE Gerencial',
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
        child: const WebDreScreen(),
      ),
    );
  }
}
