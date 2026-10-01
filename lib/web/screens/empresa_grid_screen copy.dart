import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/empresa_model.dart';

class WebEmpresaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WebEmpresaGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Empresa>(
      telaNome: 'Empresas', // nome da tela no banco
      hasPermission: hasPermission,
      fromJson: (json) => Empresa.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}
