import 'package:flutter/material.dart';
import '../../../models/diretorio_model.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';

class WindowsDiretorioGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsDiretorioGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Diretorio>(
      telaNome: 'Diretórios', // nome da tela no banco
      hasPermission: hasPermission,
      fromJson: (json) => Diretorio.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}
