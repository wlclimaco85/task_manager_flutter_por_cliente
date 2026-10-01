// lib/widgets/gated_button.dart
//
// Widget condicional que mostra ou oculta seu child baseado no flag 'enabled'.
// Usado para esconder ações que não se aplicam ao estado atual sem criar
// gaps no layout — oculta substituindo por SizedBox.shrink().
//
// Exemplo:
//   GatedButton(
//     enabled: status == 'RASCUNHO',
//     child: IconButton(icon: Icon(Icons.edit), onPressed: onEdit),
//   )

import 'package:flutter/material.dart';

class GatedButton extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const GatedButton({
    required this.enabled,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return enabled ? child : SizedBox.shrink();
  }
}
