import 'package:flutter/material.dart';
import '../../../models/forma_pagamento_model.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../services/formaPagamento_caller.dart';

class WebFormaPagamentoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WebFormaPagamentoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<FormaPagamento>(
      telaNome: 'forma_pagamento',
      hasPermission: hasPermission,
      fromJson: (json) => FormaPagamento.fromJson(json),
      toJson: (a) => a.toJson(),
      onAfterCreate: () => FormaPagamentoCaller.clearCache(),
    );
  }
}


