import 'package:flutter/material.dart';

import '../../widgets/relatorios_personalizados_view.dart';

/// Relatórios no Mobile: a mesma tela de Web/Windows, em coluna vertical.
class MobileRelatoriosPersonalizadosScreen extends StatelessWidget {
  const MobileRelatoriosPersonalizadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: const SafeArea(child: RelatoriosPersonalizadosView()),
    );
  }
}
