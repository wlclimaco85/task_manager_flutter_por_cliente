import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/venda_model.dart';

class WindowsClassificacaoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsClassificacaoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Classificacao>(
      telaNome: 'Classificacao',
      hasPermission: hasPermission,
      fromJson: (json) => Classificacao.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}
