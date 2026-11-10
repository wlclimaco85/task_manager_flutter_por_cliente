import 'package:flutter/material.dart';

import '../../widgets/mdfe_emissao_view.dart';

/// MDF-e no Mobile: mesma tela de Web/Windows, em coluna vertical com AppBar.
class MobileMdfeEmissaoScreen extends StatelessWidget {
  final bool Function(String acao)? hasPermission;

  const MobileMdfeEmissaoScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MDF-e')),
      body: SafeArea(child: MdfeEmissaoView(hasPermission: hasPermission)),
    );
  }
}
