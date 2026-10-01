import 'package:flutter/material.dart';
import '../../../models/forma_pagamento_model.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';

class WindowsFormaPagamentoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsFormaPagamentoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<FormaPagamento>(
      telaNome: 'Formas de Pagamento', // o nome que está no banco
      hasPermission: hasPermission,
      fromJson: (json) => FormaPagamento.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}
