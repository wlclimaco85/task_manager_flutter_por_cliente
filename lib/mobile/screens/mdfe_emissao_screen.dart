import 'package:flutter/material.dart';

import '../../widgets/mdfe_emissao_view.dart';

/// MDF-e no Mobile: mesma tela de Web/Windows, em coluna vertical com AppBar.
class MobileMdfeEmissaoScreen extends StatelessWidget {
  const MobileMdfeEmissaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MDF-e')),
      body: const SafeArea(child: MdfeEmissaoView()),
    );
  }
}
