import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/nota_fiscal_entrada_model.dart';

class WebNotaFiscalEntradaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebNotaFiscalEntradaGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<NotaFiscalEntrada>(
      telaNome: 'nota_fiscal_entrada',
      hasPermission: hasPermission,
      fromJson: (json) => NotaFiscalEntrada.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}


