import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import '../../web/screens/nfe_import_screen.dart';

/// Tela mobile de Importar NF-e CSV — envelopa o componente funcional com AppBar e layout mobile nativo.
class MobileNfeImportScreen extends StatelessWidget {
  const MobileNfeImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Importar NF-e CSV',
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
        child: const NfeImportScreen(),
      ),
    );
  }
}
