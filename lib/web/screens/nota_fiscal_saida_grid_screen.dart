import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/nota_fiscal_saida_model.dart';

class WebNotaFiscalSaidaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebNotaFiscalSaidaGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<NotaFiscalSaida>(
      telaNome: 'nota_fiscal_saida',
      hasPermission: hasPermission,
      fromJson: (json) => NotaFiscalSaida.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}


