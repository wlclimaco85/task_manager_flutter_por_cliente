import 'package:flutter/material.dart';

import '../../widgets/cte_emissao_view.dart';

/// CT-e no Mobile: mesma tela de Web/Windows, em coluna vertical com AppBar.
class MobileCteEmissaoScreen extends StatelessWidget {
  const MobileCteEmissaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CT-e')),
      body: const SafeArea(child: CteEmissaoView()),
    );
  }
}
