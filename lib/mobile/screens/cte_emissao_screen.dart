import 'package:flutter/material.dart';

import '../../widgets/cte_emissao_view.dart';

/// CT-e no Mobile: mesma tela de Web/Windows, em coluna vertical com AppBar.
class MobileCteEmissaoScreen extends StatelessWidget {
  final bool Function(String acao)? hasPermission;

  const MobileCteEmissaoScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CT-e')),
      body: SafeArea(child: CteEmissaoView(hasPermission: hasPermission)),
    );
  }
}
